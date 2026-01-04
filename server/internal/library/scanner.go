package library

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/metadata"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// Scanner handles media file discovery and metadata extraction
type Scanner struct {
	db         *gorm.DB
	ffprobeBin string
	tmdb       *metadata.TMDBAgent
}

// NewScanner creates a new scanner
func NewScanner(db *gorm.DB) *Scanner {
	// Try to find ffprobe
	ffprobeBin := "ffprobe"
	if path, err := exec.LookPath("ffprobe"); err == nil {
		ffprobeBin = path
	}

	return &Scanner{
		db:         db,
		ffprobeBin: ffprobeBin,
	}
}

// SetTMDBAgent sets the TMDB agent for metadata fetching
func (s *Scanner) SetTMDBAgent(agent *metadata.TMDBAgent) {
	s.tmdb = agent
}

// GetTMDBAgent returns the TMDB agent for metadata operations
func (s *Scanner) GetTMDBAgent() *metadata.TMDBAgent {
	return s.tmdb
}

// Video file extensions
var videoExtensions = map[string]bool{
	".mp4": true, ".mkv": true, ".avi": true, ".mov": true,
	".wmv": true, ".flv": true, ".webm": true, ".m4v": true,
	".mpg": true, ".mpeg": true, ".ts": true, ".m2ts": true,
}

// ScanResult contains scan statistics
type ScanResult struct {
	LibraryID    uint
	FilesFound   int
	FilesAdded   int
	FilesUpdated int
	FilesRemoved int
	Errors       []string
}

// ScanLibrary scans a library for media files
func (s *Scanner) ScanLibrary(library *models.Library) (*ScanResult, error) {
	result := &ScanResult{
		LibraryID: library.ID,
		Errors:    []string{},
	}

	// Get library paths
	var paths []models.LibraryPath
	if err := s.db.Where("library_id = ?", library.ID).Find(&paths).Error; err != nil {
		return nil, err
	}

	// Track existing files to detect removals and modifications
	existingFiles := make(map[string]*models.MediaFile)
	var existingItems []models.MediaFile
	s.db.Joins("JOIN media_items ON media_items.id = media_files.media_item_id").
		Where("media_items.library_id = ?", library.ID).
		Find(&existingItems)
	for i := range existingItems {
		existingFiles[existingItems[i].FilePath] = &existingItems[i]
	}

	foundFiles := make(map[string]bool)

	// Scan each path
	for _, libPath := range paths {
		err := filepath.Walk(libPath.Path, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				result.Errors = append(result.Errors, fmt.Sprintf("Error accessing %s: %v", path, err))
				return nil
			}

			if info.IsDir() {
				return nil
			}

			ext := strings.ToLower(filepath.Ext(path))
			if !videoExtensions[ext] {
				return nil
			}

			result.FilesFound++
			foundFiles[path] = true

			// Check if file already exists
			if existingFile, exists := existingFiles[path]; exists {
				// Check if file was modified (size or mod time changed)
				if info.Size() != existingFile.FileSize || !info.ModTime().Equal(existingFile.FileModTime) {
					if err := s.updateMediaFile(existingFile, path, info); err != nil {
						result.Errors = append(result.Errors, fmt.Sprintf("Error updating %s: %v", path, err))
					} else {
						result.FilesUpdated++
					}
				}
				return nil
			}

			// Add new file
			if err := s.addMediaFile(library, path, info); err != nil {
				result.Errors = append(result.Errors, fmt.Sprintf("Error adding %s: %v", path, err))
			} else {
				result.FilesAdded++
			}

			return nil
		})

		if err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Error walking %s: %v", libPath.Path, err))
		}
	}

	// Remove files that no longer exist
	for path, file := range existingFiles {
		if !foundFiles[path] {
			s.removeMediaFileByID(file)
			result.FilesRemoved++
		}
	}

	// Update library scan time
	now := time.Now()
	s.db.Model(library).Update("scanned_at", &now)

	return result, nil
}

// addMediaFile adds a new media file to the library
func (s *Scanner) addMediaFile(library *models.Library, filePath string, info os.FileInfo) error {
	// Parse filename to extract title info
	parsed := s.parseFilename(filePath, library.Type)

	// Get media info from ffprobe
	mediaInfo := s.getMediaInfo(filePath)

	// Create media item based on library type
	switch library.Type {
	case "movie":
		return s.addMovie(library, filePath, info, parsed, mediaInfo)
	case "show":
		return s.addEpisode(library, filePath, info, parsed, mediaInfo)
	default:
		return s.addGenericMedia(library, filePath, info, parsed, mediaInfo)
	}
}

