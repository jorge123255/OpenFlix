package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// ============ DVR V2: Jobs ============

// getJobs lists DVR jobs with filter and pagination support
func (s *Server) getJobs(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")

	var query *gorm.DB
	if isAdmin {
		query = s.db.Model(&models.DVRJob{})
	} else {
		query = s.db.Model(&models.DVRJob{}).Where("user_id = ?", userID)
	}

	// Filter by status
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	// Search by title
	if search := c.Query("search"); search != "" {
		query = query.Where("title LIKE ? OR description LIKE ?", "%"+search+"%", "%"+search+"%")
	}

	// Filter by date range
	if after := c.Query("after"); after != "" {
		if t, err := time.Parse(time.RFC3339, after); err == nil {
			query = query.Where("start_time >= ?", t)
		}
	}
	if before := c.Query("before"); before != "" {
		if t, err := time.Parse(time.RFC3339, before); err == nil {
			query = query.Where("start_time <= ?", t)
		}
	}

	// Filter by channel
	if channelID := c.Query("channelId"); channelID != "" {
		if id, err := strconv.ParseUint(channelID, 10, 32); err == nil {
			query = query.Where("channel_id = ?", id)
		}
	}

	// Filter by rule
	if ruleID := c.Query("ruleId"); ruleID != "" {
		if id, err := strconv.ParseUint(ruleID, 10, 32); err == nil {
			query = query.Where("rule_id = ?", id)
		}
	}

	// Get total count before pagination
	var totalCount int64
	countQuery := *query
	countQuery.Count(&totalCount)

	// Pagination
	page := 1
	pageSize := 0
	if ps := c.Query("pageSize"); ps != "" {
		if v, err := strconv.Atoi(ps); err == nil && v > 0 {
			pageSize = v
		}
	}
	if p := c.Query("page"); p != "" {
		if v, err := strconv.Atoi(p); err == nil && v > 0 {
			page = v
		}
	}
	if pageSize > 0 {
		offset := (page - 1) * pageSize
		query = query.Offset(offset).Limit(pageSize)
	}

	var jobs []models.DVRJob
	if err := query.Order("start_time DESC").Find(&jobs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch jobs"})
		return
	}

	result := gin.H{"jobs": jobs, "totalCount": totalCount}
	if pageSize > 0 {
		result["page"] = page
		result["pageSize"] = pageSize
		result["totalPages"] = (totalCount + int64(pageSize) - 1) / int64(pageSize)
	}

	c.JSON(http.StatusOK, result)
}

// getJob returns a single DVR job by ID
func (s *Server) getJob(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	var job models.DVRJob
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id = ?", userID)
	}
	if err := query.First(&job).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}

	c.JSON(http.StatusOK, job)
}

// createJob creates a new DVR job from channel+time or from a program
func (s *Server) createJob(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		ChannelID     uint       `json:"channelId" binding:"required"`
		ProgramID     *uint      `json:"programId"`
		RuleID        *uint      `json:"ruleId"`
		Title         string     `json:"title"`
		Subtitle      string     `json:"subtitle"`
		Description   string     `json:"description"`
		StartTime     *time.Time `json:"startTime"`
		EndTime       *time.Time `json:"endTime"`
		Category      string     `json:"category"`
		EpisodeNum    string     `json:"episodeNum"`
		Priority      *int       `json:"priority"`
		QualityPreset string     `json:"qualityPreset"`
		PaddingStart  int        `json:"paddingStart"`
		PaddingEnd    int        `json:"paddingEnd"`
		SeriesRecord  bool       `json:"seriesRecord"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate channel exists
	var channel models.Channel
	if err := s.db.First(&channel, req.ChannelID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Channel not found"})
		return
	}

	// If programId is provided, populate from program
	var startTime, endTime time.Time
	title := req.Title
	subtitle := req.Subtitle
	description := req.Description
	category := req.Category
	episodeNum := req.EpisodeNum
	isMovie := false
	isSports := false

	if req.ProgramID != nil {
		var program models.Program
		if err := s.db.First(&program, *req.ProgramID).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Program not found"})
			return
		}
		startTime = program.Start
		endTime = program.End
		if title == "" {
			title = program.Title
		}
		if subtitle == "" {
			subtitle = program.Subtitle
		}
		if description == "" {
			description = program.Description
		}
		if category == "" {
			category = program.Category
		}
		if episodeNum == "" {
			episodeNum = program.EpisodeNum
		}
		isMovie = program.IsMovie
		isSports = program.IsSports
	} else {
		// Manual channel+time
		if req.StartTime == nil || req.EndTime == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "startTime and endTime are required when programId is not provided"})
			return
		}
		if title == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "title is required when programId is not provided"})
			return
		}
		startTime = *req.StartTime
		endTime = *req.EndTime
	}

	// Set priority (default 50)
	priority := 50
	if req.Priority != nil {
		if *req.Priority < 0 || *req.Priority > 100 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Priority must be between 0 and 100"})
			return
		}
		priority = *req.Priority
	}

	qualityPreset := req.QualityPreset
	if qualityPreset == "" {
		qualityPreset = s.config.DVR.DefaultQuality
		if qualityPreset == "" {
			qualityPreset = "original"
		}
	}

	job := models.DVRJob{
		UserID:        userID,
		ChannelID:     req.ChannelID,
		ProgramID:     req.ProgramID,
		RuleID:        req.RuleID,
		Title:         title,
		Subtitle:      subtitle,
		Description:   description,
		StartTime:     startTime,
		EndTime:       endTime,
		Status:        "scheduled",
		Priority:      priority,
		QualityPreset: qualityPreset,
		PaddingStart:  req.PaddingStart,
		PaddingEnd:    req.PaddingEnd,
		Category:      category,
		EpisodeNum:    episodeNum,
		IsMovie:       isMovie,
		IsSports:      isSports,
		ChannelName:   channel.Name,
		ChannelLogo:   channel.Logo,
		SeriesRecord:  req.SeriesRecord,
		MaxRetries:    3,
	}

	if err := s.db.Create(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create job"})
		return
	}

	c.JSON(http.StatusCreated, job)
}

// updateJob updates an existing DVR job
func (s *Server) updateJob(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	var job models.DVRJob
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id = ?", userID)
	}
	if err := query.First(&job).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}

	var req struct {
		Title         *string    `json:"title"`
		Subtitle      *string    `json:"subtitle"`
		Description   *string    `json:"description"`
		StartTime     *time.Time `json:"startTime"`
		EndTime       *time.Time `json:"endTime"`
		Priority      *int       `json:"priority"`
		QualityPreset *string    `json:"qualityPreset"`
		PaddingStart  *int       `json:"paddingStart"`
		PaddingEnd    *int       `json:"paddingEnd"`
		Category      *string    `json:"category"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Title != nil {
		job.Title = *req.Title
	}
	if req.Subtitle != nil {
		job.Subtitle = *req.Subtitle
	}
	if req.Description != nil {
		job.Description = *req.Description
	}
	if req.StartTime != nil {
		job.StartTime = *req.StartTime
	}
	if req.EndTime != nil {
		job.EndTime = *req.EndTime
	}
	if req.Priority != nil {
		if *req.Priority < 0 || *req.Priority > 100 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Priority must be between 0 and 100"})
			return
		}
		job.Priority = *req.Priority
	}
	if req.QualityPreset != nil {
		job.QualityPreset = *req.QualityPreset
	}
	if req.PaddingStart != nil {
		job.PaddingStart = *req.PaddingStart
	}
	if req.PaddingEnd != nil {
		job.PaddingEnd = *req.PaddingEnd
	}
	if req.Category != nil {
		job.Category = *req.Category
	}

	if err := s.db.Save(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update job"})
		return
	}

	c.JSON(http.StatusOK, job)
}

