package livetv

import (
	"time"

	dbutil "github.com/openflix/openflix-server/internal/db"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

const programUpsertBatchSize = 500

type ProgramUpsertResult struct {
	Imported int
	Updated  int
}

type ProgramCleanupOptions struct {
	ChannelIDs     []string
	DeleteBefore   *time.Time
	CheckpointMode string
}

type programIdentity struct {
	ChannelID string
	Start     time.Time
}

func UpsertPrograms(db *gorm.DB, programs []models.Program, opts ProgramCleanupOptions) (ProgramUpsertResult, error) {
	programs = dedupeIncomingPrograms(programs)
	result := ProgramUpsertResult{}

	if len(programs) == 0 {
		if len(opts.ChannelIDs) > 0 && opts.DeleteBefore != nil {
			if err := db.Where("channel_id IN ? AND start < ?", opts.ChannelIDs, *opts.DeleteBefore).
				Delete(&models.Program{}).Error; err != nil {
				return result, err
			}
			_ = dbutil.CheckpointSQLite(db, opts.CheckpointMode)
		}
		return result, nil
	}

	err := db.Transaction(func(tx *gorm.DB) error {
		if len(opts.ChannelIDs) > 0 && opts.DeleteBefore != nil {
			if err := tx.Where("channel_id IN ? AND start < ?", opts.ChannelIDs, *opts.DeleteBefore).
				Delete(&models.Program{}).Error; err != nil {
				return err
			}
		}

		existing, err := loadExistingProgramKeys(tx, programs)
		if err != nil {
			return err
		}

		for _, program := range programs {
			if _, ok := existing[makeProgramIdentity(program.ChannelID, program.Start)]; ok {
				result.Updated++
			} else {
				result.Imported++
			}
		}

		return tx.Clauses(clause.OnConflict{
			Columns: []clause.Column{
				{Name: "channel_id"},
				{Name: "start"},
			},
			DoUpdates: clause.AssignmentColumns([]string{
				"call_sign",
				"channel_no",
				"affiliate_name",
				"title",
				"subtitle",
				"description",
				"end",
				"icon",
				"art",
				"category",
				"episode_num",
				"season_number",
				"episode_number",
				"rating",
				"is_movie",
				"is_sports",
				"is_kids",
				"is_news",
				"is_new",
				"is_live",
				"is_premiere",
				"is_season_premiere",
				"is_series_premiere",
				"is_finale",
				"is_season_finale",
				"is_series_finale",
				"original_air_date",
				"teams",
				"league",
				"epg_source_id",
				"genres",
				"has_cc",
				"series_id",
				"program_id",
				"gracenote_id",
			}),
		}).CreateInBatches(programs, programUpsertBatchSize).Error
	})
	if err != nil {
		return result, err
	}

	_ = dbutil.CheckpointSQLite(db, opts.CheckpointMode)
	return result, nil
}

func loadExistingProgramKeys(db *gorm.DB, programs []models.Program) (map[programIdentity]struct{}, error) {
	channelSet := make(map[string]struct{}, len(programs))
	minStart := programs[0].Start
	maxStart := programs[0].Start
	for _, program := range programs {
		channelSet[program.ChannelID] = struct{}{}
		if program.Start.Before(minStart) {
			minStart = program.Start
		}
		if program.Start.After(maxStart) {
			maxStart = program.Start
		}
	}

	channelIDs := make([]string, 0, len(channelSet))
	for channelID := range channelSet {
		channelIDs = append(channelIDs, channelID)
	}

	var existingRows []struct {
		ChannelID string
		Start     time.Time
	}
	if err := db.Model(&models.Program{}).
		Select("channel_id", "start").
		Where("channel_id IN ? AND start >= ? AND start <= ?", channelIDs, minStart, maxStart).
		Find(&existingRows).Error; err != nil {
		return nil, err
	}

	existing := make(map[programIdentity]struct{}, len(existingRows))
	for _, row := range existingRows {
		existing[makeProgramIdentity(row.ChannelID, row.Start)] = struct{}{}
	}
	return existing, nil
}

func dedupeIncomingPrograms(programs []models.Program) []models.Program {
	indexByKey := make(map[programIdentity]int, len(programs))
	deduped := make([]models.Program, 0, len(programs))
	for _, program := range programs {
		key := makeProgramIdentity(program.ChannelID, program.Start)
		if idx, ok := indexByKey[key]; ok {
			deduped[idx] = program
			continue
		}
		indexByKey[key] = len(deduped)
		deduped = append(deduped, program)
	}
	return deduped
}

func makeProgramIdentity(channelID string, start time.Time) programIdentity {
	return programIdentity{
		ChannelID: channelID,
		Start:     start.UTC(),
	}
}