// ParsedFilename contains parsed filename information
type ParsedFilename struct {
	Title       string
	Year        int
	Season      int
	Episode     int
	EpisodeEnd  int // For multi-episode files
	Resolution  string
	Quality     string
	ReleaseType string
}

// parseFilename extracts information from a filename
func (s *Scanner) parseFilename(filePath string, libraryType string) ParsedFilename {
	filename := filepath.Base(filePath)
	name := strings.TrimSuffix(filename, filepath.Ext(filename))

	parsed := ParsedFilename{}

	// Clean up common separators
	name = strings.ReplaceAll(name, ".", " ")
	name = strings.ReplaceAll(name, "_", " ")

	// Extract resolution
	resPatterns := []string{"2160p", "1080p", "720p", "480p", "4K", "UHD"}
	for _, res := range resPatterns {
		if strings.Contains(strings.ToUpper(name), strings.ToUpper(res)) {
			parsed.Resolution = res
			break
		}
	}

	// Extract quality indicators
	qualityPatterns := []string{"BluRay", "BDRip", "WEB-DL", "WEBRip", "HDTV", "DVDRip", "REMUX"}
	for _, q := range qualityPatterns {
		if strings.Contains(strings.ToUpper(name), strings.ToUpper(q)) {
			parsed.Quality = q
			break
		}
	}

	if libraryType == "show" {
		// TV Show patterns: S01E01, 1x01, Season 1 Episode 1
		patterns := []*regexp.Regexp{
			regexp.MustCompile(`(?i)S(\d{1,2})E(\d{1,3})(?:-?E(\d{1,3}))?`), // S01E01 or S01E01-E02
			regexp.MustCompile(`(?i)(\d{1,2})x(\d{1,3})`),                   // 1x01
			regexp.MustCompile(`(?i)Season\s*(\d{1,2})\s*Episode\s*(\d{1,3})`),
		}

		for _, pattern := range patterns {
			if matches := pattern.FindStringSubmatch(name); matches != nil {
				parsed.Season, _ = strconv.Atoi(matches[1])
				parsed.Episode, _ = strconv.Atoi(matches[2])
				if len(matches) > 3 && matches[3] != "" {
					parsed.EpisodeEnd, _ = strconv.Atoi(matches[3])
				}

				// Extract show title (everything before the episode pattern)
				idx := pattern.FindStringIndex(name)
				if idx != nil {
					parsed.Title = strings.TrimSpace(name[:idx[0]])
				}
				break
			}
		}
	}

	// Extract year
	yearPattern := regexp.MustCompile(`\(?(19\d{2}|20\d{2})\)?`)
	if matches := yearPattern.FindStringSubmatch(name); matches != nil {
		parsed.Year, _ = strconv.Atoi(matches[1])

		// For movies, title is everything before the year
		if libraryType == "movie" && parsed.Title == "" {
			idx := yearPattern.FindStringIndex(name)
			if idx != nil {
				parsed.Title = strings.TrimSpace(name[:idx[0]])
			}
		}
	}

	// If no title extracted, use the cleaned filename
	if parsed.Title == "" {
		// Remove quality/resolution info
		title := name
		for _, pattern := range []string{parsed.Resolution, parsed.Quality} {
			if pattern != "" {
				title = regexp.MustCompile(`(?i)`+regexp.QuoteMeta(pattern)).ReplaceAllString(title, "")
			}
		}
		parsed.Title = strings.TrimSpace(title)
	}

	return parsed
}

// MediaInfo contains technical information about a media file
type MediaInfo struct {
	Duration    int64  // in milliseconds
	Width       int
	Height      int
	VideoCodec  string
	AudioCodec  string
	AudioLang   string
	Container   string
	Bitrate     int64
	HasSubtitle bool
}

// getMediaInfo uses ffprobe to get media information
func (s *Scanner) getMediaInfo(filePath string) MediaInfo {
	info := MediaInfo{}

	cmd := exec.Command(s.ffprobeBin,
		"-v", "quiet",
		"-print_format", "json",
		"-show_format",
		"-show_streams",
		filePath,
	)

	output, err := cmd.Output()
	if err != nil {
		return info
	}

	var probe struct {
		Format struct {
			Duration string `json:"duration"`
			BitRate  string `json:"bit_rate"`
		} `json:"format"`
		Streams []struct {
			CodecType string `json:"codec_type"`
			CodecName string `json:"codec_name"`
			Width     int    `json:"width"`
			Height    int    `json:"height"`
			Tags      struct {
				Language string `json:"language"`
			} `json:"tags"`
		} `json:"streams"`
	}

	if err := json.Unmarshal(output, &probe); err != nil {
		return info
	}

	// Parse duration
	if dur, err := strconv.ParseFloat(probe.Format.Duration, 64); err == nil {
		info.Duration = int64(dur * 1000)
	}

	// Parse bitrate
	if br, err := strconv.ParseInt(probe.Format.BitRate, 10, 64); err == nil {
		info.Bitrate = br
	}

	// Get stream info
	for _, stream := range probe.Streams {
		switch stream.CodecType {
		case "video":
			info.VideoCodec = stream.CodecName
			info.Width = stream.Width
			info.Height = stream.Height
		case "audio":
			if info.AudioCodec == "" {
				info.AudioCodec = stream.CodecName
				info.AudioLang = stream.Tags.Language
			}
		case "subtitle":
			info.HasSubtitle = true
		}
	}

	return info
}

