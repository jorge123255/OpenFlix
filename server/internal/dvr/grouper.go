package dvr

import (
	"regexp"
	"strings"

	"github.com/openflix/openflix-server/internal/models"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

// Grouper handles auto-grouping of DVRFiles into DVRGroups by series title
type Grouper struct {
	db     *gorm.DB
	logger *logrus.Entry
}

// NewGrouper creates a new DVR file grouper
func NewGrouper(db *gorm.DB) *Grouper {
	return &Grouper{
		db:     db,
		logger: logrus.WithField("component", "dvr-grouper"),
	}
}

// AssignFileToGroup finds or creates a DVRGroup for the given file and links them.
// For movies, each movie gets its own group. For TV, episodes of the same show share a group.
func (g *Grouper) AssignFileToGroup(file *models.DVRFile) error {
	if file.GroupID != nil {
		return nil // Already assigned
	}

	groupTitle := g.normalizeTitle(file.Title)
	if groupTitle == "" {
		return nil
	}

	// For movies, use the exact title (each movie = own group)
	// For TV shows, the title is the show name (shared group)
	var group models.DVRGroup

	// Try matching by TMDB ID first (most reliable)
	if file.TMDBId != nil && *file.TMDBId > 0 {
		tmdbType := "tv"
		if file.IsMovie {
			tmdbType = "movie"
		}
		err := g.db.Where("tmdb_id = ? AND tmdb_type = ?", *file.TMDBId, tmdbType).First(&group).Error
		if err == nil {
			return g.linkFileToGroup(file, &group)
		}
	}

	// Try matching by normalized title
	err := g.db.Where("LOWER(title) = LOWER(?)", groupTitle).First(&group).Error
	if err == nil {
		// Verify TMDB match if both have IDs
		if file.TMDBId != nil && group.TMDBId != nil && *file.TMDBId != *group.TMDBId {
			// Different TMDB IDs - create a new group for this file
			return g.createGroupForFile(file, groupTitle)
		}
		return g.linkFileToGroup(file, &group)
	}

	// No existing group found - create one
	return g.createGroupForFile(file, groupTitle)
}

// createGroupForFile creates a new DVRGroup from a file's metadata
func (g *Grouper) createGroupForFile(file *models.DVRFile, groupTitle string) error {
	tmdbType := "tv"
	if file.IsMovie {
		tmdbType = "movie"
	}

	group := models.DVRGroup{
		Title:         groupTitle,
		SortTitle:     g.sortTitle(groupTitle),
		Description:   file.Description,
		Thumb:         file.Thumb,
		Art:           file.Art,
		Categories:    file.Category,
		Genres:        file.Genres,
		ContentRating: file.ContentRating,
		Year:          file.Year,
		TMDBId:        file.TMDBId,
		TMDBType:      tmdbType,
		FileCount:     1,
	}

	if err := g.db.Create(&group).Error; err != nil {
		g.logger.WithError(err).WithField("title", groupTitle).Warn("Failed to create DVRGroup")
		return err
	}

	file.GroupID = &group.ID
	if err := g.db.Model(file).Update("group_id", group.ID).Error; err != nil {
		return err
	}

	g.logger.WithFields(logrus.Fields{
		"group_id":    group.ID,
		"group_title": group.Title,
		"file_id":     file.ID,
	}).Info("Created new DVRGroup for file")

	return nil
}

// linkFileToGroup links a file to an existing group and updates the group metadata
func (g *Grouper) linkFileToGroup(file *models.DVRFile, group *models.DVRGroup) error {
	file.GroupID = &group.ID
	if err := g.db.Model(file).Update("group_id", group.ID).Error; err != nil {
		return err
	}

	// Update group file count
	var count int64
	g.db.Model(&models.DVRFile{}).Where("group_id = ? AND deleted = ?", group.ID, false).Count(&count)
	group.FileCount = int(count)

	// Update group art/thumb if the group doesn't have it but the file does
	updates := map[string]interface{}{
		"file_count": count,
	}
	if group.Thumb == "" && file.Thumb != "" {
		updates["thumb"] = file.Thumb
	}
	if group.Art == "" && file.Art != "" {
		updates["art"] = file.Art
	}
	if group.TMDBId == nil && file.TMDBId != nil {
		updates["tmdb_id"] = file.TMDBId
		if file.IsMovie {
			updates["tmdb_type"] = "movie"
		} else {
			updates["tmdb_type"] = "tv"
		}
	}
	if group.Genres == "" && file.Genres != "" {
		updates["genres"] = file.Genres
	}
	if group.ContentRating == "" && file.ContentRating != "" {
		updates["content_rating"] = file.ContentRating
	}
	if group.Year == nil && file.Year != nil {
		updates["year"] = file.Year
	}

	g.db.Model(group).Updates(updates)

	g.logger.WithFields(logrus.Fields{
		"group_id":    group.ID,
		"group_title": group.Title,
		"file_id":     file.ID,
		"file_count":  count,
	}).Debug("Linked file to existing DVRGroup")

	return nil
}

// GroupUngroupedFiles scans for DVRFiles without a group and assigns them.
// Called periodically or on-demand.
func (g *Grouper) GroupUngroupedFiles() (int, error) {
	var files []models.DVRFile
	g.db.Where("group_id IS NULL AND deleted = ? AND completed = ?", false, true).Find(&files)

	if len(files) == 0 {
		return 0, nil
	}

	grouped := 0
	for i := range files {
		if err := g.AssignFileToGroup(&files[i]); err != nil {
			g.logger.WithError(err).WithField("file_id", files[i].ID).Warn("Failed to group file")
			continue
		}
		grouped++
	}

	g.logger.WithFields(logrus.Fields{
		"total":   len(files),
		"grouped": grouped,
	}).Info("Grouped ungrouped DVR files")

	return grouped, nil
}

// normalizeTitle cleans up a title for group matching
func (g *Grouper) normalizeTitle(title string) string {
	clean := title

	// Remove S01E05 patterns
	patterns := []*regexp.Regexp{
		regexp.MustCompile(`(?i)\s*[\-\.]*\s*S\d{1,2}E\d{1,2}.*$`),
		regexp.MustCompile(`(?i)\s*[\-\.]*\s*\d{1,2}x\d{1,2}.*$`),
		regexp.MustCompile(`(?i)\s*[\-\.]*\s*Season\s*\d+\s*Episode\s*\d+.*$`),
	}
	for _, p := range patterns {
		clean = p.ReplaceAllString(clean, "")
	}

	// Remove subtitle after " - " (e.g., "Seinfeld - The Contest")
	if idx := strings.Index(clean, " - "); idx > 0 {
		clean = clean[:idx]
	}

	// Remove trailing year in parens (e.g., "Movie (2024)")
	clean = regexp.MustCompile(`\s*\(\d{4}\)\s*$`).ReplaceAllString(clean, "")

	// Remove "(New)" or "(Rerun)" suffixes
	clean = regexp.MustCompile(`(?i)\s*\((new|rerun|repeat|live)\)\s*$`).ReplaceAllString(clean, "")

	return strings.TrimSpace(clean)
}

// sortTitle creates a sort-friendly title (strips leading "The ", "A ", etc.)
func (g *Grouper) sortTitle(title string) string {
	lower := strings.ToLower(title)
	for _, prefix := range []string{"the ", "a ", "an "} {
		if strings.HasPrefix(lower, prefix) {
			return strings.TrimSpace(title[len(prefix):])
		}
	}
	return title
}