// deleteJob deletes a DVR job
func (s *Server) deleteJob(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	var job models.DVRJob
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id = ?", userID)
	}
	if err := query.First(&job).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}

	if job.Status == "recording" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot delete a job that is currently recording. Cancel it first."})
		return
	}

	if err := s.db.Delete(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete job"})
		return
	}

	s.publishDVREvent(dvr.DVREvent{Type: dvr.EventJobDeleted, JobID: job.ID, Title: job.Title})
	c.JSON(http.StatusOK, gin.H{"message": "Job deleted"})
}

// cancelJob cancels a scheduled or recording DVR job
func (s *Server) cancelJob(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	var job models.DVRJob
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id = ?", userID)
	}
	if err := query.First(&job).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}

	if job.Status != "scheduled" && job.Status != "recording" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Can only cancel scheduled or recording jobs"})
		return
	}

	job.Status = "cancelled"
	job.Cancelled = true
	if err := s.db.Save(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to cancel job"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Job cancelled", "job": job})
}

// ============ DVR V2: Files ============

// getFiles lists completed DVR files with search, filter, date range, and pagination
func (s *Server) getFiles(c *gin.Context) {
	query := s.db.Model(&models.DVRFile{}).Where("deleted = ?", false)

	// Search by title or description
	if search := c.Query("search"); search != "" {
		query = query.Where("title LIKE ? OR description LIKE ? OR subtitle LIKE ?", "%"+search+"%", "%"+search+"%", "%"+search+"%")
	}

	// Filter by completed/processed status
	if status := c.Query("status"); status != "" {
		switch status {
		case "completed":
			query = query.Where("completed = ?", true)
		case "processing":
			query = query.Where("processed = ? AND completed = ?", false, true)
		case "processed":
			query = query.Where("processed = ?", true)
		}
	}

	// Filter by group
	if groupID := c.Query("groupId"); groupID != "" {
		if id, err := strconv.ParseUint(groupID, 10, 32); err == nil {
			query = query.Where("group_id = ?", id)
		}
	}

	// Filter by category
	if category := c.Query("category"); category != "" {
		query = query.Where("category = ?", category)
	}

	// Filter by movie/tv
	if c.Query("moviesOnly") == "true" {
		query = query.Where("is_movie = ?", true)
	}
	if c.Query("tvOnly") == "true" {
		query = query.Where("is_movie = ?", false)
	}

	// Date range on recorded_at
	if after := c.Query("after"); after != "" {
		if t, err := time.Parse(time.RFC3339, after); err == nil {
			query = query.Where("recorded_at >= ?", t)
		}
	}
	if before := c.Query("before"); before != "" {
		if t, err := time.Parse(time.RFC3339, before); err == nil {
			query = query.Where("recorded_at <= ?", t)
		}
	}

	// Get total count before pagination
	var totalCount int64
	countQuery := *query
	countQuery.Count(&totalCount)

	// Pagination
	page := 1
	pageSize := 0
	if ps := c.Query("pageSize"); ps != "" {
		if v, err := strconv.Atoi(ps); err == nil && v > 0 {
			pageSize = v
		}
	}
	if p := c.Query("page"); p != "" {
		if v, err := strconv.Atoi(p); err == nil && v > 0 {
			page = v
		}
	}
	if pageSize > 0 {
		offset := (page - 1) * pageSize
		query = query.Offset(offset).Limit(pageSize)
	}

	var files []models.DVRFile
	if err := query.Preload("Commercials").Order("created_at DESC").Find(&files).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch files"})
		return
	}

	result := gin.H{"files": files, "totalCount": totalCount}
	if pageSize > 0 {
		result["page"] = page
		result["pageSize"] = pageSize
		result["totalPages"] = (totalCount + int64(pageSize) - 1) / int64(pageSize)
	}

	c.JSON(http.StatusOK, result)
}

// getFile returns a single DVR file by ID
func (s *Server) getFile(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var file models.DVRFile
	if err := s.db.Preload("Commercials").Preload("DetectedSegments").First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	c.JSON(http.StatusOK, file)
}