// addMovie adds a movie to the library
func (s *Scanner) addMovie(library *models.Library, filePath string, fileInfo os.FileInfo, parsed ParsedFilename, mediaInfo MediaInfo) error {
	// Create media item
	item := models.MediaItem{
		UUID:      uuid.New().String(),
		LibraryID: library.ID,
		Type:      "movie",
		Title:     parsed.Title,
		SortTitle: strings.ToLower(parsed.Title),
		Year:      parsed.Year,
		Duration:  mediaInfo.Duration,
		AddedAt:   time.Now(),
	}

	if err := s.db.Create(&item).Error; err != nil {
		return err
	}

	// Fetch TMDB metadata in background (don't block scanning)
	if s.tmdb != nil {
		go func() {
			if err := s.tmdb.UpdateMovieMetadata(&item); err != nil {
				fmt.Printf("TMDB metadata fetch failed for %s: %v\n", item.Title, err)
			}
		}()
	}

	// Create media file
	return s.createMediaFile(&item, filePath, fileInfo, mediaInfo)
}

// addEpisode adds a TV episode to the library
func (s *Scanner) addEpisode(library *models.Library, filePath string, fileInfo os.FileInfo, parsed ParsedFilename, mediaInfo MediaInfo) error {
	// Find or create show
	show, err := s.findOrCreateShow(library, parsed.Title, parsed.Year)
	if err != nil {
		return err
	}

	// Find or create season
	season, err := s.findOrCreateSeason(library, show, parsed.Season)
	if err != nil {
		return err
	}

	// Create episode
	episode := models.MediaItem{
		UUID:          uuid.New().String(),
		LibraryID:     library.ID,
		Type:          "episode",
		Title:         fmt.Sprintf("Episode %d", parsed.Episode),
		ParentID:      &season.ID,
		GrandparentID: &show.ID,
		Index:         parsed.Episode,
		Duration:      mediaInfo.Duration,
		AddedAt:       time.Now(),
	}

	if err := s.db.Create(&episode).Error; err != nil {
		return err
	}

	return s.createMediaFile(&episode, filePath, fileInfo, mediaInfo)
}

// findOrCreateShow finds or creates a TV show
func (s *Scanner) findOrCreateShow(library *models.Library, title string, year int) (*models.MediaItem, error) {
	var show models.MediaItem

	query := s.db.Where("library_id = ? AND type = ? AND title = ?", library.ID, "show", title)
	if year > 0 {
		query = query.Where("year = ?", year)
	}

	if err := query.First(&show).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Create new show
			show = models.MediaItem{
				UUID:      uuid.New().String(),
				LibraryID: library.ID,
				Type:      "show",
				Title:     title,
				SortTitle: strings.ToLower(title),
				Year:      year,
				AddedAt:   time.Now(),
			}
			if err := s.db.Create(&show).Error; err != nil {
				return nil, err
			}

			// Fetch TMDB metadata for new show in background
			if s.tmdb != nil {
				go func() {
					if err := s.tmdb.UpdateShowMetadata(&show); err != nil {
						fmt.Printf("TMDB metadata fetch failed for show %s: %v\n", show.Title, err)
					}
				}()
			}
		} else {
			return nil, err
		}
	}

	return &show, nil
}

// findOrCreateSeason finds or creates a TV season
func (s *Scanner) findOrCreateSeason(library *models.Library, show *models.MediaItem, seasonNum int) (*models.MediaItem, error) {
	var season models.MediaItem

	if err := s.db.Where("library_id = ? AND type = ? AND parent_id = ? AND `index` = ?",
		library.ID, "season", show.ID, seasonNum).First(&season).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Create new season
			season = models.MediaItem{
				UUID:      uuid.New().String(),
				LibraryID: library.ID,
				Type:      "season",
				Title:     fmt.Sprintf("Season %d", seasonNum),
				ParentID:  &show.ID,
				Index:     seasonNum,
				AddedAt:   time.Now(),
			}
			if err := s.db.Create(&season).Error; err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
	}

	return &season, nil
}

