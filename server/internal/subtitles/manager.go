package subtitles

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// SubtitleConfig holds the OpenSubtitles configuration.
type SubtitleConfig struct {
	APIKey       string   `json:"apiKey"`
	AutoDownload bool     `json:"autoDownload"`
	Languages    []string `json:"languages"` // ISO 639-1 codes, e.g. ["en", "fr"]
}

// DownloadedSubtitle tracks a downloaded subtitle to avoid re-downloading.
type DownloadedSubtitle struct {
	ID           uint   `gorm:"primaryKey" json:"id"`
	MediaItemID  uint   `gorm:"index:idx_sub_media_lang,unique" json:"mediaItemId"`
	Language     string `gorm:"size:10;index:idx_sub_media_lang,unique" json:"language"`
	FilePath     string `gorm:"size:2000" json:"filePath"`
	FileName     string `gorm:"size:500" json:"fileName"`
	OpenSubID    string `gorm:"size:100" json:"openSubId"` // OpenSubtitles file ID
	Format       string `gorm:"size:10" json:"format"`     // srt, vtt
	DownloadedAt int64  `json:"downloadedAt"`              // Unix timestamp
}

// LocalSubtitle represents a subtitle file found on disk alongside a media file.
type LocalSubtitle struct {
	FilePath string `json:"filePath"`
	FileName string `json:"fileName"`
	Language string `json:"language"`
	Format   string `json:"format"`
}

// SubtitleManager handles subtitle search, download, and management.
type SubtitleManager struct {
	db     *gorm.DB
	client *Client
	config SubtitleConfig
	mu     sync.RWMutex
}

// NewSubtitleManager creates a new SubtitleManager.
func NewSubtitleManager(db *gorm.DB, cfg SubtitleConfig) *SubtitleManager {
	// Auto-migrate the downloaded subtitles table
	if err := db.AutoMigrate(&DownloadedSubtitle{}); err != nil {
		logger.Warnf("Failed to auto-migrate DownloadedSubtitle: %v", err)
	}

	var client *Client
	if cfg.APIKey != "" {
		client = NewClient(cfg.APIKey)
	}

	return &SubtitleManager{
		db:     db,
		client: client,
		config: cfg,
	}
}

// GetConfig returns the current subtitle configuration.
func (m *SubtitleManager) GetConfig() SubtitleConfig {
	m.mu.RLock()
	defer m.mu.RUnlock()
	cfg := m.config
	// Make a copy of the languages slice
	cfg.Languages = make([]string, len(m.config.Languages))
	copy(cfg.Languages, m.config.Languages)
	return cfg
}

// UpdateConfig updates the subtitle configuration.
func (m *SubtitleManager) UpdateConfig(cfg SubtitleConfig) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.config = cfg
	if cfg.APIKey != "" {
		if m.client == nil {
			m.client = NewClient(cfg.APIKey)
		} else {
			m.client.SetAPIKey(cfg.APIKey)
		}
	} else {
		m.client = nil
	}
}

// HasAPIKey returns true if an API key is configured.
func (m *SubtitleManager) HasAPIKey() bool {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.config.APIKey != ""
}

// getClient returns the current client (thread-safe).
func (m *SubtitleManager) getClient() *Client {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.client
}

// getLanguages returns the configured language preferences.
func (m *SubtitleManager) getLanguages() []string {
	m.mu.RLock()
	defer m.mu.RUnlock()
	if len(m.config.Languages) > 0 {
		langs := make([]string, len(m.config.Languages))
		copy(langs, m.config.Languages)
		return langs
	}
	return []string{"en"}
}

// SearchForMedia searches OpenSubtitles for subtitles matching a media item.
func (m *SubtitleManager) SearchForMedia(mediaItem *models.MediaItem, languages []string) (*SearchResponse, error) {
	client := m.getClient()
	if client == nil {
		return nil, fmt.Errorf("OpenSubtitles API key not configured")
	}

	if len(languages) == 0 {
		languages = m.getLanguages()
	}

	// Try searching by file hash first (most accurate)
	if len(mediaItem.MediaFiles) > 0 {
		for _, mf := range mediaItem.MediaFiles {
			if mf.IsRemote || mf.FilePath == "" {
				continue
			}
			hash, err := ComputeHash(mf.FilePath)
			if err != nil {
				logger.Debugf("Could not compute hash for %s: %v", mf.FilePath, err)
				continue
			}
			result, err := client.SearchByHash(hash, languages)
			if err == nil && result.TotalCount > 0 {
				return result, nil
			}
		}
	}

	// Fall back to TMDB ID search
	tmdbID := extractTMDBID(mediaItem.UUID)
	if tmdbID > 0 {
		if mediaItem.Type == "episode" {
			// For episodes, search by parent show TMDB ID + season/episode
			parentTMDBID := 0
			if mediaItem.GrandparentID != nil {
				var show models.MediaItem
				if err := m.db.First(&show, *mediaItem.GrandparentID).Error; err == nil {
					parentTMDBID = extractTMDBID(show.UUID)
				}
			}
			if parentTMDBID > 0 {
				result, err := client.SearchByEpisode(parentTMDBID, mediaItem.ParentIndex, mediaItem.Index, languages)
				if err == nil && result.TotalCount > 0 {
					return result, nil
				}
			}
		}

		result, err := client.SearchByTMDBID(tmdbID, languages)
		if err == nil && result.TotalCount > 0 {
			return result, nil
		}
	}

	// Fall back to title + year search
	title := mediaItem.Title
	year := mediaItem.Year
	return client.SearchByTitle(title, year, languages)
}