// updateFile updates a DVR file's metadata
func (s *Server) updateFile(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var file models.DVRFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	var req struct {
		Title         *string `json:"title"`
		Subtitle      *string `json:"subtitle"`
		Description   *string `json:"description"`
		Summary       *string `json:"summary"`
		Category      *string `json:"category"`
		Genres        *string `json:"genres"`
		ContentRating *string `json:"contentRating"`
		Labels        *string `json:"labels"`
		Thumb         *string `json:"thumb"`
		Art           *string `json:"art"`
		GroupID       *uint   `json:"groupId"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Title != nil {
		file.Title = *req.Title
	}
	if req.Subtitle != nil {
		file.Subtitle = *req.Subtitle
	}
	if req.Description != nil {
		file.Description = *req.Description
	}
	if req.Summary != nil {
		file.Summary = *req.Summary
	}
	if req.Category != nil {
		file.Category = *req.Category
	}
	if req.Genres != nil {
		file.Genres = *req.Genres
	}
	if req.ContentRating != nil {
		file.ContentRating = *req.ContentRating
	}
	if req.Labels != nil {
		file.Labels = *req.Labels
	}
	if req.Thumb != nil {
		file.Thumb = *req.Thumb
	}
	if req.Art != nil {
		file.Art = *req.Art
	}
	if req.GroupID != nil {
		file.GroupID = req.GroupID
	}

	if err := s.db.Save(&file).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update file"})
		return
	}

	c.JSON(http.StatusOK, file)
}

// deleteFile soft-deletes a DVR file (marks deleted=true)
func (s *Server) deleteFile(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var file models.DVRFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	// Soft delete: mark as deleted
	file.Deleted = true
	if err := s.db.Save(&file).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete file"})
		return
	}

	// Also delete the physical file if it exists
	if file.FilePath != "" {
		if _, statErr := os.Stat(file.FilePath); statErr == nil {
			os.Remove(file.FilePath)
		}
	}

	// Update group file count
	if file.GroupID != nil {
		s.updateGroupFileCount(*file.GroupID)
	}

	s.publishDVREvent(dvr.DVREvent{Type: dvr.EventFileDeleted, FileID: file.ID, Title: file.Title})
	c.JSON(http.StatusOK, gin.H{"message": "File deleted"})
}

// streamFile serves the physical file for a DVR file record
func (s *Server) streamFile(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var file models.DVRFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	if file.Deleted {
		c.JSON(http.StatusGone, gin.H{"error": "File has been deleted"})
		return
	}

	if file.FilePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "No file path available"})
		return
	}

	if _, statErr := os.Stat(file.FilePath); os.IsNotExist(statErr) {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found on disk"})
		return
	}

	c.File(file.FilePath)
}

// ============ DVR V2: Groups ============

// getGroups lists DVR groups with file counts and unwatched counts
func (s *Server) getGroups(c *gin.Context) {
	profileID := c.GetUint("profileID")

	var groups []models.DVRGroup
	if err := s.db.Order("title ASC").Find(&groups).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch groups"})
		return
	}

	type GroupResponse struct {
		models.DVRGroup
		UnwatchedCount int `json:"unwatchedCount"`
	}

	responses := make([]GroupResponse, 0, len(groups))
	for _, g := range groups {
		// Count non-deleted files
		var fileCount int64
		s.db.Model(&models.DVRFile{}).Where("group_id = ? AND deleted = ?", g.ID, false).Count(&fileCount)
		g.FileCount = int(fileCount)

		// Count unwatched files for the current profile
		unwatchedCount := int(fileCount) // default: all are unwatched
		if profileID > 0 {
			var watchedCount int64
			s.db.Model(&models.FileState{}).
				Joins("JOIN dvr_files ON dvr_files.id = file_states.file_id").
				Where("file_states.profile_id = ? AND dvr_files.group_id = ? AND dvr_files.deleted = ? AND file_states.watched = ?",
					profileID, g.ID, false, true).
				Count(&watchedCount)
			unwatchedCount = int(fileCount) - int(watchedCount)
			if unwatchedCount < 0 {
				unwatchedCount = 0
			}
		}

		responses = append(responses, GroupResponse{
			DVRGroup:       g,
			UnwatchedCount: unwatchedCount,
		})
	}

	c.JSON(http.StatusOK, gin.H{"groups": responses})
}

// getGroup returns a single DVR group with its files
func (s *Server) getGroup(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid group ID"})
		return
	}

	var group models.DVRGroup
	if err := s.db.First(&group, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Group not found"})
		return
	}

	// Load non-deleted files for this group
	var files []models.DVRFile
	s.db.Where("group_id = ? AND deleted = ?", id, false).
		Preload("Commercials").
		Order("COALESCE(season_number, 0), COALESCE(episode_number, 0), created_at ASC").
		Find(&files)

	group.Files = files
	group.FileCount = len(files)

	c.JSON(http.StatusOK, group)
}

// deleteGroup deletes a DVR group and optionally its files
func (s *Server) deleteGroup(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid group ID"})
		return
	}

	var group models.DVRGroup
	if err := s.db.First(&group, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Group not found"})
		return
	}

	// Check if deleteFiles query param is set
	deleteFiles := c.Query("deleteFiles") == "true"

	if deleteFiles {
		// Soft-delete all files in this group
		var files []models.DVRFile
		s.db.Where("group_id = ? AND deleted = ?", id, false).Find(&files)
		for _, f := range files {
			f.Deleted = true
			s.db.Save(&f)
			if f.FilePath != "" {
				if _, statErr := os.Stat(f.FilePath); statErr == nil {
					os.Remove(f.FilePath)
				}
			}
		}
	} else {
		// Unlink files from this group (set group_id to NULL)
		s.db.Model(&models.DVRFile{}).Where("group_id = ?", id).Update("group_id", nil)
	}

	if err := s.db.Delete(&group).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete group"})
		return
	}

	s.publishDVREvent(dvr.DVREvent{Type: dvr.EventGroupUpdated, GroupID: group.ID, Title: group.Title, Message: "deleted"})
	c.JSON(http.StatusOK, gin.H{"message": "Group deleted"})
}

// updateGroupFileCount recalculates and updates the file_count for a group
func (s *Server) updateGroupFileCount(groupID uint) {
	var count int64
	s.db.Model(&models.DVRFile{}).Where("group_id = ? AND deleted = ?", groupID, false).Count(&count)
	s.db.Model(&models.DVRGroup{}).Where("id = ?", groupID).Update("file_count", count)
}

// ============ DVR V2: Rules ============

// getRules lists all DVR rules for the user
func (s *Server) getRules(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")

	var rules []models.DVRRule
	query := s.db.Model(&models.DVRRule{})
	if !isAdmin {
		query = query.Where("user_id = ?", userID)
	}
	if err := query.Order("created_at DESC").Find(&rules).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch rules"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"rules": rules})
}

// getRule returns a single DVR rule by ID
func (s *Server) getRule(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}

	var rule models.DVRRule
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id = ?", userID)
	}
	if err := query.First(&rule).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rule not found"})
		return
	}

	c.JSON(http.StatusOK, rule)
}

// createRule creates a new DVR rule
func (s *Server) createRule(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		Name            string `json:"name" binding:"required"`
		Image           string `json:"image"`
		Query           string `json:"query" binding:"required"`
		KeepOnly        bool   `json:"keepOnly"`
		KeepNum         int    `json:"keepNum"`
		Rerecord        bool   `json:"rerecord"`
		Duplicates      string `json:"duplicates"`
		Limit           int    `json:"limit"`
		PaddingStart    int    `json:"paddingStart"`
		PaddingEnd      int    `json:"paddingEnd"`
		RecordPreShow   bool   `json:"recordPreShow"`
		RecordPostShow  bool   `json:"recordPostShow"`
		PreShowMinutes  int    `json:"preShowMinutes"`
		PostShowMinutes int    `json:"postShowMinutes"`
		Priority        *int   `json:"priority"`
		QualityPreset   string `json:"qualityPreset"`
		Paused          bool   `json:"paused"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	priority := 50
	if req.Priority != nil {
		if *req.Priority < 0 || *req.Priority > 100 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Priority must be between 0 and 100"})
			return
		}
		priority = *req.Priority
	}

	duplicates := req.Duplicates
	if duplicates == "" {
		duplicates = "skip"
	}

	qualityPreset := req.QualityPreset
	if qualityPreset == "" {
		qualityPreset = "original"
	}

	preShowMinutes := req.PreShowMinutes
	if preShowMinutes <= 0 {
		preShowMinutes = 30
	}
	postShowMinutes := req.PostShowMinutes
	if postShowMinutes <= 0 {
		postShowMinutes = 60
	}

	rule := models.DVRRule{
		UserID:          userID,
		Name:            req.Name,
		Image:           req.Image,
		Query:           req.Query,
		KeepOnly:        req.KeepOnly,
		KeepNum:         req.KeepNum,
		Rerecord:        req.Rerecord,
		Duplicates:      duplicates,
		Limit:           req.Limit,
		PaddingStart:    req.PaddingStart,
		PaddingEnd:      req.PaddingEnd,
		RecordPreShow:   req.RecordPreShow,
		RecordPostShow:  req.RecordPostShow,
		PreShowMinutes:  preShowMinutes,
		PostShowMinutes: postShowMinutes,
		Priority:        priority,
		QualityPreset:   qualityPreset,
		Paused:          req.Paused,
		Enabled:         true,
	}

	if err := s.db.Create(&rule).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create rule"})
		return
	}

	s.publishDVREvent(dvr.DVREvent{Type: dvr.EventRuleTriggered, RuleID: rule.ID, Title: rule.Name, Message: "created"})
	c.JSON(http.StatusCreated, rule)
}

