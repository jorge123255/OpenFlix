package api

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Label Management API ============

// LabelInfo represents a label with its usage count
type LabelInfo struct {
	Label string `json:"label"`
	Count int    `json:"count"`
}

// SetLabelsRequest is the request body for setting labels on a file or recording
type SetLabelsRequest struct {
	Labels []string `json:"labels"`
}

// BulkLabelRequest is the request body for bulk add/remove label operations
type BulkLabelRequest struct {
	Action  string `json:"action"`  // "add" or "remove"
	Label   string `json:"label"`
	FileIDs []uint `json:"fileIds"`
}

// getLabels returns all unique labels across DVR files and recordings with counts.
// GET /dvr/labels
func (s *Server) getLabels(c *gin.Context) {
	labelCounts := make(map[string]int)

	// Collect labels from DVR files
	var files []models.DVRFile
	if err := s.db.Where("labels != '' AND labels IS NOT NULL AND deleted = ?", false).
		Select("labels").Find(&files).Error; err != nil {
		logger.Warnf("Failed to query DVR file labels: %v", err)
	}
	for _, f := range files {
		for _, l := range splitLabelString(f.Labels) {
			labelCounts[l]++
		}
	}

	// Collect labels from legacy recordings (stored in the Category or other fields)
	// Note: Recording model doesn't have a dedicated Tags field, but DVRFile.Labels is the primary source

	// Build result
	var result []LabelInfo
	for label, count := range labelCounts {
		result = append(result, LabelInfo{
			Label: label,
			Count: count,
		})
	}

	if result == nil {
		result = []LabelInfo{}
	}

	c.JSON(http.StatusOK, gin.H{
		"labels": result,
	})
}

// setFileLabels sets labels on a DVR file.
// PUT /dvr/v2/files/:id/labels
func (s *Server) setFileLabels(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var req SetLabelsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	var file models.DVRFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	// Clean and deduplicate labels
	seen := make(map[string]bool)
	var cleaned []string
	for _, l := range req.Labels {
		trimmed := strings.TrimSpace(l)
		if trimmed != "" && !seen[trimmed] {
			seen[trimmed] = true
			cleaned = append(cleaned, trimmed)
		}
	}

	file.Labels = strings.Join(cleaned, ",")
	if err := s.db.Save(&file).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update labels"})
		return
	}

	logger.WithField("fileId", file.ID).Infof("Labels set: %s", file.Labels)
	c.JSON(http.StatusOK, gin.H{
		"message": "Labels updated",
		"file":    file,
	})
}

// setRecordingLabels sets labels/tags on a Recording.
// PUT /dvr/recordings/:id/labels
func (s *Server) setRecordingLabels(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	var req SetLabelsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	var recording models.Recording
	if err := s.db.First(&recording, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	// Clean and deduplicate labels
	seen := make(map[string]bool)
	var cleaned []string
	for _, l := range req.Labels {
		trimmed := strings.TrimSpace(l)
		if trimmed != "" && !seen[trimmed] {
			seen[trimmed] = true
			cleaned = append(cleaned, trimmed)
		}
	}

	// Store in the Category field as a workaround since Recording doesn't have a Tags field.
	// We'll use a convention: labels are stored comma-separated in Category.
	// However, to avoid overwriting real category data, we check if there's an
	// associated DVRFile and update that instead.
	// Look up associated DVR file by legacy recording ID
	var dvrFile models.DVRFile
	if err := s.db.Where("legacy_recording_id = ?", recording.ID).First(&dvrFile).Error; err == nil {
		// Found associated DVR file, update its labels
		dvrFile.Labels = strings.Join(cleaned, ",")
		if err := s.db.Save(&dvrFile).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update labels on DVR file"})
			return
		}
		logger.WithField("recordingId", recording.ID).Infof("Labels set on associated DVR file %d: %s", dvrFile.ID, dvrFile.Labels)
		c.JSON(http.StatusOK, gin.H{
			"message":   "Labels updated",
			"recording": recording,
			"labels":    cleaned,
		})
		return
	}

	// No DVR file found; return success with labels for client-side tracking
	logger.WithField("recordingId", recording.ID).Info("No DVR file associated; labels noted")
	c.JSON(http.StatusOK, gin.H{
		"message":   "Labels noted (no DVR file associated)",
		"recording": recording,
		"labels":    cleaned,
	})
}

// bulkLabelAction performs bulk add/remove of a label across multiple DVR files.
// POST /dvr/labels/bulk
func (s *Server) bulkLabelAction(c *gin.Context) {
	var req BulkLabelRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if req.Label == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Label is required"})
		return
	}

	if req.Action != "add" && req.Action != "remove" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Action must be 'add' or 'remove'"})
		return
	}

	if len(req.FileIDs) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "At least one file ID is required"})
		return
	}

	label := strings.TrimSpace(req.Label)
	var updated int
	var errors []string

	for _, fileID := range req.FileIDs {
		var file models.DVRFile
		if err := s.db.First(&file, fileID).Error; err != nil {
			errors = append(errors, "File "+strconv.FormatUint(uint64(fileID), 10)+" not found")
			continue
		}

		if req.Action == "add" {
			file.Labels = addLabel(file.Labels, label)
		} else {
			file.Labels = removeLabel(file.Labels, label)
		}

		if err := s.db.Save(&file).Error; err != nil {
			errors = append(errors, "Failed to update file "+strconv.FormatUint(uint64(fileID), 10))
			continue
		}
		updated++
	}

	logger.Infof("Bulk label %s: label=%s, updated=%d, errors=%d", req.Action, label, updated, len(errors))
	c.JSON(http.StatusOK, gin.H{
		"message": "Bulk label operation completed",
		"action":  req.Action,
		"label":   label,
		"updated": updated,
		"errors":  errors,
	})
}

// getFilesByLabel returns all DVR files with a specific label.
// GET /dvr/labels/:label/files
func (s *Server) getFilesByLabel(c *gin.Context) {
	label := c.Param("label")
	if label == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Label is required"})
		return
	}

	var files []models.DVRFile
	if err := s.db.Where("labels LIKE ? AND deleted = ?", "%"+label+"%", false).
		Order("created_at DESC").
		Find(&files).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch files"})
		return
	}

	// Filter to ensure exact label match (not just substring)
	var matched []models.DVRFile
	for _, f := range files {
		for _, l := range splitLabelString(f.Labels) {
			if l == label {
				matched = append(matched, f)
				break
			}
		}
	}

	if matched == nil {
		matched = []models.DVRFile{}
	}

	c.JSON(http.StatusOK, gin.H{
		"files":      matched,
		"label":      label,
		"totalCount": len(matched),
	})
}