// SearchByTitleYear searches OpenSubtitles by title and year.
func (m *SubtitleManager) SearchByTitleYear(title string, year int, languages []string) (*SearchResponse, error) {
	client := m.getClient()
	if client == nil {
		return nil, fmt.Errorf("OpenSubtitles API key not configured")
	}

	if len(languages) == 0 {
		languages = m.getLanguages()
	}

	return client.SearchByTitle(title, year, languages)
}

// DownloadSubtitle downloads a subtitle file by its OpenSubtitles file ID
// and saves it alongside the media file.
func (m *SubtitleManager) DownloadSubtitle(mediaItemID uint, fileID int, language string) (*DownloadedSubtitle, error) {
	client := m.getClient()
	if client == nil {
		return nil, fmt.Errorf("OpenSubtitles API key not configured")
	}

	// Check if already downloaded
	var existing DownloadedSubtitle
	if err := m.db.Where("media_item_id = ? AND language = ?", mediaItemID, language).First(&existing).Error; err == nil {
		return &existing, nil
	}

	// Get the media item to determine save location
	var mediaItem models.MediaItem
	if err := m.db.Preload("MediaFiles").First(&mediaItem, mediaItemID).Error; err != nil {
		return nil, fmt.Errorf("media item not found: %w", err)
	}

	// Find a local media file to save the subtitle next to
	savePath, baseName := m.getSubtitleSavePath(&mediaItem)
	if savePath == "" {
		return nil, fmt.Errorf("no local media file found to save subtitle alongside")
	}

	// Request download link from OpenSubtitles
	dlResp, err := client.Download(fileID)
	if err != nil {
		return nil, fmt.Errorf("requesting download link: %w", err)
	}

	// Download the actual file
	data, err := client.DownloadFile(dlResp.Link)
	if err != nil {
		return nil, fmt.Errorf("downloading subtitle file: %w", err)
	}

	// Determine format from the file name
	format := "srt"
	if dlResp.FileName != "" {
		ext := strings.ToLower(filepath.Ext(dlResp.FileName))
		if ext == ".vtt" {
			format = "vtt"
		} else if ext == ".srt" {
			format = "srt"
		}
	}

	// Build the subtitle filename: basename.lang.format
	subFileName := fmt.Sprintf("%s.%s.%s", baseName, language, format)
	subFilePath := filepath.Join(savePath, subFileName)

	// Write the file
	if err := os.WriteFile(subFilePath, data, 0644); err != nil {
		return nil, fmt.Errorf("writing subtitle file: %w", err)
	}

	logger.Infof("Downloaded subtitle: %s", subFilePath)

	// Record in database
	downloaded := &DownloadedSubtitle{
		MediaItemID:  mediaItemID,
		Language:     language,
		FilePath:     subFilePath,
		FileName:     subFileName,
		OpenSubID:    fmt.Sprintf("%d", fileID),
		Format:       format,
		DownloadedAt: time.Now().Unix(),
	}

	if err := m.db.Create(downloaded).Error; err != nil {
		// File was saved but DB record failed - not critical
		logger.Warnf("Failed to record downloaded subtitle in DB: %v", err)
	}

	return downloaded, nil
}

// GetSubtitlesForMedia returns both local and downloaded subtitles for a media item.
func (m *SubtitleManager) GetSubtitlesForMedia(mediaItemID uint) ([]LocalSubtitle, []DownloadedSubtitle, error) {
	var mediaItem models.MediaItem
	if err := m.db.Preload("MediaFiles").First(&mediaItem, mediaItemID).Error; err != nil {
		return nil, nil, fmt.Errorf("media item not found: %w", err)
	}

	// Find local subtitle files on disk
	localSubs := m.findLocalSubtitles(&mediaItem)

	// Find downloaded subtitles from DB
	var downloadedSubs []DownloadedSubtitle
	m.db.Where("media_item_id = ?", mediaItemID).Find(&downloadedSubs)

	return localSubs, downloadedSubs, nil
}

// DeleteSubtitle removes a downloaded subtitle file and its DB record.
func (m *SubtitleManager) DeleteSubtitle(mediaItemID uint, language string) error {
	var sub DownloadedSubtitle
	if err := m.db.Where("media_item_id = ? AND language = ?", mediaItemID, language).First(&sub).Error; err != nil {
		return fmt.Errorf("subtitle not found: %w", err)
	}

	// Remove file from disk
	if sub.FilePath != "" {
		if err := os.Remove(sub.FilePath); err != nil && !os.IsNotExist(err) {
			logger.Warnf("Failed to delete subtitle file %s: %v", sub.FilePath, err)
		}
	}

	// Remove DB record
	if err := m.db.Delete(&sub).Error; err != nil {
		return fmt.Errorf("deleting subtitle record: %w", err)
	}

	logger.Infof("Deleted subtitle for media %d, language %s", mediaItemID, language)
	return nil
}