// updateRule updates an existing DVR rule
func (s *Server) updateRule(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}

	var rule models.DVRRule
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id = ?", userID)
	}
	if err := query.First(&rule).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rule not found"})
		return
	}

	var req struct {
		Name            *string `json:"name"`
		Image           *string `json:"image"`
		Query           *string `json:"query"`
		KeepOnly        *bool   `json:"keepOnly"`
		KeepNum         *int    `json:"keepNum"`
		Rerecord        *bool   `json:"rerecord"`
		Duplicates      *string `json:"duplicates"`
		Limit           *int    `json:"limit"`
		PaddingStart    *int    `json:"paddingStart"`
		PaddingEnd      *int    `json:"paddingEnd"`
		RecordPreShow   *bool   `json:"recordPreShow"`
		RecordPostShow  *bool   `json:"recordPostShow"`
		PreShowMinutes  *int    `json:"preShowMinutes"`
		PostShowMinutes *int    `json:"postShowMinutes"`
		Priority        *int    `json:"priority"`
		QualityPreset   *string `json:"qualityPreset"`
		Paused          *bool   `json:"paused"`
		Enabled         *bool   `json:"enabled"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Name != nil {
		rule.Name = *req.Name
	}
	if req.Image != nil {
		rule.Image = *req.Image
	}
	if req.Query != nil {
		rule.Query = *req.Query
	}
	if req.KeepOnly != nil {
		rule.KeepOnly = *req.KeepOnly
	}
	if req.KeepNum != nil {
		rule.KeepNum = *req.KeepNum
	}
	if req.Rerecord != nil {
		rule.Rerecord = *req.Rerecord
	}
	if req.Duplicates != nil {
		rule.Duplicates = *req.Duplicates
	}
	if req.Limit != nil {
		rule.Limit = *req.Limit
	}
	if req.PaddingStart != nil {
		rule.PaddingStart = *req.PaddingStart
	}
	if req.PaddingEnd != nil {
		rule.PaddingEnd = *req.PaddingEnd
	}
	if req.RecordPreShow != nil {
		rule.RecordPreShow = *req.RecordPreShow
	}
	if req.RecordPostShow != nil {
		rule.RecordPostShow = *req.RecordPostShow
	}
	if req.PreShowMinutes != nil {
		rule.PreShowMinutes = *req.PreShowMinutes
	}
	if req.PostShowMinutes != nil {
		rule.PostShowMinutes = *req.PostShowMinutes
	}
	if req.Priority != nil {
		if *req.Priority < 0 || *req.Priority > 100 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Priority must be between 0 and 100"})
			return
		}
		rule.Priority = *req.Priority
	}
	if req.QualityPreset != nil {
		rule.QualityPreset = *req.QualityPreset
	}
	if req.Paused != nil {
		rule.Paused = *req.Paused
	}
	if req.Enabled != nil {
		rule.Enabled = *req.Enabled
	}

	if err := s.db.Save(&rule).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update rule"})
		return
	}

	c.JSON(http.StatusOK, rule)
}

// deleteRule deletes a DVR rule
func (s *Server) deleteRule(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}

	var rule models.DVRRule
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id = ?", userID)
	}
	if err := query.First(&rule).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rule not found"})
		return
	}

	if err := s.db.Delete(&rule).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete rule"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Rule deleted"})
}

// previewRule shows which programs would match a rule's query DSL
func (s *Server) previewRule(c *gin.Context) {
	var req struct {
		Query string `json:"query" binding:"required"`
		Hours int    `json:"hours"` // How far ahead to look (default 48)
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	conditions, err := dvr.ParseQuery(req.Query)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid query DSL: " + err.Error()})
		return
	}
	if len(conditions) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Query must contain at least one condition"})
		return
	}

	hours := req.Hours
	if hours <= 0 {
		hours = 48
	}
	if hours > 168 { // Max 7 days
		hours = 168
	}

	now := time.Now().UTC()
	var programs []models.Program
	s.db.Where("start > ? AND start < ?", now, now.Add(time.Duration(hours)*time.Hour)).
		Order("start ASC").
		Find(&programs)

	// Build a temporary rule for matching
	tempRule := &models.DVRRule{Query: req.Query}
	matched := dvr.MatchProgramsForRule(programs, tempRule)

	// Limit to 100 results
	if len(matched) > 100 {
		matched = matched[:100]
	}

	c.JSON(http.StatusOK, gin.H{
		"programs":   matched,
		"totalCount": len(matched),
		"hours":      hours,
	})
}

// previewExistingRule shows which programs would match an existing rule
func (s *Server) previewExistingRule(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}

	var rule models.DVRRule
	if err := s.db.First(&rule, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rule not found"})
		return
	}

	now := time.Now().UTC()
	var programs []models.Program
	s.db.Where("start > ? AND start < ?", now, now.Add(7*24*time.Hour)).
		Order("start ASC").
		Find(&programs)

	matched := dvr.MatchProgramsForRule(programs, &rule)

	if len(matched) > 100 {
		matched = matched[:100]
	}

	c.JSON(http.StatusOK, gin.H{
		"programs":   matched,
		"totalCount": len(matched),
		"rule":       rule,
	})
}

// ============ DVR V2: Watch State ============

// updateFileState upserts a FileState record with watched/playbackTime/favorited
func (s *Server) updateFileState(c *gin.Context) {
	profileID := c.GetUint("profileID")
	if profileID == 0 {
		// Fall back to userID if profileID is not set
		profileID = c.GetUint("userID")
	}

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	// Verify file exists
	var file models.DVRFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	var req struct {
		Watched      *bool  `json:"watched"`
		PlaybackTime *int64 `json:"playbackTime"` // milliseconds
		Favorited    *bool  `json:"favorited"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Upsert the FileState
	var state models.FileState
	result := s.db.Where("profile_id = ? AND file_id = ?", profileID, id).First(&state)
	if result.Error != nil {
		// Create new
		state = models.FileState{
			ProfileID: profileID,
			FileID:    uint(id),
		}
	}

	now := time.Now()
	if req.Watched != nil {
		state.Watched = *req.Watched
		if *req.Watched {
			state.PlayedAt = &now
		}
	}
	if req.PlaybackTime != nil {
		state.PlaybackTime = *req.PlaybackTime
		state.PlayedAt = &now
	}
	if req.Favorited != nil {
		state.Favorited = *req.Favorited
		if *req.Favorited {
			state.FavoritedAt = &now
		} else {
			state.FavoritedAt = nil
		}
	}

	if state.ID == 0 {
		if err := s.db.Create(&state).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create file state"})
			return
		}
	} else {
		if err := s.db.Save(&state).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update file state"})
			return
		}
	}

	// Update GroupState when watch state changes
	if req.Watched != nil && file.GroupID != nil {
		go func() {
			upnext := dvr.NewUpNextManager(s.db)
			upnext.UpdateGroupStateForFile(profileID, uint(id))
		}()
	}

	c.JSON(http.StatusOK, state)
}

