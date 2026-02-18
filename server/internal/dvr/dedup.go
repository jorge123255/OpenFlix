package dvr

import (
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// DuplicateDetector checks whether a DVR job would record content
// that has already been recorded or is already scheduled. It matches
// across multiple sources (different channels carrying the same show)
// using title+subtitle, title+airdate, programID, and title+season+episode.
type DuplicateDetector struct {
	db *gorm.DB
}

// NewDuplicateDetector creates a new DuplicateDetector.
func NewDuplicateDetector(db *gorm.DB) *DuplicateDetector {
	return &DuplicateDetector{db: db}
}

// DuplicateMatch contains details about a detected duplicate.
type DuplicateMatch struct {
	MatchedFile *models.DVRFile `json:"matchedFile,omitempty"`
	MatchedJob  *models.DVRJob  `json:"matchedJob,omitempty"`
	MatchType   string          `json:"matchType"` // title_subtitle, title_airdate, program_id, title_season_episode
}

// IsDuplicate checks whether the given job would duplicate an existing
// completed file or scheduled/recording job. It returns whether a duplicate
// was found, and the matching file or job that it duplicates.
//
// The check is performed across all sources for the same user using these
// strategies in order:
//   1. Exact programID match (strongest signal)
//   2. Title + Season + Episode number match
//   3. Title + Subtitle match (for episode-titled shows)
//   4. Title + OriginalAirDate match (for shows identified by airdate)
func (d *DuplicateDetector) IsDuplicate(job models.DVRJob) (bool, *DuplicateMatch) {
	if job.Title == "" {
		return false, nil
	}

	userID := job.UserID

	// Strategy 1: ProgramID match (exact EPG program dedup)
	if job.ProgramID != nil && *job.ProgramID > 0 {
		// Check completed files linked to jobs with the same programID
		var existingJob models.DVRJob
		err := d.db.Where(
			"user_id = ? AND program_id = ? AND id != ? AND status IN ? AND accepted_duplicate = ?",
			userID, *job.ProgramID, job.ID,
			[]string{"scheduled", "recording", "completed"},
			false,
		).First(&existingJob).Error
		if err == nil {
			return true, &DuplicateMatch{
				MatchedJob: &existingJob,
				MatchType:  "program_id",
			}
		}
	}

	// Strategy 2: Title + Season + Episode number
	if job.EpisodeNum != "" {
		season, episode := parseEpisodeNum(job.EpisodeNum)
		if season > 0 && episode > 0 {
			// Check files
			var file models.DVRFile
			err := d.db.Where(
				"title = ? AND season_number = ? AND episode_number = ? AND deleted = ? AND completed = ?",
				job.Title, season, episode, false, true,
			).First(&file).Error
			if err == nil {
				return true, &DuplicateMatch{
					MatchedFile: &file,
					MatchType:   "title_season_episode",
				}
			}

			// Check scheduled/recording jobs
			var existingJob models.DVRJob
			err = d.db.Where(
				"user_id = ? AND title = ? AND episode_num = ? AND id != ? AND status IN ? AND accepted_duplicate = ?",
				userID, job.Title, job.EpisodeNum, job.ID,
				[]string{"scheduled", "recording", "completed"},
				false,
			).First(&existingJob).Error
			if err == nil {
				return true, &DuplicateMatch{
					MatchedJob: &existingJob,
					MatchType:  "title_season_episode",
				}
			}
		}
	}

	// Strategy 3: Title + Subtitle (for shows with distinct episode titles)
	if job.Subtitle != "" {
		normalizedTitle := normalizeTitle(job.Title)
		normalizedSubtitle := normalizeTitle(job.Subtitle)

		// Check files
		var files []models.DVRFile
		d.db.Where(
			"title = ? AND subtitle != '' AND deleted = ? AND completed = ?",
			job.Title, false, true,
		).Find(&files)
		for _, f := range files {
			if normalizeTitle(f.Title) == normalizedTitle &&
				normalizeTitle(f.Subtitle) == normalizedSubtitle {
				fileCopy := f
				return true, &DuplicateMatch{
					MatchedFile: &fileCopy,
					MatchType:   "title_subtitle",
				}
			}
		}

		// Check jobs
		var existingJob models.DVRJob
		err := d.db.Where(
			"user_id = ? AND title = ? AND subtitle = ? AND id != ? AND status IN ? AND accepted_duplicate = ?",
			userID, job.Title, job.Subtitle, job.ID,
			[]string{"scheduled", "recording", "completed"},
			false,
		).First(&existingJob).Error
		if err == nil {
			return true, &DuplicateMatch{
				MatchedJob: &existingJob,
				MatchType:  "title_subtitle",
			}
		}
	}

	// Strategy 4: Title + air date (within same calendar day)
	if !job.StartTime.IsZero() {
		airDate := job.StartTime.Truncate(24 * time.Hour)
		nextDay := airDate.Add(24 * time.Hour)

		// Check files by AiredAt date
		var file models.DVRFile
		err := d.db.Where(
			"title = ? AND aired_at >= ? AND aired_at < ? AND deleted = ? AND completed = ?",
			job.Title, airDate, nextDay, false, true,
		).First(&file).Error
		if err == nil {
			return true, &DuplicateMatch{
				MatchedFile: &file,
				MatchType:   "title_airdate",
			}
		}

		// Check jobs by StartTime date
		var existingJob models.DVRJob
		err = d.db.Where(
			"user_id = ? AND title = ? AND start_time >= ? AND start_time < ? AND id != ? AND status IN ? AND accepted_duplicate = ?",
			userID, job.Title, airDate, nextDay, job.ID,
			[]string{"scheduled", "recording", "completed"},
			false,
		).First(&existingJob).Error
		if err == nil {
			return true, &DuplicateMatch{
				MatchedJob: &existingJob,
				MatchType:  "title_airdate",
			}
		}
	}

	return false, nil
}

// FindDuplicates finds all files and jobs that match the given title.
// It returns slices of matching files and jobs, useful for the UI to
// show what would be considered duplicates of a given program.
func (d *DuplicateDetector) FindDuplicates(title string) ([]models.DVRFile, []models.DVRJob) {
	var files []models.DVRFile
	var jobs []models.DVRJob

	if title == "" {
		return files, jobs
	}

	normalized := normalizeTitle(title)

	// Find matching files
	var allFiles []models.DVRFile
	d.db.Where("deleted = ? AND completed = ?", false, true).Find(&allFiles)
	for _, f := range allFiles {
		if normalizeTitle(f.Title) == normalized {
			files = append(files, f)
		}
	}

	// Find matching jobs (scheduled, recording, or completed)
	var allJobs []models.DVRJob
	d.db.Where("status IN ?", []string{"scheduled", "recording", "completed"}).Find(&allJobs)
	for _, j := range allJobs {
		if normalizeTitle(j.Title) == normalized {
			jobs = append(jobs, j)
		}
	}

	return files, jobs
}

// GetDuplicatePolicy returns the duplicate policy for a given rule.
// Returns "skip" (default) or "record".
func (d *DuplicateDetector) GetDuplicatePolicy(ruleID uint) string {
	var rule models.DVRRule
	if err := d.db.First(&rule, ruleID).Error; err != nil {
		return "skip" // default to skip if rule not found
	}
	if rule.Duplicates == "" {
		return "skip"
	}
	return rule.Duplicates
}

// MarkAsAcceptedDuplicate overrides duplicate detection for a specific job,
// allowing it to proceed despite being flagged as a duplicate.
func (d *DuplicateDetector) MarkAsAcceptedDuplicate(jobID uint) error {
	var job models.DVRJob
	if err := d.db.First(&job, jobID).Error; err != nil {
		return err
	}

	job.AcceptedDuplicate = true
	// Reset the duplicate-skipped status so the scheduler can pick it up
	if job.Status == "cancelled" && job.IsDuplicate {
		job.Status = "scheduled"
	}

	if err := d.db.Save(&job).Error; err != nil {
		return err
	}

	logger.Log.WithFields(map[string]interface{}{
		"job_id": jobID,
		"title":  job.Title,
	}).Info("Duplicate override accepted for job")

	return nil
}

// GetDuplicateJobs returns all jobs that are marked as duplicates.
func (d *DuplicateDetector) GetDuplicateJobs() []models.DVRJob {
	var jobs []models.DVRJob
	d.db.Where("is_duplicate = ? AND accepted_duplicate = ?", true, false).
		Order("created_at DESC").
		Find(&jobs)
	return jobs
}

// GetDuplicateStats returns statistics about duplicate recordings.
type DuplicateStats struct {
	TotalDuplicatesFound   int64 `json:"totalDuplicatesFound"`
	DuplicatesSkipped      int64 `json:"duplicatesSkipped"`
	DuplicatesOverridden   int64 `json:"duplicatesOverridden"`
	PotentialSpaceSavedMB  int64 `json:"potentialSpaceSavedMB"`
	ByMatchType            map[string]int64 `json:"byMatchType"`
}

func (d *DuplicateDetector) GetDuplicateStats() DuplicateStats {
	stats := DuplicateStats{
		ByMatchType: make(map[string]int64),
	}

	// Count total duplicates found (all jobs ever flagged)
	d.db.Model(&models.DVRJob{}).Where("is_duplicate = ?", true).Count(&stats.TotalDuplicatesFound)

	// Count skipped (is_duplicate AND cancelled or still flagged)
	d.db.Model(&models.DVRJob{}).Where(
		"is_duplicate = ? AND accepted_duplicate = ?", true, false,
	).Count(&stats.DuplicatesSkipped)

	// Count overridden
	d.db.Model(&models.DVRJob{}).Where(
		"is_duplicate = ? AND accepted_duplicate = ?", true, true,
	).Count(&stats.DuplicatesOverridden)

	// Estimate potential space saved: average file size * duplicates skipped
	var avgSize struct{ Avg float64 }
	d.db.Model(&models.DVRFile{}).
		Where("deleted = ? AND completed = ?", false, true).
		Select("COALESCE(AVG(file_size), 0) as avg").
		Scan(&avgSize)
	stats.PotentialSpaceSavedMB = int64(avgSize.Avg * float64(stats.DuplicatesSkipped) / (1024 * 1024))

	return stats
}

// CheckProgramDuplicate checks whether a program (by its ID) would be
// a duplicate if scheduled. This is used by the API for pre-scheduling checks.
func (d *DuplicateDetector) CheckProgramDuplicate(programID uint, userID uint) (bool, *DuplicateMatch) {
	var prog models.Program
	if err := d.db.First(&prog, programID).Error; err != nil {
		return false, nil
	}

	// Build a synthetic job from the program
	syntheticJob := models.DVRJob{
		UserID:    userID,
		ProgramID: &programID,
		Title:     prog.Title,
		Subtitle:  prog.Subtitle,
		StartTime: prog.Start,
		EndTime:   prog.End,
		EpisodeNum: prog.EpisodeNum,
	}

	return d.IsDuplicate(syntheticJob)
}

// parseEpisodeNum extracts season and episode numbers from formats like
// "S01E05", "1x05", "s1e5", etc.
func parseEpisodeNum(episodeNum string) (season, episode int) {
	s := strings.ToUpper(strings.TrimSpace(episodeNum))

	// Try S01E05 format
	if idx := strings.Index(s, "S"); idx >= 0 {
		rest := s[idx+1:]
		if eIdx := strings.Index(rest, "E"); eIdx > 0 {
			seasonStr := rest[:eIdx]
			episodeStr := rest[eIdx+1:]
			season = parseInt(seasonStr)
			episode = parseInt(episodeStr)
			return
		}
	}

	// Try 1x05 format
	if xIdx := strings.Index(s, "X"); xIdx > 0 {
		seasonStr := s[:xIdx]
		episodeStr := s[xIdx+1:]
		season = parseInt(seasonStr)
		episode = parseInt(episodeStr)
		return
	}

	return 0, 0
}

// parseInt parses an integer from a string, returning 0 on failure.
func parseInt(s string) int {
	s = strings.TrimSpace(s)
	n := 0
	for _, c := range s {
		if c >= '0' && c <= '9' {
			n = n*10 + int(c-'0')
		} else {
			break
		}
	}
	return n
}

// normalizeTitle lowercases and trims whitespace for case-insensitive matching.
func normalizeTitle(title string) string {
	return strings.ToLower(strings.TrimSpace(title))
}
