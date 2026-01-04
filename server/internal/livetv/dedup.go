package livetv

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// DuplicateDetector detects and handles duplicate/conflicting EPG programs
type DuplicateDetector struct {
	db *gorm.DB
}

// NewDuplicateDetector creates a new duplicate detector
func NewDuplicateDetector(db *gorm.DB) *DuplicateDetector {
	return &DuplicateDetector{db: db}
}

// ConflictType represents the type of EPG conflict
type ConflictType string

const (
	ConflictTypeDuplicate  ConflictType = "duplicate"  // Exact same program
	ConflictTypeOverlap    ConflictType = "overlap"    // Programs overlap in time
	ConflictTypeGap        ConflictType = "gap"        // Gap between programs
	ConflictTypeIncomplete ConflictType = "incomplete" // Missing required fields
)

// EPGConflict represents a detected conflict
type EPGConflict struct {
	Type         ConflictType     `json:"type"`
	ChannelID    string           `json:"channelId"`
	Program1     *models.Program  `json:"program1,omitempty"`
	Program2     *models.Program  `json:"program2,omitempty"`
	Description  string           `json:"description"`
	ResolutionAction string       `json:"resolutionAction,omitempty"`
}

// ConflictReport contains all detected conflicts
type ConflictReport struct {
	TotalPrograms    int           `json:"totalPrograms"`
	DuplicatesFound  int           `json:"duplicatesFound"`
	OverlapsFound    int           `json:"overlapsFound"`
	GapsFound        int           `json:"gapsFound"`
	IncompleteFound  int           `json:"incompleteFound"`
	Conflicts        []EPGConflict `json:"conflicts"`
	AnalysisTime     time.Duration `json:"analysisTime"`
}

// DetectConflicts analyzes EPG data and returns a conflict report
func (d *DuplicateDetector) DetectConflicts(channelIDs []string) (*ConflictReport, error) {
	startTime := time.Now()
	report := &ConflictReport{
		Conflicts: make([]EPGConflict, 0),
	}

	// Get programs for analysis (future programs + 24h of past)
	pastCutoff := time.Now().Add(-24 * time.Hour)

	query := d.db.Model(&models.Program{}).Where("end > ?", pastCutoff)
	if len(channelIDs) > 0 {
		query = query.Where("channel_id IN ?", channelIDs)
	}

	var programs []models.Program
	if err := query.Order("channel_id, start").Find(&programs).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch programs: %w", err)
	}

	report.TotalPrograms = len(programs)

	// Group programs by channel
	programsByChannel := make(map[string][]models.Program)
	for _, prog := range programs {
		programsByChannel[prog.ChannelID] = append(programsByChannel[prog.ChannelID], prog)
	}

	// Analyze each channel
	for channelID, channelProgs := range programsByChannel {
		d.detectChannelConflicts(channelID, channelProgs, report)
	}

	// Detect duplicates across channels (same title/time on different channel IDs for same logical channel)
	d.detectCrossChannelDuplicates(programsByChannel, report)

	report.AnalysisTime = time.Since(startTime)
	return report, nil
}

// detectChannelConflicts detects conflicts within a single channel
func (d *DuplicateDetector) detectChannelConflicts(channelID string, programs []models.Program, report *ConflictReport) {
	seen := make(map[string]bool)

	for i := 0; i < len(programs); i++ {
		prog := programs[i]

		// Check for incomplete programs
		if prog.Title == "" {
			report.IncompleteFound++
			report.Conflicts = append(report.Conflicts, EPGConflict{
				Type:        ConflictTypeIncomplete,
				ChannelID:   channelID,
				Program1:    &prog,
				Description: "Program missing title",
			})
			continue
		}

		// Generate hash for duplicate detection
		hash := d.generateProgramHash(&prog)
		if seen[hash] {
			report.DuplicatesFound++
			report.Conflicts = append(report.Conflicts, EPGConflict{
				Type:        ConflictTypeDuplicate,
				ChannelID:   channelID,
				Program1:    &prog,
				Description: fmt.Sprintf("Duplicate program: %s at %s", prog.Title, prog.Start.Format(time.RFC3339)),
			})
			continue
		}
		seen[hash] = true

		// Check for overlaps with next program
		if i+1 < len(programs) {
			nextProg := programs[i+1]

			// Check for overlap
			if prog.End.After(nextProg.Start) {
				overlap := prog.End.Sub(nextProg.Start)
				report.OverlapsFound++
				report.Conflicts = append(report.Conflicts, EPGConflict{
					Type:        ConflictTypeOverlap,
					ChannelID:   channelID,
					Program1:    &prog,
					Program2:    &nextProg,
					Description: fmt.Sprintf("Programs overlap by %v: '%s' ends at %s but '%s' starts at %s",
						overlap, prog.Title, prog.End.Format("15:04"),
						nextProg.Title, nextProg.Start.Format("15:04")),
				})
			}

			// Check for gaps (> 1 minute)
			gap := nextProg.Start.Sub(prog.End)
			if gap > time.Minute {
				report.GapsFound++
				if gap > 30*time.Minute { // Only report significant gaps
					report.Conflicts = append(report.Conflicts, EPGConflict{
						Type:        ConflictTypeGap,
						ChannelID:   channelID,
						Program1:    &prog,
						Program2:    &nextProg,
						Description: fmt.Sprintf("Gap of %v between '%s' and '%s'",
							gap.Round(time.Minute), prog.Title, nextProg.Title),
					})
				}
			}
		}
	}
}