// getUpNext finds the next unwatched file per group for the current profile
func (s *Server) getUpNext(c *gin.Context) {
	profileID := c.GetUint("profileID")
	if profileID == 0 {
		profileID = c.GetUint("userID")
	}

	// Get all groups that have non-deleted files
	var groups []models.DVRGroup
	s.db.Where("file_count > 0").Order("title ASC").Find(&groups)

	type UpNextItem struct {
		Group models.DVRGroup `json:"group"`
		File  models.DVRFile  `json:"file"`
	}

	items := make([]UpNextItem, 0)

	for _, group := range groups {
		// Find the next unwatched file in this group
		// Order by season, episode, then created_at for chronological order
		var file models.DVRFile
		subQuery := s.db.Select("file_id").
			Where("profile_id = ? AND watched = ?", profileID, true).
			Table("file_states")

		err := s.db.Where("group_id = ? AND deleted = ? AND id NOT IN (?)", group.ID, false, subQuery).
			Order("COALESCE(season_number, 0), COALESCE(episode_number, 0), created_at ASC").
			First(&file).Error

		if err != nil {
			continue // No unwatched files in this group
		}

		items = append(items, UpNextItem{
			Group: group,
			File:  file,
		})
	}

	c.JSON(http.StatusOK, gin.H{"upNext": items, "totalCount": len(items)})
}

