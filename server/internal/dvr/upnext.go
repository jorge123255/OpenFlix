package dvr

import (
	"github.com/openflix/openflix-server/internal/models"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

// UpNextManager handles GroupState maintenance and UpNext calculation
type UpNextManager struct {
	db     *gorm.DB
	logger *logrus.Entry
}

// NewUpNextManager creates a new UpNext manager
func NewUpNextManager(db *gorm.DB) *UpNextManager {
	return &UpNextManager{
		db:     db,
		logger: logrus.WithField("component", "dvr-upnext"),
	}
}

// UpdateGroupStateForFile updates GroupState entries when a file's watch state changes.
// Called after FileState is created/updated.
func (u *UpNextManager) UpdateGroupStateForFile(profileID, fileID uint) {
	// Find the file's group
	var file models.DVRFile
	if err := u.db.Select("id, group_id").First(&file, fileID).Error; err != nil || file.GroupID == nil {
		return
	}

	u.RecalculateGroupState(profileID, *file.GroupID)
}

// RecalculateGroupState recalculates the GroupState for a specific profile + group
func (u *UpNextManager) RecalculateGroupState(profileID, groupID uint) {
	// Count total non-deleted files in group
	var totalFiles int64
	u.db.Model(&models.DVRFile{}).Where("group_id = ? AND deleted = ?", groupID, false).Count(&totalFiles)

	// Count watched files for this profile
	var watchedCount int64
	u.db.Model(&models.FileState{}).
		Joins("JOIN dvr_files ON dvr_files.id = file_states.file_id").
		Where("file_states.profile_id = ? AND dvr_files.group_id = ? AND dvr_files.deleted = ? AND file_states.watched = ?",
			profileID, groupID, false, true).
		Count(&watchedCount)

	numUnwatched := int(totalFiles) - int(watchedCount)
	if numUnwatched < 0 {
		numUnwatched = 0
	}

	// Find the up-next file (first unwatched, ordered by season/episode/created_at)
	var upNextFileID *uint
	var nextFile models.DVRFile
	err := u.db.Where("group_id = ? AND deleted = ?", groupID, false).
		Where("id NOT IN (?)",
			u.db.Model(&models.FileState{}).
				Select("file_id").
				Where("profile_id = ? AND watched = ?", profileID, true),
		).
		Order("COALESCE(season_number, 0), COALESCE(episode_number, 0), created_at ASC").
		First(&nextFile).Error
	if err == nil {
		upNextFileID = &nextFile.ID
	}

	// Upsert GroupState
	var state models.GroupState
	err = u.db.Where("profile_id = ? AND group_id = ?", profileID, groupID).First(&state).Error
	if err != nil {
		// Create new
		state = models.GroupState{
			ProfileID:    profileID,
			GroupID:      groupID,
			NumUnwatched: numUnwatched,
			UpNextFileID: upNextFileID,
		}
		u.db.Create(&state)
	} else {
		// Update existing
		u.db.Model(&state).Updates(map[string]interface{}{
			"num_unwatched":   numUnwatched,
			"up_next_file_id": upNextFileID,
		})
	}
}

// RecalculateAllGroupStates recalculates GroupState for all profiles across all groups.
// Called periodically for maintenance.
func (u *UpNextManager) RecalculateAllGroupStates() {
	var profiles []models.UserProfile
	u.db.Find(&profiles)

	var groups []models.DVRGroup
	u.db.Find(&groups)

	for _, p := range profiles {
		for _, g := range groups {
			u.RecalculateGroupState(p.ID, g.ID)
		}
	}

	u.logger.WithFields(logrus.Fields{
		"profiles": len(profiles),
		"groups":   len(groups),
	}).Debug("Recalculated all group states")
}

// InitializeFileStateForProfiles creates default FileState entries for a new file
// across all existing profiles (unwatched, position 0).
func (u *UpNextManager) InitializeFileStateForProfiles(fileID uint) {
	var profiles []models.UserProfile
	u.db.Find(&profiles)

	for _, p := range profiles {
		// Only create if doesn't exist
		var count int64
		u.db.Model(&models.FileState{}).Where("profile_id = ? AND file_id = ?", p.ID, fileID).Count(&count)
		if count == 0 {
			u.db.Create(&models.FileState{
				ProfileID:    p.ID,
				FileID:       fileID,
				Watched:      false,
				PlaybackTime: 0,
			})
		}
	}
}

// InitializeGroupStateForProfiles creates/updates GroupState entries for a group
// across all existing profiles.
func (u *UpNextManager) InitializeGroupStateForProfiles(groupID uint) {
	var profiles []models.UserProfile
	u.db.Find(&profiles)

	for _, p := range profiles {
		u.RecalculateGroupState(p.ID, groupID)
	}
}
