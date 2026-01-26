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

	// Fetch VOD categories first to build maps
	categories, err := v.xtreamClient.GetVODCategories(&source)
	if err != nil {
		log.Printf("Warning: could not fetch VOD categories: %v", err)
	}

	// Build category maps: id -> name, id -> parent_id
	categoryNameMap := make(map[string]string)  // category_id -> category_name
	categoryParentMap := make(map[string]string) // category_id -> parent_id
	for _, cat := range categories {
		categoryNameMap[cat.CategoryID] = cat.CategoryName
		parentID := interfaceToString(cat.ParentID)
		if parentID != "0" && parentID != "" {
			categoryParentMap[cat.CategoryID] = parentID
		}
	}
	log.Printf("Loaded %d VOD categories", len(categoryNameMap))

	// Get all VOD streams
	streams, err := v.xtreamClient.GetVODStreams(&source, "")
	if err != nil {
		return nil, fmt.Errorf("failed to get VOD streams: %w", err)
	}

	result.Total = len(streams)
	log.Printf("Importing %d VOD items from source %s", result.Total, source.Name)

	for _, stream := range streams {
		// Convert interface{} types to proper types
		streamID := interfaceToInt(stream.StreamID)
		categoryID := interfaceToString(stream.CategoryID)

		// Check if already exists
		var existing models.MediaItem
		err := v.db.Where("xtream_vod_id = ? AND provider_source_id = ?", streamID, source.ID).
			First(&existing).Error

		// Build stream URL
		streamURL := v.xtreamClient.BuildVODStreamURL(&source, streamID, stream.ContainerExtension)

		// Parse year from name if present (e.g., "Movie Name (2023)")
		title, year := parseYearFromTitle(stream.Name)

		// Convert rating to float64
		var rating float64
		switch r := stream.Rating.(type) {
		case float64:
			rating = r
		case string:
			rating, _ = strconv.ParseFloat(r, 64)
		}

		// Get category name and parent info from maps
		categoryName := categoryNameMap[categoryID]
		parentCategoryID := categoryParentMap[categoryID]
		parentCategoryName := categoryNameMap[parentCategoryID]

		// If no parent, this category IS a top-level (streaming service)
		// Store it as parent for easy filtering
		if parentCategoryID == "" && categoryName != "" {
			parentCategoryID = categoryID
			parentCategoryName = categoryName
		}

		mediaItem := models.MediaItem{
			UUID:                   uuid.New().String(),
			LibraryID:              *source.VODLibraryID,
			Type:                   "movie",
			Title:                  title,
			Year:                   year,
			Thumb:                  stream.StreamIcon,
			Rating:                 rating,
			ProviderType:           "xtream",
			ProviderSourceID:       &source.ID,
			ProviderName:           source.Name,
			StreamURL:              streamURL,
			XtreamVODID:            &streamID,
			XtreamCategoryID:       categoryID,
			XtreamCategoryName:     categoryName,
			XtreamParentCategoryID: parentCategoryID,
			XtreamParentCategory:   parentCategoryName,
			AddedAt:                time.Now(),
			UpdatedAt:              time.Now(),
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
				FilePath:        fmt.Sprintf("xtream://vod/%d/%d.%s", source.ID, streamID, stream.ContainerExtension),
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

	// Fetch series categories first to build maps
	categories, err := v.xtreamClient.GetSeriesCategories(&source)
	if err != nil {
		log.Printf("Warning: could not fetch series categories: %v", err)
	}

	// Build category maps: id -> name, id -> parent_id
	categoryNameMap := make(map[string]string)  // category_id -> category_name
	categoryParentMap := make(map[string]string) // category_id -> parent_id
	for _, cat := range categories {
		categoryNameMap[cat.CategoryID] = cat.CategoryName
		parentID := interfaceToString(cat.ParentID)
		if parentID != "0" && parentID != "" {
			categoryParentMap[cat.CategoryID] = parentID
		}
	}
	log.Printf("Loaded %d series categories", len(categoryNameMap))

	// Get all series
	seriesList, err := v.xtreamClient.GetSeries(&source, "")
	if err != nil {
		return nil, fmt.Errorf("failed to get series: %w", err)
	}

	result.Total = len(seriesList)
	log.Printf("Importing %d series from source %s", result.Total, source.Name)

	for _, series := range seriesList {
		// Convert interface{} types to proper types
		seriesID := interfaceToInt(series.SeriesID)
		categoryID := interfaceToString(series.CategoryID)

		// Get category name and parent info from maps
		categoryName := categoryNameMap[categoryID]
		parentCategoryID := categoryParentMap[categoryID]
		parentCategoryName := categoryNameMap[parentCategoryID]

		// If no parent, this category IS a top-level (streaming service)
		if parentCategoryID == "" && categoryName != "" {
			parentCategoryID = categoryID
			parentCategoryName = categoryName
		}

		// Check if show already exists
		var existingShow models.MediaItem
		err := v.db.Where("xtream_series_id = ? AND provider_source_id = ? AND type = ?",
			seriesID, source.ID, "show").First(&existingShow).Error

		// Parse year
		_, year := parseYearFromTitle(series.ReleaseDate)

		// Parse rating
		var rating float64
		switch r := series.Rating.(type) {
		case float64:
			rating = r
		case string:
			rating, _ = strconv.ParseFloat(r, 64)
		}

		showItem := models.MediaItem{
			UUID:                   uuid.New().String(),
			LibraryID:              *source.SeriesLibraryID,
			Type:                   "show",
			Title:                  series.Name,
			Summary:                series.Plot,
			Year:                   year,
			Thumb:                  series.Cover,
			Rating:                 rating,
			ProviderType:           "xtream",
			ProviderSourceID:       &source.ID,
			ProviderName:           source.Name,
			XtreamSeriesID:         &seriesID,
			XtreamCategoryID:       categoryID,
			XtreamCategoryName:     categoryName,
			XtreamParentCategoryID: parentCategoryID,
			XtreamParentCategory:   parentCategoryName,
			AddedAt:                time.Now(),
			UpdatedAt:              time.Now(),
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
		seriesInfo, err := v.xtreamClient.GetSeriesInfo(&source, seriesID)
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
		err := v.db.Where("parent_id = ? AND type = ? AND `index` = ?",
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
	err := v.db.Where("parent_id = ? AND type = ? AND `index` = ?",
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

// ImportM3UVOD imports VOD movies from an M3U source into the specified library
func (v *VODImporter) ImportM3UVOD(sourceID uint) (*ImportResult, error) {
	start := time.Now()
	result := &ImportResult{}

	// Get the source
	var source models.M3USource
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

	// Parse VOD entries from the M3U
	parser := NewM3UParser(v.db)
	vodEntries, err := parser.FetchAndParseM3UVOD(source.URL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse M3U VOD: %w", err)
	}

	// Filter to only movies
	var movies []ParsedVODEntry
	for _, entry := range vodEntries {
		if entry.ContentType == "movie" {
			movies = append(movies, entry)
		}
	}

	result.Total = len(movies)
	log.Printf("Importing %d VOD movies from M3U source %s", result.Total, source.Name)

	// Track groups for category mapping
	groupMap := make(map[string]bool)
	for _, movie := range movies {
		if movie.Group != "" {
			groupMap[movie.Group] = true
		}
	}

	for _, movie := range movies {
		// Create unique identifier for this M3U VOD item
		m3uVodID := hashString(movie.StreamURL)

		// Check if already exists
		var existing models.MediaItem
		err := v.db.Where("m3u_vod_id = ? AND m3u_source_id = ?", m3uVodID, source.ID).
			First(&existing).Error

		mediaItem := models.MediaItem{
			UUID:           uuid.New().String(),
			LibraryID:      *source.VODLibraryID,
			Type:           "movie",
			Title:          movie.Name,
			Year:           movie.Year,
			Thumb:          movie.Logo,
			ProviderType:   "m3u",
			M3USourceID:    &source.ID,
			M3UVODID:       m3uVodID,
			ProviderName:   source.Name,
			StreamURL:      movie.StreamURL,
			Duration:       int64(movie.Duration) * 1000, // Convert to ms
			XtreamCategoryName: movie.Group,              // Use group as category
			AddedAt:        time.Now(),
			UpdatedAt:      time.Now(),
		}

		if err == gorm.ErrRecordNotFound {
			// Create new item
			if err := v.db.Create(&mediaItem).Error; err != nil {
				log.Printf("Failed to create M3U VOD item %s: %v", movie.Name, err)
				result.Errors++
				continue
			}

			// Create a remote media file entry
			ext := getExtensionFromURL(movie.StreamURL)
			mediaFile := models.MediaFile{
				MediaItemID:     mediaItem.ID,
				FilePath:        fmt.Sprintf("m3u://vod/%d/%s.%s", source.ID, m3uVodID, ext),
				Container:       ext,
				Duration:        int64(movie.Duration) * 1000,
				IsRemote:        true,
				RemoteURL:       movie.StreamURL,
				RemoteExtension: ext,
			}
			v.db.Create(&mediaFile)

			result.Added++
		} else if err == nil {
			// Update existing
			mediaItem.ID = existing.ID
			mediaItem.UUID = existing.UUID
			mediaItem.AddedAt = existing.AddedAt

			if err := v.db.Save(&mediaItem).Error; err != nil {
				log.Printf("Failed to update M3U VOD item %s: %v", movie.Name, err)
				result.Errors++
				continue
			}
			result.Updated++
		} else {
			result.Errors++
		}
	}

	// Update source stats
	var vodCount int64
	v.db.Model(&models.MediaItem{}).Where("m3u_source_id = ? AND type = ?", source.ID, "movie").Count(&vodCount)

	now := time.Now()
	source.LastFetched = &now
	v.db.Save(&source)

	result.Duration = time.Since(start).String()
	log.Printf("M3U VOD import complete: %d added, %d updated, %d errors in %s",
		result.Added, result.Updated, result.Errors, result.Duration)

	return result, nil
}

// ImportM3USeries imports TV series from an M3U source into the specified library
func (v *VODImporter) ImportM3USeries(sourceID uint) (*ImportResult, error) {
	start := time.Now()
	result := &ImportResult{}

	// Get the source
	var source models.M3USource
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

	// Parse VOD entries from the M3U
	parser := NewM3UParser(v.db)
	vodEntries, err := parser.FetchAndParseM3UVOD(source.URL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse M3U VOD: %w", err)
	}

	// Filter to only series episodes
	var seriesEntries []ParsedVODEntry
	for _, entry := range vodEntries {
		if entry.ContentType == "series" {
			seriesEntries = append(seriesEntries, entry)
		}
	}

	result.Total = len(seriesEntries)
	log.Printf("Importing %d series episodes from M3U source %s", result.Total, source.Name)

	// Group episodes by series name
	seriesMap := make(map[string][]ParsedVODEntry)
	for _, ep := range seriesEntries {
		seriesName := ep.SeriesName
		if seriesName == "" {
			seriesName = ep.Name // Fallback to full name if no series name extracted
		}
		seriesMap[seriesName] = append(seriesMap[seriesName], ep)
	}

	showsAdded := 0
	showsUpdated := 0

	for seriesName, episodes := range seriesMap {
		// Check if show already exists
		m3uSeriesID := hashString(seriesName + "_" + source.Name)
		var existingShow models.MediaItem
		err := v.db.Where("m3u_series_id = ? AND m3u_source_id = ? AND type = ?",
			m3uSeriesID, source.ID, "show").First(&existingShow).Error

		// Get the first episode's logo as the show thumb
		var showThumb string
		if len(episodes) > 0 {
			showThumb = episodes[0].Logo
		}

		// Get category from episodes
		var category string
		if len(episodes) > 0 {
			category = episodes[0].Group
		}

		showItem := models.MediaItem{
			UUID:               uuid.New().String(),
			LibraryID:          *source.SeriesLibraryID,
			Type:               "show",
			Title:              seriesName,
			Thumb:              showThumb,
			ProviderType:       "m3u",
			M3USourceID:        &source.ID,
			M3USeriesID:        m3uSeriesID,
			ProviderName:       source.Name,
			XtreamCategoryName: category,
			AddedAt:            time.Now(),
			UpdatedAt:          time.Now(),
		}

		var showID uint
		if err == gorm.ErrRecordNotFound {
			// Create new show
			if err := v.db.Create(&showItem).Error; err != nil {
				log.Printf("Failed to create M3U series %s: %v", seriesName, err)
				result.Errors++
				continue
			}
			showID = showItem.ID
			showsAdded++
		} else if err == nil {
			showItem.ID = existingShow.ID
			showItem.UUID = existingShow.UUID
			showItem.AddedAt = existingShow.AddedAt
			if err := v.db.Save(&showItem).Error; err != nil {
				log.Printf("Failed to update M3U series %s: %v", seriesName, err)
				result.Errors++
				continue
			}
			showID = existingShow.ID
			showsUpdated++
		} else {
			result.Errors++
			continue
		}

		// Import seasons and episodes
		v.importM3USeasonsAndEpisodes(&source, showID, seriesName, episodes)
	}

	result.Added = showsAdded
	result.Updated = showsUpdated

	// Update source stats
	now := time.Now()
	source.LastFetched = &now
	v.db.Save(&source)

	result.Duration = time.Since(start).String()
	log.Printf("M3U Series import complete: %d shows added, %d updated, %d errors in %s",
		result.Added, result.Updated, result.Errors, result.Duration)

	return result, nil
}

func (v *VODImporter) importM3USeasonsAndEpisodes(source *models.M3USource, showID uint, showTitle string, episodes []ParsedVODEntry) {
	// Get the show to access library ID
	var show models.MediaItem
	if err := v.db.First(&show, showID).Error; err != nil {
		return
	}

	// Group episodes by season
	seasonEpisodes := make(map[int][]ParsedVODEntry)
	for _, ep := range episodes {
		seasonNum := ep.SeasonNumber
		if seasonNum == 0 {
			seasonNum = 1 // Default to season 1 if not specified
		}
		seasonEpisodes[seasonNum] = append(seasonEpisodes[seasonNum], ep)
	}

	for seasonNum, eps := range seasonEpisodes {
		// Check if season exists
		var existingSeason models.MediaItem
		err := v.db.Where("parent_id = ? AND type = ? AND `index` = ?",
			showID, "season", seasonNum).First(&existingSeason).Error

		seasonItem := models.MediaItem{
			UUID:             uuid.New().String(),
			LibraryID:        show.LibraryID,
			Type:             "season",
			Title:            fmt.Sprintf("Season %d", seasonNum),
			Index:            seasonNum,
			ParentID:         &showID,
			ParentTitle:      showTitle,
			ProviderType:     "m3u",
			M3USourceID:      &source.ID,
			ProviderName:     source.Name,
			AddedAt:          time.Now(),
			UpdatedAt:        time.Now(),
		}

		var seasonID uint
		if err == gorm.ErrRecordNotFound {
			if err := v.db.Create(&seasonItem).Error; err != nil {
				log.Printf("Failed to create M3U season %d for %s: %v", seasonNum, showTitle, err)
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
		for _, ep := range eps {
			v.importM3UEpisode(source, showID, seasonID, showTitle, seasonNum, ep)
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

func (v *VODImporter) importM3UEpisode(source *models.M3USource, showID, seasonID uint, showTitle string, seasonNum int, ep ParsedVODEntry) {
	// Get season info
	var season models.MediaItem
	if err := v.db.First(&season, seasonID).Error; err != nil {
		return
	}

	episodeNum := ep.EpisodeNumber
	if episodeNum == 0 {
		// Try to assign episode number based on order
		var maxEp int
		v.db.Model(&models.MediaItem{}).Where("parent_id = ? AND type = ?", seasonID, "episode").
			Select("COALESCE(MAX(`index`), 0)").Scan(&maxEp)
		episodeNum = maxEp + 1
	}

	// Create unique identifier
	m3uEpisodeID := hashString(ep.StreamURL)

	// Check if episode exists
	var existing models.MediaItem
	err := v.db.Where("parent_id = ? AND type = ? AND m3u_episode_id = ?",
		seasonID, "episode", m3uEpisodeID).First(&existing).Error

	episodeTitle := ep.Name
	if ep.SeriesName != "" {
		// Clean up episode title by removing series name prefix if present
		episodeTitle = strings.TrimPrefix(episodeTitle, ep.SeriesName)
		episodeTitle = strings.TrimLeft(episodeTitle, " -")
	}
	if episodeTitle == "" {
		episodeTitle = fmt.Sprintf("Episode %d", episodeNum)
	}

	episodeItem := models.MediaItem{
		UUID:             uuid.New().String(),
		LibraryID:        season.LibraryID,
		Type:             "episode",
		Title:            episodeTitle,
		Index:            episodeNum,
		ParentIndex:      seasonNum,
		ParentID:         &seasonID,
		GrandparentID:    &showID,
		ParentTitle:      season.Title,
		GrandparentTitle: showTitle,
		Thumb:            ep.Logo,
		Duration:         int64(ep.Duration) * 1000, // Convert to ms
		StreamURL:        ep.StreamURL,
		ProviderType:     "m3u",
		M3USourceID:      &source.ID,
		M3UEpisodeID:     m3uEpisodeID,
		ProviderName:     source.Name,
		AddedAt:          time.Now(),
		UpdatedAt:        time.Now(),
	}

	if err == gorm.ErrRecordNotFound {
		if err := v.db.Create(&episodeItem).Error; err != nil {
			log.Printf("Failed to create M3U episode S%02dE%02d for %s: %v", seasonNum, episodeNum, showTitle, err)
			return
		}

		// Create media file
		ext := getExtensionFromURL(ep.StreamURL)
		mediaFile := models.MediaFile{
			MediaItemID:     episodeItem.ID,
			FilePath:        fmt.Sprintf("m3u://series/%d/%s.%s", source.ID, m3uEpisodeID, ext),
			Container:       ext,
			Duration:        int64(ep.Duration) * 1000,
			IsRemote:        true,
			RemoteURL:       ep.StreamURL,
			RemoteExtension: ext,
		}
		v.db.Create(&mediaFile)
	} else if err == nil {
		episodeItem.ID = existing.ID
		episodeItem.UUID = existing.UUID
		episodeItem.AddedAt = existing.AddedAt
		v.db.Save(&episodeItem)
	}
}

// hashString creates a short hash of a string for use as an ID
func hashString(s string) string {
	// Simple hash using FNV-1a
	h := uint64(14695981039346656037)
	for i := 0; i < len(s); i++ {
		h ^= uint64(s[i])
		h *= 1099511628211
	}
	return fmt.Sprintf("%x", h)
}

// getExtensionFromURL extracts the file extension from a URL
func getExtensionFromURL(u string) string {
	// Remove query string and headers
	clean := u
	if idx := strings.Index(clean, "?"); idx > 0 {
		clean = clean[:idx]
	}
	if idx := strings.Index(clean, "|"); idx > 0 {
		clean = clean[:idx]
	}

	// Get extension
	if idx := strings.LastIndex(clean, "."); idx > 0 {
		ext := clean[idx+1:]
		// Common video extensions
		validExts := map[string]bool{
			"mp4": true, "mkv": true, "avi": true, "ts": true,
			"m3u8": true, "mov": true, "wmv": true, "flv": true,
		}
		if validExts[strings.ToLower(ext)] {
			return strings.ToLower(ext)
		}
	}

	return "mp4" // Default
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