// updateGroupState updates the GroupState for the current profile (favorited)
func (s *Server) updateGroupState(c *gin.Context) {
	profileID := c.GetUint("profileID")
	if profileID == 0 {
		profileID = c.GetUint("userID")
	}

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid group ID"})
		return
	}

	var group models.DVRGroup
	if err := s.db.First(&group, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Group not found"})
		return
	}

	var req struct {
		Favorited *bool `json:"favorited"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Upsert GroupState
	var state models.GroupState
	result := s.db.Where("profile_id = ? AND group_id = ?", profileID, id).First(&state)
	if result.Error != nil {
		state = models.GroupState{
			ProfileID: profileID,
			GroupID:   uint(id),
		}
	}

	now := time.Now()
	if req.Favorited != nil {
		state.Favorited = *req.Favorited
		if *req.Favorited {
			state.FavoritedAt = &now
		} else {
			state.FavoritedAt = nil
		}
	}

	// Recalculate unwatched count
	upnextMgr := dvr.NewUpNextManager(s.db)
	upnextMgr.RecalculateGroupState(profileID, uint(id))

	// Re-fetch the updated state
	s.db.Where("profile_id = ? AND group_id = ?", profileID, id).First(&state)
	if req.Favorited != nil {
		state.Favorited = *req.Favorited
		if *req.Favorited {
			state.FavoritedAt = &now
		} else {
			state.FavoritedAt = nil
		}
		s.db.Save(&state)
	}

	c.JSON(http.StatusOK, state)
}

// regroupFile re-runs grouping logic for a single file
func (s *Server) regroupFile(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var file models.DVRFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	// Clear existing group assignment
	oldGroupID := file.GroupID
	file.GroupID = nil
	s.db.Model(&file).Update("group_id", nil)

	// Update old group's file count
	if oldGroupID != nil {
		s.updateGroupFileCount(*oldGroupID)
	}

	// Re-run grouper
	grouper := dvr.NewGrouper(s.db)
	if err := grouper.AssignFileToGroup(&file); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to regroup file"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "File regrouped",
		"fileId":  file.ID,
		"groupId": file.GroupID,
	})
}

// groupUngroupedFiles runs the grouper on all ungrouped files
func (s *Server) groupUngroupedFiles(c *gin.Context) {
	grouper := dvr.NewGrouper(s.db)
	count, err := grouper.GroupUngroupedFiles()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Grouping failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Grouping complete",
		"grouped": count,
	})
}

// ============ DVR V2: Virtual Stations ============

// getVirtualStations lists all virtual stations
func (s *Server) getVirtualStations(c *gin.Context) {
	var stations []models.VirtualStation
	query := s.db.Model(&models.VirtualStation{})

	if enabled := c.Query("enabled"); enabled != "" {
		query = query.Where("enabled = ?", enabled == "true")
	}

	if err := query.Order("number, name").Find(&stations).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch virtual stations"})
		return
	}

	c.JSON(http.StatusOK, stations)
}

// getVirtualStation returns a single virtual station with its resolved files
func (s *Server) getVirtualStation(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid station ID"})
		return
	}

	var station models.VirtualStation
	if err := s.db.First(&station, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Virtual station not found"})
		return
	}

	// Resolve files for the station
	files := s.resolveVirtualStationFiles(&station)

	c.JSON(http.StatusOK, gin.H{
		"station": station,
		"files":   files,
		"count":   len(files),
	})
}

// createVirtualStation creates a new virtual station
func (s *Server) createVirtualStation(c *gin.Context) {
	var station models.VirtualStation
	if err := c.ShouldBindJSON(&station); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if station.Name == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Name is required"})
		return
	}

	// Auto-assign channel number if not provided
	if station.Number == 0 {
		var maxNum int
		s.db.Model(&models.VirtualStation{}).Select("COALESCE(MAX(number), 9000)").Scan(&maxNum)
		station.Number = maxNum + 1
	}

	if err := s.db.Create(&station).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create virtual station"})
		return
	}

	c.JSON(http.StatusCreated, station)
}

// updateVirtualStation updates an existing virtual station
func (s *Server) updateVirtualStation(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid station ID"})
		return
	}

	var station models.VirtualStation
	if err := s.db.First(&station, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Virtual station not found"})
		return
	}

	var updates models.VirtualStation
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	s.db.Model(&station).Updates(map[string]interface{}{
		"name":        updates.Name,
		"number":      updates.Number,
		"logo":        updates.Logo,
		"art":         updates.Art,
		"description": updates.Description,
		"smart_rule":  updates.SmartRule,
		"file_ids":    updates.FileIDs,
		"sort":        updates.Sort,
		"order":       updates.Order,
		"shuffle":     updates.Shuffle,
		"loop":        updates.Loop,
		"limit":       updates.Limit,
		"enabled":     updates.Enabled,
	})

	s.db.First(&station, id)
	c.JSON(http.StatusOK, station)
}

// deleteVirtualStation deletes a virtual station
func (s *Server) deleteVirtualStation(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid station ID"})
		return
	}

	if err := s.db.Delete(&models.VirtualStation{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete virtual station"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Virtual station deleted"})
}

// streamVirtualStation generates an HLS playlist for the virtual station's content
func (s *Server) streamVirtualStation(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid station ID"})
		return
	}

	var station models.VirtualStation
	if err := s.db.First(&station, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Virtual station not found"})
		return
	}

	if !station.Enabled {
		c.JSON(http.StatusConflict, gin.H{"error": "Virtual station is disabled"})
		return
	}

	files := s.resolveVirtualStationFiles(&station)
	if len(files) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "No files in virtual station"})
		return
	}

	baseURL := getBaseURL(c)

	// Build a simple M3U8 playlist that chains the files
	var m3u strings.Builder
	m3u.WriteString("#EXTM3U\n")
	m3u.WriteString("#EXT-X-VERSION:3\n")

	for _, file := range files {
		duration := file.Duration
		if duration == 0 {
			duration = 3600 // Default 1 hour
		}
		m3u.WriteString(fmt.Sprintf("#EXTINF:%d,%s\n", duration, file.Title))
		m3u.WriteString(fmt.Sprintf("%s/dvr/v2/files/%d/stream\n", baseURL, file.ID))
	}

	if !station.Loop {
		m3u.WriteString("#EXT-X-ENDLIST\n")
	}

	c.Header("Content-Type", "application/vnd.apple.mpegurl")
	c.String(http.StatusOK, m3u.String())
}

// resolveVirtualStationFiles returns the files for a virtual station
func (s *Server) resolveVirtualStationFiles(station *models.VirtualStation) []models.DVRFile {
	var files []models.DVRFile

	// Smart rule: evaluate query DSL against files
	if station.SmartRule != "" {
		conditions, err := dvr.ParseQuery(station.SmartRule)
		if err == nil && len(conditions) > 0 {
			var allFiles []models.DVRFile
			s.db.Where("completed = ? AND deleted = ?", true, false).Find(&allFiles)
			for i := range allFiles {
				if matchFileAgainstConditions(conditions, &allFiles[i]) {
					files = append(files, allFiles[i])
				}
			}
		}
	}

	// Manual file IDs
	if station.FileIDs != "" {
		ids := parseIDList(station.FileIDs)
		if len(ids) > 0 {
			var manualFiles []models.DVRFile
			s.db.Where("id IN ? AND deleted = ?", ids, false).Find(&manualFiles)
			files = append(files, manualFiles...)
		}
	}

	// Apply sort
	files = sortDVRFiles(files, station.Sort, station.Order)

	// Apply limit
	if station.Limit > 0 && len(files) > station.Limit {
		files = files[:station.Limit]
	}

	return files
}

// ============ DVR V2: Collections ============

// getCollections lists all DVR collections
func (s *Server) getDVRCollections(c *gin.Context) {
	var collections []models.DVRCollection
	if err := s.db.Order("title").Find(&collections).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch collections"})
		return
	}

	c.JSON(http.StatusOK, collections)
}

// getCollection returns a single collection with its resolved items
func (s *Server) getDVRCollection(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	var collection models.DVRCollection
	if err := s.db.First(&collection, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Collection not found"})
		return
	}

	files, groups := s.resolveCollectionItems(&collection)

	c.JSON(http.StatusOK, gin.H{
		"collection": collection,
		"files":      files,
		"groups":     groups,
	})
}

// createCollection creates a new DVR collection
func (s *Server) createDVRCollection(c *gin.Context) {
	var collection models.DVRCollection
	if err := c.ShouldBindJSON(&collection); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if collection.Title == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Title is required"})
		return
	}

	if err := s.db.Create(&collection).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create collection"})
		return
	}

	c.JSON(http.StatusCreated, collection)
}

// updateCollection updates an existing collection
func (s *Server) updateDVRCollection(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	var collection models.DVRCollection
	if err := s.db.First(&collection, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Collection not found"})
		return
	}

	var updates models.DVRCollection
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	s.db.Model(&collection).Updates(map[string]interface{}{
		"title":              updates.Title,
		"description":        updates.Description,
		"thumb":              updates.Thumb,
		"smart":              updates.Smart,
		"smart_rule":         updates.SmartRule,
		"tmdb_collection_id": updates.TMDBCollectionID,
		"file_ids":           updates.FileIDs,
		"group_ids":          updates.GroupIDs,
		"sort":               updates.Sort,
		"order":              updates.Order,
	})

	s.db.First(&collection, id)
	c.JSON(http.StatusOK, collection)
}

// deleteCollection deletes a DVR collection
func (s *Server) deleteDVRCollection(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	if err := s.db.Delete(&models.DVRCollection{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete collection"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Collection deleted"})
}

// getCollectionItems returns the resolved items for a collection
func (s *Server) getDVRCollectionItems(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	var collection models.DVRCollection
	if err := s.db.First(&collection, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Collection not found"})
		return
	}

	files, groups := s.resolveCollectionItems(&collection)

	c.JSON(http.StatusOK, gin.H{
		"files":  files,
		"groups": groups,
	})
}

// resolveCollectionItems returns files and groups for a collection
func (s *Server) resolveCollectionItems(collection *models.DVRCollection) ([]models.DVRFile, []models.DVRGroup) {
	var files []models.DVRFile
	var groups []models.DVRGroup

	// Smart rule: evaluate query DSL
	if collection.Smart && collection.SmartRule != "" {
		conditions, err := dvr.ParseQuery(collection.SmartRule)
		if err == nil && len(conditions) > 0 {
			var allFiles []models.DVRFile
			s.db.Where("completed = ? AND deleted = ?", true, false).Find(&allFiles)
			for i := range allFiles {
				if matchFileAgainstConditions(conditions, &allFiles[i]) {
					files = append(files, allFiles[i])
				}
			}
		}
	}

	// Manual file IDs
	if collection.FileIDs != "" {
		ids := parseIDList(collection.FileIDs)
		if len(ids) > 0 {
			var manualFiles []models.DVRFile
			s.db.Where("id IN ? AND deleted = ?", ids, false).Find(&manualFiles)
			files = append(files, manualFiles...)
		}
	}

	// Group IDs
	if collection.GroupIDs != "" {
		ids := parseIDList(collection.GroupIDs)
		if len(ids) > 0 {
			s.db.Where("id IN ?", ids).Find(&groups)
			// Also include files from these groups
			var groupFiles []models.DVRFile
			s.db.Where("group_id IN ? AND deleted = ?", ids, false).Find(&groupFiles)
			files = append(files, groupFiles...)
		}
	}

	// Apply sort
	files = sortDVRFiles(files, collection.Sort, collection.Order)

	// Deduplicate files
	files = deduplicateFiles(files)

	return files, groups
}

// ============ DVR V2: Channel Collections ============

// getChannelCollections lists all channel collections
func (s *Server) getChannelCollections(c *gin.Context) {
	var collections []models.ChannelCollection
	if err := s.db.Order("name").Find(&collections).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch channel collections"})
		return
	}

	c.JSON(http.StatusOK, collections)
}

// getChannelCollection returns a single channel collection with resolved channels
func (s *Server) getChannelCollection(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	var collection models.ChannelCollection
	if err := s.db.First(&collection, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel collection not found"})
		return
	}

	// Resolve channels
	var channels []models.Channel
	if collection.ChannelIDs != "" {
		ids := parseIDList(collection.ChannelIDs)
		if len(ids) > 0 {
			s.db.Where("id IN ?", ids).Find(&channels)
		}
	}

	// Resolve virtual stations
	var stations []models.VirtualStation
	if collection.VirtualStationIDs != "" {
		ids := parseIDList(collection.VirtualStationIDs)
		if len(ids) > 0 {
			s.db.Where("id IN ?", ids).Find(&stations)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"collection":      collection,
		"channels":        channels,
		"virtualStations": stations,
	})
}

// createChannelCollection creates a new channel collection
func (s *Server) createChannelCollection(c *gin.Context) {
	var collection models.ChannelCollection
	if err := c.ShouldBindJSON(&collection); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if collection.Name == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Name is required"})
		return
	}

	if err := s.db.Create(&collection).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create channel collection"})
		return
	}

	c.JSON(http.StatusCreated, collection)
}

// updateChannelCollection updates an existing channel collection
func (s *Server) updateChannelCollection(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	var collection models.ChannelCollection
	if err := s.db.First(&collection, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel collection not found"})
		return
	}

	var updates models.ChannelCollection
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	s.db.Model(&collection).Updates(map[string]interface{}{
		"name":                updates.Name,
		"description":         updates.Description,
		"channel_ids":         updates.ChannelIDs,
		"virtual_station_ids": updates.VirtualStationIDs,
	})

	s.db.First(&collection, id)
	c.JSON(http.StatusOK, collection)
}

// deleteChannelCollection deletes a channel collection
func (s *Server) deleteChannelCollection(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	if err := s.db.Delete(&models.ChannelCollection{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete channel collection"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Channel collection deleted"})
}

// exportChannelCollectionM3U exports a channel collection as M3U playlist
func (s *Server) exportChannelCollectionM3U(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	var collection models.ChannelCollection
	if err := s.db.First(&collection, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel collection not found"})
		return
	}

	baseURL := getBaseURL(c)

	var m3u strings.Builder
	m3u.WriteString("#EXTM3U\n")

	// Add real channels
	if collection.ChannelIDs != "" {
		ids := parseIDList(collection.ChannelIDs)
		if len(ids) > 0 {
			var channels []models.Channel
			s.db.Where("id IN ?", ids).Find(&channels)

			// Maintain order from ChannelIDs
			channelMap := make(map[uint]models.Channel)
			for _, ch := range channels {
				channelMap[ch.ID] = ch
			}

			for _, chID := range ids {
				ch, ok := channelMap[uint(chID)]
				if !ok {
					continue
				}
				extinf := "#EXTINF:-1"
				tvgID := ch.ChannelID
				if tvgID == "" {
					tvgID = ch.TVGId
				}
				if tvgID != "" {
					extinf += fmt.Sprintf(` tvg-id="%s"`, escapeM3UValue(tvgID))
				}
				extinf += fmt.Sprintf(` tvg-name="%s"`, escapeM3UValue(ch.Name))
				if ch.Number > 0 {
					extinf += fmt.Sprintf(` tvg-chno="%d"`, ch.Number)
				}
				if ch.Logo != "" {
					extinf += fmt.Sprintf(` tvg-logo="%s"`, escapeM3UValue(ch.Logo))
				}
				if ch.Group != "" {
					extinf += fmt.Sprintf(` group-title="%s"`, escapeM3UValue(ch.Group))
				}
				stationID := getGracenoteStationID(ch)
				if stationID != "" {
					extinf += fmt.Sprintf(` tvc-guide-stationid="%s"`, stationID)
				}
				extinf += fmt.Sprintf(",%s\n", ch.Name)
				m3u.WriteString(extinf)
				m3u.WriteString(fmt.Sprintf("%s/api/livetv/channels/%d/stream.m3u8\n", baseURL, ch.ID))
			}
		}
	}

	// Add virtual stations
	if collection.VirtualStationIDs != "" {
		ids := parseIDList(collection.VirtualStationIDs)
		if len(ids) > 0 {
			var stations []models.VirtualStation
			s.db.Where("id IN ? AND enabled = ?", ids, true).Find(&stations)

			for _, st := range stations {
				extinf := "#EXTINF:-1"
				extinf += fmt.Sprintf(` tvg-name="%s"`, escapeM3UValue(st.Name))
				if st.Number > 0 {
					extinf += fmt.Sprintf(` tvg-chno="%d"`, st.Number)
				}
				if st.Logo != "" {
					extinf += fmt.Sprintf(` tvg-logo="%s"`, escapeM3UValue(st.Logo))
				}
				extinf += ` group-title="Virtual"`
				extinf += fmt.Sprintf(",%s\n", st.Name)
				m3u.WriteString(extinf)
				m3u.WriteString(fmt.Sprintf("%s/dvr/v2/virtual-stations/%d/stream.m3u8\n", baseURL, st.ID))
			}
		}
	}

	c.Header("Content-Type", "audio/x-mpegurl")
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s.m3u\"", collection.Name))
	c.String(http.StatusOK, m3u.String())
}

// ============ DVR V2: WebSocket Events ============

// dvrEvents handles WebSocket connections for real-time DVR event streaming
func (s *Server) dvrEvents(c *gin.Context) {
	if s.recorder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "DVR not available"})
		return
	}

	eventBus := s.recorder.GetEventBus()
	if eventBus == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Event bus not available"})
		return
	}

	upgrader := websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool { return true },
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}
	defer conn.Close()

	// Generate subscriber ID
	subscriberID := fmt.Sprintf("ws-%d", time.Now().UnixNano())
	ch := eventBus.Subscribe(subscriberID)
	defer eventBus.Unsubscribe(subscriberID)

	// Send a welcome message
	welcome, _ := json.Marshal(map[string]string{
		"type":    "connected",
		"message": "DVR event stream connected",
	})
	conn.WriteMessage(websocket.TextMessage, welcome)

	// Read goroutine to detect client disconnect
	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			if _, _, err := conn.ReadMessage(); err != nil {
				return
			}
		}
	}()

	// Write events to WebSocket
	for {
		select {
		case msg, ok := <-ch:
			if !ok {
				return
			}
			if err := conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				return
			}
		case <-done:
			return
		}
	}
}

// publishDVREvent publishes an event to the DVR event bus if available
func (s *Server) publishDVREvent(event dvr.DVREvent) {
	if s.recorder != nil {
		if eb := s.recorder.GetEventBus(); eb != nil {
			eb.Publish(event)
		}
	}
}

// ============ Helpers ============

// parseIDList parses a comma-separated string of IDs into uint slice
func parseIDList(s string) []uint {
	parts := strings.Split(s, ",")
	var ids []uint
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if id, err := strconv.ParseUint(p, 10, 32); err == nil {
			ids = append(ids, uint(id))
		}
	}
	return ids
}

// matchFileAgainstConditions evaluates query conditions against a DVRFile
func matchFileAgainstConditions(conditions []models.RuleCondition, file *models.DVRFile) bool {
	for _, cond := range conditions {
		fieldValue := getFileFieldValue(cond.Field, file)
		if !evaluateFileCondition(cond.Op, fieldValue, cond.Value) {
			return false
		}
	}
	return true
}

// getFileFieldValue extracts field values from a DVRFile for query matching
func getFileFieldValue(field string, f *models.DVRFile) string {
	switch strings.ToLower(field) {
	case "title":
		return f.Title
	case "subtitle":
		return f.Subtitle
	case "description", "summary":
		return f.Description
	case "genre", "genres":
		return f.Genres
	case "contentrating", "rating":
		return f.ContentRating
	case "ismovie":
		return strconv.FormatBool(f.IsMovie)
	case "year":
		if f.Year != nil && *f.Year > 0 {
			return strconv.Itoa(*f.Year)
		}
		return ""
	case "season", "seasonnumber":
		if f.SeasonNumber != nil && *f.SeasonNumber > 0 {
			return strconv.Itoa(*f.SeasonNumber)
		}
		return ""
	case "episode", "episodenumber":
		if f.EpisodeNumber != nil && *f.EpisodeNumber > 0 {
			return strconv.Itoa(*f.EpisodeNumber)
		}
		return ""
	case "labels":
		return f.Labels
	default:
		return ""
	}
}

// evaluateFileCondition applies query ops to file field values
func evaluateFileCondition(op, fieldValue, condValue string) bool {
	switch strings.ToUpper(op) {
	case "EQ":
		return strings.EqualFold(fieldValue, condValue)
	case "NE":
		return !strings.EqualFold(fieldValue, condValue)
	case "LIKE":
		fv := strings.ToLower(fieldValue)
		cv := strings.ToLower(condValue)
		if strings.HasPrefix(cv, "%") && strings.HasSuffix(cv, "%") {
			return strings.Contains(fv, cv[1:len(cv)-1])
		}
		if strings.HasPrefix(cv, "%") {
			return strings.HasSuffix(fv, cv[1:])
		}
		if strings.HasSuffix(cv, "%") {
			return strings.HasPrefix(fv, cv[:len(cv)-1])
		}
		return strings.Contains(fv, cv)
	case "IN":
		parts := strings.Split(condValue, ",")
		for _, p := range parts {
			if strings.EqualFold(fieldValue, strings.TrimSpace(p)) {
				return true
			}
		}
		return false
	case "NI":
		parts := strings.Split(condValue, ",")
		for _, p := range parts {
			if strings.EqualFold(fieldValue, strings.TrimSpace(p)) {
				return false
			}
		}
		return true
	default:
		return false
	}
}

// sortDVRFiles sorts files by the given criteria
func sortDVRFiles(files []models.DVRFile, sortBy, order string) []models.DVRFile {
	if len(files) <= 1 {
		return files
	}

	// Import sort inline
	switch strings.ToLower(sortBy) {
	case "title":
		for i := 0; i < len(files); i++ {
			for j := i + 1; j < len(files); j++ {
				if strings.ToLower(files[i].Title) > strings.ToLower(files[j].Title) {
					files[i], files[j] = files[j], files[i]
				}
			}
		}
	case "date":
		for i := 0; i < len(files); i++ {
			for j := i + 1; j < len(files); j++ {
				if files[i].CreatedAt.After(files[j].CreatedAt) {
					files[i], files[j] = files[j], files[i]
				}
			}
		}
	case "episode":
		for i := 0; i < len(files); i++ {
			for j := i + 1; j < len(files); j++ {
				si := derefInt(files[i].SeasonNumber)*1000 + derefInt(files[i].EpisodeNumber)
				sj := derefInt(files[j].SeasonNumber)*1000 + derefInt(files[j].EpisodeNumber)
				if si > sj {
					files[i], files[j] = files[j], files[i]
				}
			}
		}
	}

	// Reverse for desc
	if strings.ToLower(order) == "desc" {
		for i, j := 0, len(files)-1; i < j; i, j = i+1, j-1 {
			files[i], files[j] = files[j], files[i]
		}
	}

	return files
}

// deduplicateFiles removes duplicate files by ID
func deduplicateFiles(files []models.DVRFile) []models.DVRFile {
	seen := make(map[uint]bool)
	result := make([]models.DVRFile, 0, len(files))
	for _, f := range files {
		if !seen[f.ID] {
			seen[f.ID] = true
			result = append(result, f)
		}
	}
	return result
}

// derefInt safely dereferences an *int pointer, returning 0 if nil
func derefInt(p *int) int {
	if p == nil {
		return 0
	}
	return *p
}
