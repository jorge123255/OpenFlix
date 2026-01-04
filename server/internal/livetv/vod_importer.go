package livetv

import (
	"fmt"
	"log"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// VODImporter handles importing VOD content from Xtream sources
type VODImporter struct {
	db            *gorm.DB
	xtreamClient  *XtreamClient
}

// NewVODImporter creates a new VOD importer
func NewVODImporter(db *gorm.DB) *VODImporter {
	return &VODImporter{
		db:           db,
		xtreamClient: NewXtreamClient(db),
	}
}

// ImportResult contains statistics about an import operation
type ImportResult struct {
	Added    int    `json:"added"`
	Updated  int    `json:"updated"`
	Skipped  int    `json:"skipped"`
	Errors   int    `json:"errors"`
	Total    int    `json:"total"`
	Duration string `json:"duration"`
}

// ImportXtreamVOD imports VOD movies from an Xtream source into the specified library
func (v *VODImporter) ImportXtreamVOD(sourceID uint) (*ImportResult, error) {
	start := time.Now()
	result := &ImportResult{}

	// Get the source
	var source models.XtreamSource
	if err := v.db.First(&source, sourceID).Error; err != nil {
		return nil, fmt.Errorf("source not found: %w", err)
	}

	if !source.ImportVOD {
		return nil, fmt.Errorf("VOD import not enabled for this source")
	}

	if source.VODLibraryID == nil {
		return nil, fmt.Errorf("no target library configured for VOD import")
	}

	// Verify target library exists and is a movie library
	var library models.Library
	if err := v.db.First(&library, *source.VODLibraryID).Error; err != nil {
		return nil, fmt.Errorf("target library not found: %w", err)
	}
	if library.Type != "movie" {
		return nil, fmt.Errorf("target library must be a movie library")
	}

	// Get all VOD streams
	streams, err := v.xtreamClient.GetVODStreams(&source, "")
	if err != nil {
		return nil, fmt.Errorf("failed to get VOD streams: %w", err)
	}

	result.Total = len(streams)
	log.Printf("Importing %d VOD items from source %s", result.Total, source.Name)

	for _, stream := range streams {
		// Check if already exists
		var existing models.MediaItem
		err := v.db.Where("xtream_vod_id = ? AND provider_source_id = ?", stream.StreamID, source.ID).
			First(&existing).Error

		// Build stream URL
		streamURL := v.xtreamClient.BuildVODStreamURL(&source, stream.StreamID, stream.ContainerExtension)

		// Parse year from name if present (e.g., "Movie Name (2023)")
		title, year := parseYearFromTitle(stream.Name)

		mediaItem := models.MediaItem{
			UUID:             uuid.New().String(),
			LibraryID:        *source.VODLibraryID,
			Type:             "movie",
			Title:            title,
			Year:             year,
			Thumb:            stream.StreamIcon,
			Rating:           stream.Rating,
			ProviderType:     "xtream",
			ProviderSourceID: &source.ID,
			ProviderName:     source.Name,
			StreamURL:        streamURL,
			XtreamVODID:      &stream.StreamID,
			AddedAt:          time.Now(),
			UpdatedAt:        time.Now(),
		}

		if err == gorm.ErrRecordNotFound {
			// Create new item
			if err := v.db.Create(&mediaItem).Error; err != nil {
				log.Printf("Failed to create VOD item %s: %v", stream.Name, err)
				result.Errors++
				continue
			}

			// Create a remote media file entry
			mediaFile := models.MediaFile{
				MediaItemID:     mediaItem.ID,
				FilePath:        fmt.Sprintf("xtream://vod/%d/%d.%s", source.ID, stream.StreamID, stream.ContainerExtension),
				Container:       stream.ContainerExtension,
				IsRemote:        true,
				RemoteURL:       streamURL,
				RemoteExtension: stream.ContainerExtension,
			}
			v.db.Create(&mediaFile)

			result.Added++
		} else if err == nil {
			// Update existing
			mediaItem.ID = existing.ID
			mediaItem.UUID = existing.UUID
			mediaItem.AddedAt = existing.AddedAt

			if err := v.db.Save(&mediaItem).Error; err != nil {
				log.Printf("Failed to update VOD item %s: %v", stream.Name, err)
				result.Errors++
				continue
			}
			result.Updated++
		} else {
			result.Errors++
		}
	}

	// Update source stats
	source.VODCount = result.Added + result.Updated
	source.LastFetched = timePtr(time.Now())
	v.db.Save(&source)

	result.Duration = time.Since(start).String()
	log.Printf("VOD import complete: %d added, %d updated, %d errors in %s",
		result.Added, result.Updated, result.Errors, result.Duration)

	return result, nil
}

// ImportXtreamSeries imports TV series from an Xtream source into the specified library
func (v *VODImporter) ImportXtreamSeries(sourceID uint) (*ImportResult, error) {
	start := time.Now()
	result := &ImportResult{}

	// Get the source
	var source models.XtreamSource
	if err := v.db.First(&source, sourceID).Error; err != nil {
		return nil, fmt.Errorf("source not found: %w", err)
	}

	if !source.ImportSeries {
		return nil, fmt.Errorf("series import not enabled for this source")
	}

	if source.SeriesLibraryID == nil {
		return nil, fmt.Errorf("no target library configured for series import")
	}

	// Verify target library exists and is a show library
	var library models.Library
	if err := v.db.First(&library, *source.SeriesLibraryID).Error; err != nil {
		return nil, fmt.Errorf("target library not found: %w", err)
	}
	if library.Type != "show" {
		return nil, fmt.Errorf("target library must be a TV show library")
	}

	// Get all series
	seriesList, err := v.xtreamClient.GetSeries(&source, "")
	if err != nil {
		return nil, fmt.Errorf("failed to get series: %w", err)
	}

	result.Total = len(seriesList)
	log.Printf("Importing %d series from source %s", result.Total, source.Name)

	for _, series := range seriesList {
		// Check if show already exists
		var existingShow models.MediaItem
		err := v.db.Where("xtream_series_id = ? AND provider_source_id = ? AND type = ?",
			series.SeriesID, source.ID, "show").First(&existingShow).Error

		// Parse year
		_, year := parseYearFromTitle(series.ReleaseDate)

		// Parse rating
		rating, _ := strconv.ParseFloat(series.Rating, 64)

		showItem := models.MediaItem{
			UUID:             uuid.New().String(),
			LibraryID:        *source.SeriesLibraryID,
			Type:             "show",
			Title:            series.Name,
			Summary:          series.Plot,
			Year:             year,
			Thumb:            series.Cover,
			Rating:           rating,
			ProviderType:     "xtream",
			ProviderSourceID: &source.ID,
			ProviderName:     source.Name,
			XtreamSeriesID:   &series.SeriesID,
			AddedAt:          time.Now(),
			UpdatedAt:        time.Now(),
		}

		var showID uint
		if err == gorm.ErrRecordNotFound {
			// Create new show
			if err := v.db.Create(&showItem).Error; err != nil {
				log.Printf("Failed to create series %s: %v", series.Name, err)
				result.Errors++
				continue
			}
			showID = showItem.ID
			result.Added++
		} else if err == nil {
			showItem.ID = existingShow.ID
			showItem.UUID = existingShow.UUID
			showItem.AddedAt = existingShow.AddedAt
			if err := v.db.Save(&showItem).Error; err != nil {
				log.Printf("Failed to update series %s: %v", series.Name, err)
				result.Errors++
				continue
			}
			showID = existingShow.ID
			result.Updated++
		} else {
			result.Errors++
			continue
		}

		// Get series details (seasons and episodes)
		seriesInfo, err := v.xtreamClient.GetSeriesInfo(&source, series.SeriesID)
		if err != nil {
			log.Printf("Failed to get series info for %s: %v", series.Name, err)
			continue
		}

		// Import seasons and episodes
		v.importSeasonsAndEpisodes(&source, showID, series.Name, seriesInfo)
	}

	// Update source stats
	source.SeriesCount = result.Added + result.Updated
	source.LastFetched = timePtr(time.Now())
	v.db.Save(&source)

	result.Duration = time.Since(start).String()
	log.Printf("Series import complete: %d added, %d updated, %d errors in %s",
		result.Added, result.Updated, result.Errors, result.Duration)

	return result, nil
}

func (v *VODImporter) importSeasonsAndEpisodes(source *models.XtreamSource, showID uint, showTitle string, info *XtreamSeriesInfo) {
	// Get the show to access library ID
	var show models.MediaItem
	if err := v.db.First(&show, showID).Error; err != nil {
		return
	}

	// Process each season
	for _, season := range info.Seasons {
		// Check if season exists
		var existingSeason models.MediaItem
		seasonNum := season.SeasonNumber
		err := v.db.Where("parent_id = ? AND type = ? AND index = ?",
			showID, "season", seasonNum).First(&existingSeason).Error

		seasonItem := models.MediaItem{
			UUID:             uuid.New().String(),
			LibraryID:        show.LibraryID,
			Type:             "season",
			Title:            season.Name,
			Summary:          season.Overview,
			Index:            seasonNum,
			ParentID:         &showID,
			ParentTitle:      showTitle,
			Thumb:            season.Cover,
			ProviderType:     "xtream",
			ProviderSourceID: &source.ID,
			ProviderName:     source.Name,
			AddedAt:          time.Now(),
			UpdatedAt:        time.Now(),
		}

		var seasonID uint
		if err == gorm.ErrRecordNotFound {
			if err := v.db.Create(&seasonItem).Error; err != nil {
				log.Printf("Failed to create season %d for %s: %v", seasonNum, showTitle, err)
				continue
			}
			seasonID = seasonItem.ID
		} else if err == nil {
			seasonItem.ID = existingSeason.ID
			seasonItem.UUID = existingSeason.UUID
			seasonItem.AddedAt = existingSeason.AddedAt
			v.db.Save(&seasonItem)
			seasonID = existingSeason.ID
		} else {
			continue
		}

		// Import episodes for this season
		seasonKey := strconv.Itoa(seasonNum)
		episodes, ok := info.Episodes[seasonKey]
		if !ok {
			continue
		}

		for _, ep := range episodes {
			v.importEpisode(source, showID, seasonID, showTitle, seasonNum, ep)
		}

		// Update season leaf count
		var epCount int64
		v.db.Model(&models.MediaItem{}).Where("parent_id = ?", seasonID).Count(&epCount)
		v.db.Model(&models.MediaItem{}).Where("id = ?", seasonID).Update("leaf_count", epCount)
	}

	// Update show child count and leaf count
	var seasonCount int64
	var episodeCount int64
	v.db.Model(&models.MediaItem{}).Where("parent_id = ? AND type = ?", showID, "season").Count(&seasonCount)
	v.db.Model(&models.MediaItem{}).Where("grandparent_id = ? AND type = ?", showID, "episode").Count(&episodeCount)
	v.db.Model(&models.MediaItem{}).Where("id = ?", showID).Updates(map[string]interface{}{
		"child_count": seasonCount,
		"leaf_count":  episodeCount,
	})
}

func (v *VODImporter) importEpisode(source *models.XtreamSource, showID, seasonID uint, showTitle string, seasonNum int, ep XtreamEpisode) {
	// Get season info
	var season models.MediaItem
	if err := v.db.First(&season, seasonID).Error; err != nil {
		return
	}

	// Parse episode ID
	epStreamID, _ := strconv.Atoi(ep.ID)

	// Check if episode exists
	var existing models.MediaItem
	err := v.db.Where("parent_id = ? AND type = ? AND index = ?",
		seasonID, "episode", ep.EpisodeNum).First(&existing).Error

	// Build stream URL
	streamURL := v.xtreamClient.BuildSeriesStreamURL(source, epStreamID, ep.ContainerExtension)

	episodeItem := models.MediaItem{
		UUID:             uuid.New().String(),
		LibraryID:        season.LibraryID,
		Type:             "episode",
		Title:            ep.Title,
		Summary:          ep.Info.Plot,
		Index:            ep.EpisodeNum,
		ParentIndex:      seasonNum,
		ParentID:         &seasonID,
		GrandparentID:    &showID,
		ParentTitle:      season.Title,
		GrandparentTitle: showTitle,
		Thumb:            ep.Info.MovieImage,
		Duration:         int64(ep.Info.DurationSecs * 1000), // Convert to ms
		StreamURL:        streamURL,
		ProviderType:     "xtream",
		ProviderSourceID: &source.ID,
		ProviderName:     source.Name,
		AddedAt:          time.Now(),
		UpdatedAt:        time.Now(),
	}

	if err == gorm.ErrRecordNotFound {
		if err := v.db.Create(&episodeItem).Error; err != nil {
			log.Printf("Failed to create episode S%02dE%02d for %s: %v", seasonNum, ep.EpisodeNum, showTitle, err)
			return
		}

		// Create media file
		mediaFile := models.MediaFile{
			MediaItemID:     episodeItem.ID,
			FilePath:        fmt.Sprintf("xtream://series/%d/%s.%s", source.ID, ep.ID, ep.ContainerExtension),
			Container:       ep.ContainerExtension,
			Duration:        int64(ep.Info.DurationSecs * 1000),
			Bitrate:         ep.Info.Bitrate,
			Width:           ep.Info.Video.Width,
			Height:          ep.Info.Video.Height,
			VideoCodec:      ep.Info.Video.Codec,
			AudioCodec:      ep.Info.Audio.Codec,
			AudioChannels:   ep.Info.Audio.Channels,
			IsRemote:        true,
			RemoteURL:       streamURL,
			RemoteExtension: ep.ContainerExtension,
		}
		v.db.Create(&mediaFile)
	} else if err == nil {
		episodeItem.ID = existing.ID
		episodeItem.UUID = existing.UUID
		episodeItem.AddedAt = existing.AddedAt
		v.db.Save(&episodeItem)
	}
}

// CleanupOrphaned removes media items that no longer exist in the source
func (v *VODImporter) CleanupOrphaned(sourceID uint, providerType string) (int, error) {
	// This would compare current items with what's in the source
	// and remove items that no longer exist
	// For now, just return 0
	return 0, nil
}

// Helper to parse year from title like "Movie Name (2023)"
func parseYearFromTitle(title string) (string, int) {
	// Try to extract year from parentheses at end
	if len(title) > 6 && title[len(title)-1] == ')' {
		for i := len(title) - 2; i >= 0; i-- {
			if title[i] == '(' {
				yearStr := title[i+1 : len(title)-1]
				if year, err := strconv.Atoi(yearStr); err == nil && year >= 1900 && year <= 2100 {
					return strings.TrimSpace(title[:i]), year
				}
				break
			}
		}
	}

	// Try to parse as date (for release dates)
	if len(title) >= 4 {
		// Try YYYY-MM-DD format
		if year, err := strconv.Atoi(title[:4]); err == nil && year >= 1900 && year <= 2100 {
			return title, year
		}
	}

	return title, 0
}
