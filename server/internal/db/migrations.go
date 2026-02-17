package db

import (
	"fmt"
	"log"
	"time"

	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// MigrateRecordingsToDVR migrates legacy Recording rows into DVRJob + DVRFile.
// This is idempotent — it skips recordings that have already been migrated.
func MigrateRecordingsToDVR(db *gorm.DB) error {
	// Check if the recordings table exists
	if !db.Migrator().HasTable(&models.Recording{}) {
		log.Println("DVR migration: no recordings table found, skipping")
		return nil
	}

	// Check if there are any recordings to migrate
	var totalRecordings int64
	db.Model(&models.Recording{}).Count(&totalRecordings)
	if totalRecordings == 0 {
		log.Println("DVR migration: no recordings to migrate")
		return nil
	}

	// Check how many have already been migrated (have a matching DVRJob with LegacyRecordingID)
	var alreadyMigrated int64
	db.Model(&models.DVRJob{}).Where("legacy_recording_id IS NOT NULL").Count(&alreadyMigrated)
	if alreadyMigrated >= totalRecordings {
		log.Printf("DVR migration: all %d recordings already migrated, skipping", totalRecordings)
		return nil
	}

	log.Printf("DVR migration: migrating %d recordings (%d already done)", totalRecordings, alreadyMigrated)

	// Get all recordings that haven't been migrated yet
	var recordings []models.Recording
	subQuery := db.Model(&models.DVRJob{}).Select("legacy_recording_id").Where("legacy_recording_id IS NOT NULL")
	if err := db.Where("id NOT IN (?)", subQuery).Find(&recordings).Error; err != nil {
		return fmt.Errorf("failed to fetch recordings: %w", err)
	}

	if len(recordings) == 0 {
		log.Println("DVR migration: no new recordings to migrate")
		return nil
	}

	migrated := 0
	errors := 0

	for _, rec := range recordings {
		if err := migrateOneRecording(db, rec); err != nil {
			log.Printf("DVR migration: failed to migrate recording %d: %v", rec.ID, err)
			errors++
		} else {
			migrated++
		}
	}

	// Migrate CommercialSegments to link to DVRFiles
	migrateCommercialSegments(db)

	// Migrate RecordingWatchProgress to FileState
	migrateWatchProgress(db)

	// Migrate SeriesRules to DVRRules
	migrateSeriesRules(db)

	// Migrate TeamPasses to DVRRules
	migrateTeamPasses(db)

	log.Printf("DVR migration complete: %d migrated, %d errors", migrated, errors)
	return nil
}

func migrateOneRecording(db *gorm.DB, rec models.Recording) error {
	return db.Transaction(func(tx *gorm.DB) error {
		legacyID := rec.ID

		// For completed recordings, create both a DVRFile and a DVRJob
		if rec.Status == "completed" {
			// Create DVRFile
			now := time.Now()
			dvrFile := models.DVRFile{
				Title:             rec.Title,
				Subtitle:          rec.Subtitle,
				Description:       rec.Description,
				Summary:           rec.Summary,
				FilePath:          rec.FilePath,
				FileSize:          rec.FileSize,
				Completed:         true,
				Processed:         true,
				Thumb:             rec.Thumb,
				Art:               rec.Art,
				SeasonNumber:      rec.SeasonNumber,
				EpisodeNumber:     rec.EpisodeNumber,
				EpisodeNum:        rec.EpisodeNum,
				Genres:            rec.Genres,
				ContentRating:     rec.ContentRating,
				Year:              rec.Year,
				OriginalAirDate:   rec.OriginalAirDate,
				TMDBId:            rec.TMDBId,
				IsMovie:           rec.IsMovie,
				Rating:            rec.Rating,
				ChannelName:       rec.ChannelName,
				ChannelLogo:       rec.ChannelLogo,
				Category:          rec.Category,
				AiredAt:           &rec.StartTime,
				RecordedAt:        &now,
				LegacyRecordingID: &legacyID,
				CreatedAt:         rec.CreatedAt,
				UpdatedAt:         rec.UpdatedAt,
			}
			if rec.Duration != nil {
				dvrFile.Duration = *rec.Duration * 60 // Convert minutes to seconds
			}

			if err := tx.Create(&dvrFile).Error; err != nil {
				return fmt.Errorf("create file: %w", err)
			}

			// Create DVRJob pointing to the file
			fileID := dvrFile.ID
			dvrJob := models.DVRJob{
				UserID:            rec.UserID,
				ChannelID:         rec.ChannelID,
				ProgramID:         rec.ProgramID,
				Title:             rec.Title,
				Subtitle:          rec.Subtitle,
				Description:       rec.Description,
				StartTime:         rec.StartTime,
				EndTime:           rec.EndTime,
				Status:            "completed",
				Priority:          rec.Priority,
				QualityPreset:     rec.QualityPreset,
				TargetBitrate:     rec.TargetBitrate,
				RetryCount:        rec.RetryCount,
				MaxRetries:        rec.MaxRetries,
				LastError:         rec.LastError,
				ChannelName:       rec.ChannelName,
				ChannelLogo:       rec.ChannelLogo,
				Category:          rec.Category,
				EpisodeNum:        rec.EpisodeNum,
				IsMovie:           rec.IsMovie,
				SeriesRecord:      rec.SeriesRecord,
				SeriesParentID:    rec.SeriesParentID,
				ConflictGroupID:   rec.ConflictGroupID,
				FileID:            &fileID,
				LegacyRecordingID: &legacyID,
				CreatedAt:         rec.CreatedAt,
				UpdatedAt:         rec.UpdatedAt,
			}
			if rec.SeriesRuleID != nil {
				// We'll link to DVRRule later after SeriesRule migration
				dvrJob.RuleID = nil
			}

			if err := tx.Create(&dvrJob).Error; err != nil {
				return fmt.Errorf("create job: %w", err)
			}

			return nil
		}

		// For non-completed recordings (scheduled, recording, failed, cancelled)
		dvrJob := models.DVRJob{
			UserID:            rec.UserID,
			ChannelID:         rec.ChannelID,
			ProgramID:         rec.ProgramID,
			Title:             rec.Title,
			Subtitle:          rec.Subtitle,
			Description:       rec.Description,
			StartTime:         rec.StartTime,
			EndTime:           rec.EndTime,
			Status:            rec.Status,
			Priority:          rec.Priority,
			QualityPreset:     rec.QualityPreset,
			TargetBitrate:     rec.TargetBitrate,
			RetryCount:        rec.RetryCount,
			MaxRetries:        rec.MaxRetries,
			LastError:         rec.LastError,
			ChannelName:       rec.ChannelName,
			ChannelLogo:       rec.ChannelLogo,
			Category:          rec.Category,
			EpisodeNum:        rec.EpisodeNum,
			IsMovie:           rec.IsMovie,
			SeriesRecord:      rec.SeriesRecord,
			SeriesParentID:    rec.SeriesParentID,
			ConflictGroupID:   rec.ConflictGroupID,
			LegacyRecordingID: &legacyID,
			CreatedAt:         rec.CreatedAt,
			UpdatedAt:         rec.UpdatedAt,
		}

		if err := tx.Create(&dvrJob).Error; err != nil {
			return fmt.Errorf("create job: %w", err)
		}

		return nil
	})
}

// migrateCommercialSegments links existing CommercialSegments to DVRFiles
func migrateCommercialSegments(db *gorm.DB) {
	// Find all commercial segments that have a RecordingID but no FileID
	var segments []models.CommercialSegment
	db.Where("file_id IS NULL AND recording_id > 0").Find(&segments)

	if len(segments) == 0 {
		return
	}

	updated := 0
	for _, seg := range segments {
		// Find the DVRFile that was migrated from this recording
		var file models.DVRFile
		if err := db.Where("legacy_recording_id = ?", seg.RecordingID).First(&file).Error; err != nil {
			continue
		}
		fileID := file.ID
		db.Model(&seg).Update("file_id", &fileID)
		updated++
	}

	log.Printf("DVR migration: linked %d/%d commercial segments to DVR files", updated, len(segments))
}

// migrateWatchProgress migrates RecordingWatchProgress to FileState
func migrateWatchProgress(db *gorm.DB) {
	// Check if any FileState entries already exist
	var existingCount int64
	db.Model(&models.FileState{}).Count(&existingCount)
	if existingCount > 0 {
		return // Already migrated
	}

	var progresses []models.RecordingWatchProgress
	db.Find(&progresses)
	if len(progresses) == 0 {
		return
	}

	migrated := 0
	for _, wp := range progresses {
		// Find the DVRFile for this recording
		var file models.DVRFile
		if err := db.Where("legacy_recording_id = ?", wp.RecordingID).First(&file).Error; err != nil {
			continue
		}

		// Find a profile for this user (use first profile or create default mapping)
		var profile models.UserProfile
		if err := db.Where("user_id = ?", wp.UserID).First(&profile).Error; err != nil {
			continue
		}

		fileState := models.FileState{
			ProfileID:    profile.ID,
			FileID:       file.ID,
			Watched:      false,
			PlaybackTime: wp.ViewOffset,
			UpdatedAt:    wp.UpdatedAt,
		}

		if err := db.Create(&fileState).Error; err != nil {
			continue
		}
		migrated++
	}

	log.Printf("DVR migration: migrated %d/%d watch progress entries to FileState", migrated, len(progresses))
}

// migrateSeriesRules converts legacy SeriesRules to DVRRules with Query DSL
func migrateSeriesRules(db *gorm.DB) {
	// Check if already migrated
	var existingCount int64
	db.Model(&models.DVRRule{}).Where("legacy_series_rule_id IS NOT NULL").Count(&existingCount)

	var totalRules int64
	db.Model(&models.SeriesRule{}).Count(&totalRules)
	if totalRules == 0 || existingCount >= totalRules {
		return
	}

	var rules []models.SeriesRule
	subQuery := db.Model(&models.DVRRule{}).Select("legacy_series_rule_id").Where("legacy_series_rule_id IS NOT NULL")
	db.Where("id NOT IN (?)", subQuery).Find(&rules)

	migrated := 0
	for _, sr := range rules {
		legacyID := sr.ID

		// Build Query DSL from SeriesRule fields
		query := `[{"field":"title","op":"LIKE","value":"` + escapeJSON(sr.Title) + `"}`
		if sr.Keywords != "" {
			query += `,{"field":"title","op":"LIKE","value":"` + escapeJSON(sr.Keywords) + `"}`
		}
		if sr.ChannelID != nil {
			query += fmt.Sprintf(`,{"field":"channel","op":"EQ","value":"%d"}`, *sr.ChannelID)
		}
		if sr.TimeSlot != "" {
			query += `,{"field":"timeSlot","op":"EQ","value":"` + sr.TimeSlot + `"}`
		}
		if sr.DaysOfWeek != "" {
			query += `,{"field":"dayOfWeek","op":"IN","value":"` + sr.DaysOfWeek + `"}`
		}
		query += `]`

		dvrRule := models.DVRRule{
			UserID:             sr.UserID,
			Name:               sr.Title,
			Query:              query,
			KeepNum:            sr.KeepCount,
			PaddingStart:       sr.PrePadding * 60,  // minutes to seconds
			PaddingEnd:         sr.PostPadding * 60,
			Enabled:            sr.Enabled,
			LegacySeriesRuleID: &legacyID,
			CreatedAt:          sr.CreatedAt,
			UpdatedAt:          sr.UpdatedAt,
		}

		if err := db.Create(&dvrRule).Error; err != nil {
			log.Printf("DVR migration: failed to migrate series rule %d: %v", sr.ID, err)
			continue
		}

		// Update any DVRJobs that referenced this SeriesRule
		db.Model(&models.DVRJob{}).
			Where("legacy_recording_id IN (SELECT id FROM recordings WHERE series_rule_id = ?)", sr.ID).
			Update("rule_id", dvrRule.ID)

		migrated++
	}

	log.Printf("DVR migration: migrated %d series rules to DVR rules", migrated)
}

// migrateTeamPasses converts legacy TeamPasses to DVRRules with Query DSL
func migrateTeamPasses(db *gorm.DB) {
	// Check if already migrated
	var existingCount int64
	db.Model(&models.DVRRule{}).Where("legacy_team_pass_id IS NOT NULL").Count(&existingCount)

	var totalPasses int64
	db.Model(&models.TeamPass{}).Count(&totalPasses)
	if totalPasses == 0 || existingCount >= totalPasses {
		return
	}

	var passes []models.TeamPass
	subQuery := db.Model(&models.DVRRule{}).Select("legacy_team_pass_id").Where("legacy_team_pass_id IS NOT NULL")
	db.Where("id NOT IN (?)", subQuery).Find(&passes)

	migrated := 0
	for _, tp := range passes {
		legacyID := tp.ID

		// Build Query DSL: isSports=true + team matches
		teamValue := tp.TeamName
		if tp.TeamAliases != "" {
			teamValue += "," + tp.TeamAliases
		}

		query := `[{"field":"isSports","op":"EQ","value":"true"}`
		query += `,{"field":"team","op":"IN","value":"` + escapeJSON(teamValue) + `"}`
		if tp.League != "" {
			query += `,{"field":"league","op":"EQ","value":"` + escapeJSON(tp.League) + `"}`
		}
		if tp.ChannelIDs != "" {
			query += `,{"field":"channel","op":"IN","value":"` + tp.ChannelIDs + `"}`
		}
		query += `]`

		dvrRule := models.DVRRule{
			UserID:           tp.UserID,
			Name:             tp.TeamName + " (" + tp.League + ")",
			Query:            query,
			KeepNum:          tp.KeepCount,
			PaddingStart:     tp.PrePadding * 60,
			PaddingEnd:       tp.PostPadding * 60,
			Priority:         tp.Priority,
			Enabled:          tp.Enabled,
			LegacyTeamPassID: &legacyID,
			CreatedAt:        tp.CreatedAt,
			UpdatedAt:        tp.UpdatedAt,
		}

		if err := db.Create(&dvrRule).Error; err != nil {
			log.Printf("DVR migration: failed to migrate team pass %d: %v", tp.ID, err)
			continue
		}
		migrated++
	}

	log.Printf("DVR migration: migrated %d team passes to DVR rules", migrated)
}

// escapeJSON escapes special characters for JSON string values
func escapeJSON(s string) string {
	result := ""
	for _, c := range s {
		switch c {
		case '"':
			result += `\"`
		case '\\':
			result += `\\`
		case '\n':
			result += `\n`
		case '\r':
			result += `\r`
		case '\t':
			result += `\t`
		default:
			result += string(c)
		}
	}
	return result
}