// detectCrossChannelDuplicates detects same program appearing on multiple channel IDs
func (d *DuplicateDetector) detectCrossChannelDuplicates(programsByChannel map[string][]models.Program, report *ConflictReport) {
	// Build a map of program signatures to detect cross-channel duplicates
	// This can happen when the same channel has multiple IDs in different sources
	signatures := make(map[string][]struct {
		channelID string
		program   *models.Program
	})

	for channelID, programs := range programsByChannel {
		for i := range programs {
			prog := &programs[i]
			// Use title + start time as signature (different from hash which includes channel)
			sig := fmt.Sprintf("%s|%d", prog.Title, prog.Start.Unix())
			signatures[sig] = append(signatures[sig], struct {
				channelID string
				program   *models.Program
			}{channelID, prog})
		}
	}

	// Find signatures that appear on multiple channels
	for sig, occurrences := range signatures {
		if len(occurrences) > 1 {
			// Check if these are on truly different channels (not just different IDs for same channel)
			channels := make(map[string]bool)
			for _, occ := range occurrences {
				channels[occ.channelID] = true
			}

			if len(channels) > 1 {
				logger.Log.Debugf("Cross-channel duplicate detected: %s on %d channels", sig, len(channels))
			}
		}
	}
}

// generateProgramHash creates a unique hash for a program
func (d *DuplicateDetector) generateProgramHash(prog *models.Program) string {
	data := fmt.Sprintf("%s|%s|%d|%d",
		prog.ChannelID,
		prog.Title,
		prog.Start.Unix(),
		prog.End.Unix())
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:8])
}

// ResolveDuplicates removes duplicate programs from the database
func (d *DuplicateDetector) ResolveDuplicates(dryRun bool) (*DuplicateResolutionResult, error) {
	result := &DuplicateResolutionResult{
		DryRun: dryRun,
	}

	// Find exact duplicates (same channel, title, start, end)
	var programs []models.Program
	if err := d.db.Order("channel_id, start, id").Find(&programs).Error; err != nil {
		return nil, err
	}

	seen := make(map[string]uint) // hash -> first program ID
	duplicateIDs := make([]uint, 0)

	for _, prog := range programs {
		hash := d.generateProgramHash(&prog)
		if existingID, exists := seen[hash]; exists {
			// This is a duplicate
			duplicateIDs = append(duplicateIDs, prog.ID)
			result.DuplicatesFound++
			logger.Log.Debugf("Found duplicate: %s (ID %d) is duplicate of ID %d",
				prog.Title, prog.ID, existingID)
		} else {
			seen[hash] = prog.ID
		}
	}

	result.DuplicateIDs = duplicateIDs

	// Delete duplicates if not dry run
	if !dryRun && len(duplicateIDs) > 0 {
		if err := d.db.Where("id IN ?", duplicateIDs).Delete(&models.Program{}).Error; err != nil {
			return nil, fmt.Errorf("failed to delete duplicates: %w", err)
		}
		result.Deleted = len(duplicateIDs)
		logger.Log.Infof("Deleted %d duplicate programs", result.Deleted)
	}

	return result, nil
}

// DuplicateResolutionResult contains the result of duplicate resolution
type DuplicateResolutionResult struct {
	DryRun          bool   `json:"dryRun"`
	DuplicatesFound int    `json:"duplicatesFound"`
	DuplicateIDs    []uint `json:"duplicateIds,omitempty"`
	Deleted         int    `json:"deleted"`
}

// ResolveOverlaps fixes overlapping programs by trimming the earlier program's end time
func (d *DuplicateDetector) ResolveOverlaps(channelIDs []string, dryRun bool) (*OverlapResolutionResult, error) {
	result := &OverlapResolutionResult{
		DryRun: dryRun,
	}

	query := d.db.Model(&models.Program{})
	if len(channelIDs) > 0 {
		query = query.Where("channel_id IN ?", channelIDs)
	}

	var programs []models.Program
	if err := query.Order("channel_id, start").Find(&programs).Error; err != nil {
		return nil, err
	}

	// Group by channel and find overlaps
	programsByChannel := make(map[string][]models.Program)
	for _, prog := range programs {
		programsByChannel[prog.ChannelID] = append(programsByChannel[prog.ChannelID], prog)
	}

	for channelID, channelProgs := range programsByChannel {
		for i := 0; i < len(channelProgs)-1; i++ {
			current := &channelProgs[i]
			next := &channelProgs[i+1]

			if current.End.After(next.Start) {
				result.OverlapsFound++

				if !dryRun {
					// Trim current program's end to next program's start
					current.End = next.Start
					if err := d.db.Save(current).Error; err != nil {
						logger.Log.Warnf("Failed to fix overlap for channel %s: %v", channelID, err)
						continue
					}
					result.Fixed++
				}
			}
		}
	}

	return result, nil
}

// OverlapResolutionResult contains the result of overlap resolution
type OverlapResolutionResult struct {
	DryRun        bool `json:"dryRun"`
	OverlapsFound int  `json:"overlapsFound"`
	Fixed         int  `json:"fixed"`
}

// CleanupOldPrograms removes programs that ended more than the specified hours ago
func (d *DuplicateDetector) CleanupOldPrograms(hoursOld int) (int64, error) {
	if hoursOld < 1 {
		hoursOld = 24 // Default to 24 hours
	}

	cutoff := time.Now().Add(-time.Duration(hoursOld) * time.Hour)

	result := d.db.Where("end < ?", cutoff).Delete(&models.Program{})
	if result.Error != nil {
		return 0, result.Error
	}

	if result.RowsAffected > 0 {
		logger.Log.Infof("Cleaned up %d old programs (ended before %v)", result.RowsAffected, cutoff)
	}

	return result.RowsAffected, nil
}