// addGenericMedia adds a generic media item
func (s *Scanner) addGenericMedia(library *models.Library, filePath string, fileInfo os.FileInfo, parsed ParsedFilename, mediaInfo MediaInfo) error {
	item := models.MediaItem{
		UUID:      uuid.New().String(),
		LibraryID: library.ID,
		Type:      library.Type,
		Title:     parsed.Title,
		SortTitle: strings.ToLower(parsed.Title),
		Year:      parsed.Year,
		Duration:  mediaInfo.Duration,
		AddedAt:   time.Now(),
	}

	if err := s.db.Create(&item).Error; err != nil {
		return err
	}

	return s.createMediaFile(&item, filePath, fileInfo, mediaInfo)
}

// createMediaFile creates a media file record
func (s *Scanner) createMediaFile(item *models.MediaItem, filePath string, fileInfo os.FileInfo, mediaInfo MediaInfo) error {
	file := models.MediaFile{
		MediaItemID: item.ID,
		FilePath:    filePath,
		FileSize:    fileInfo.Size(),
		FileModTime: fileInfo.ModTime(),
		Container:   strings.TrimPrefix(filepath.Ext(filePath), "."),
		Duration:    mediaInfo.Duration,
		Bitrate:     int(mediaInfo.Bitrate),
		Width:       mediaInfo.Width,
		Height:      mediaInfo.Height,
		VideoCodec:  mediaInfo.VideoCodec,
		AudioCodec:  mediaInfo.AudioCodec,
	}

	if err := s.db.Create(&file).Error; err != nil {
		return err
	}

	// Create stream records
	s.createStreamRecords(&file, mediaInfo)

	return nil
}

// updateMediaFile updates an existing media file that was modified
func (s *Scanner) updateMediaFile(existingFile *models.MediaFile, filePath string, fileInfo os.FileInfo) error {
	// Re-scan media info
	mediaInfo := s.getMediaInfo(filePath)

	// Update file record
	updates := map[string]interface{}{
		"file_size":     fileInfo.Size(),
		"file_mod_time": fileInfo.ModTime(),
		"duration":      mediaInfo.Duration,
		"bitrate":       int(mediaInfo.Bitrate),
		"width":         mediaInfo.Width,
		"height":        mediaInfo.Height,
		"video_codec":   mediaInfo.VideoCodec,
		"audio_codec":   mediaInfo.AudioCodec,
	}

	if err := s.db.Model(existingFile).Updates(updates).Error; err != nil {
		return err
	}

	// Delete old streams and recreate
	s.db.Where("media_file_id = ?", existingFile.ID).Delete(&models.MediaStream{})
	s.createStreamRecords(existingFile, mediaInfo)

	// Update media item duration if changed
	if mediaInfo.Duration > 0 {
		s.db.Model(&models.MediaItem{}).Where("id = ?", existingFile.MediaItemID).
			Update("duration", mediaInfo.Duration)
	}

	return nil
}

// createStreamRecords creates audio/video/subtitle stream records for a file
func (s *Scanner) createStreamRecords(file *models.MediaFile, mediaInfo MediaInfo) {
	// Create video stream record
	if mediaInfo.VideoCodec != "" {
		videoStream := models.MediaStream{
			MediaFileID: file.ID,
			StreamType:  1, // 1=video
			Codec:       mediaInfo.VideoCodec,
			Index:       0,
			Width:       mediaInfo.Width,
			Height:      mediaInfo.Height,
		}
		s.db.Create(&videoStream)
	}

	// Create audio stream record
	if mediaInfo.AudioCodec != "" {
		audioStream := models.MediaStream{
			MediaFileID: file.ID,
			StreamType:  2, // 2=audio
			Codec:       mediaInfo.AudioCodec,
			Index:       1,
			Language:    mediaInfo.AudioLang,
		}
		s.db.Create(&audioStream)
	}
}

// removeMediaFile removes a media file that no longer exists (by path lookup)
func (s *Scanner) removeMediaFile(filePath string) {
	var file models.MediaFile
	if err := s.db.Where("file_path = ?", filePath).First(&file).Error; err != nil {
		return
	}
	s.removeMediaFileByID(&file)
}

// removeMediaFileByID removes a media file that no longer exists (by ID)
func (s *Scanner) removeMediaFileByID(file *models.MediaFile) {
	// Delete streams
	s.db.Where("media_file_id = ?", file.ID).Delete(&models.MediaStream{})

	// Delete file
	s.db.Delete(file)

	// Check if media item has other files, if not delete it
	var count int64
	s.db.Model(&models.MediaFile{}).Where("media_item_id = ?", file.MediaItemID).Count(&count)
	if count == 0 {
		s.db.Delete(&models.MediaItem{}, file.MediaItemID)
	}
}