// AutoSearchAndDownload searches and downloads subtitles for a media item
// using the configured language preferences.
func (m *SubtitleManager) AutoSearchAndDownload(mediaItem *models.MediaItem) {
	if !m.HasAPIKey() {
		return
	}

	m.mu.RLock()
	autoDownload := m.config.AutoDownload
	m.mu.RUnlock()

	if !autoDownload {
		return
	}

	languages := m.getLanguages()

	for _, lang := range languages {
		// Skip if already downloaded
		var count int64
		m.db.Model(&DownloadedSubtitle{}).Where("media_item_id = ? AND language = ?", mediaItem.ID, lang).Count(&count)
		if count > 0 {
			continue
		}

		// Search for subtitles
		result, err := m.SearchForMedia(mediaItem, []string{lang})
		if err != nil {
			logger.Debugf("Auto-search subtitles for %q (%s) failed: %v", mediaItem.Title, lang, err)
			continue
		}

		if result.TotalCount == 0 || len(result.Data) == 0 {
			continue
		}

		// Pick the best result (first one, which is typically highest rated)
		best := result.Data[0]
		if len(best.Attributes.Files) == 0 {
			continue
		}

		fileID := best.Attributes.Files[0].FileID
		_, err = m.DownloadSubtitle(mediaItem.ID, fileID, lang)
		if err != nil {
			logger.Warnf("Auto-download subtitle for %q (%s) failed: %v", mediaItem.Title, lang, err)
		}
	}
}

// GetLanguageForProfile returns the subtitle language for a user profile,
// falling back to the manager's configured language or "en".
func (m *SubtitleManager) GetLanguageForProfile(profileID uint) string {
	var profile models.UserProfile
	if err := m.db.First(&profile, profileID).Error; err == nil {
		if profile.DefaultSubtitleLanguage != "" {
			return profile.DefaultSubtitleLanguage
		}
	}

	langs := m.getLanguages()
	if len(langs) > 0 {
		return langs[0]
	}
	return "en"
}

// ========== Internal Helpers ==========

// getSubtitleSavePath determines where to save a subtitle file for a media item.
// Returns the directory and base name (without extension).
func (m *SubtitleManager) getSubtitleSavePath(mediaItem *models.MediaItem) (string, string) {
	for _, mf := range mediaItem.MediaFiles {
		if mf.IsRemote || mf.FilePath == "" {
			continue
		}
		dir := filepath.Dir(mf.FilePath)
		base := strings.TrimSuffix(filepath.Base(mf.FilePath), filepath.Ext(mf.FilePath))
		return dir, base
	}
	return "", ""
}

// findLocalSubtitles scans the filesystem for subtitle files alongside media files.
func (m *SubtitleManager) findLocalSubtitles(mediaItem *models.MediaItem) []LocalSubtitle {
	var subs []LocalSubtitle

	for _, mf := range mediaItem.MediaFiles {
		if mf.IsRemote || mf.FilePath == "" {
			continue
		}

		dir := filepath.Dir(mf.FilePath)
		base := strings.TrimSuffix(filepath.Base(mf.FilePath), filepath.Ext(mf.FilePath))

		// Look for subtitle files matching the pattern: basename.*.srt, basename.*.vtt, basename.srt, etc.
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}

		for _, entry := range entries {
			if entry.IsDir() {
				continue
			}
			name := entry.Name()
			ext := strings.ToLower(filepath.Ext(name))
			if ext != ".srt" && ext != ".vtt" && ext != ".ass" && ext != ".ssa" && ext != ".sub" {
				continue
			}

			nameNoExt := strings.TrimSuffix(name, ext)
			if !strings.HasPrefix(nameNoExt, base) {
				continue
			}

			// Extract language from filename (e.g., "movie.en.srt" -> "en")
			lang := ""
			remaining := strings.TrimPrefix(nameNoExt, base)
			remaining = strings.TrimPrefix(remaining, ".")
			if remaining != "" {
				lang = remaining
			}

			subs = append(subs, LocalSubtitle{
				FilePath: filepath.Join(dir, name),
				FileName: name,
				Language: lang,
				Format:   strings.TrimPrefix(ext, "."),
			})
		}
	}

	return subs
}

// extractTMDBID extracts a TMDB ID from a GUID string like "tmdb://12345".
func extractTMDBID(guid string) int {
	if strings.HasPrefix(guid, "tmdb://") {
		idStr := strings.TrimPrefix(guid, "tmdb://")
		var id int
		if _, err := fmt.Sscanf(idStr, "%d", &id); err == nil {
			return id
		}
	}
	return 0
}
