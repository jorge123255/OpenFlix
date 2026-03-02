package api

import (
	"context"
	"net/http"
	"path/filepath"
	"sort"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Chapter Marker Handlers ============

// chapterResponse is the unified chapter representation returned by the API.
// It merges data from ChapterMarker, DetectedSegment, and CommercialSegment tables.
type chapterResponse struct {
	ID           uint    `json:"id"`
	FileID       uint    `json:"fileId"`
	Title        string  `json:"title"`
	StartTime    float64 `json:"startTime"`
	EndTime      float64 `json:"endTime"`
	Type         string  `json:"type"`
	Thumbnail    string  `json:"thumbnail,omitempty"`
	AutoDetected bool    `json:"autoDetected"`
	Source       string  `json:"source"` // "chapter", "segment", "commercial"
}

// getFileChapters returns all chapters for a DVR file, merging data from
// ChapterMarker, DetectedSegment, and CommercialSegment tables into a
// unified sorted list.
//
// GET /dvr/v2/files/:id/chapters
func (s *Server) getFileChapters(c *gin.Context) {
	fileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	// Verify the file exists
	var file models.DVRFile
	if err := s.db.First(&file, fileID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	// Load chapter markers
	var chapters []models.ChapterMarker
	s.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&chapters)

	// Load detected segments (intro, outro, credits)
	var segments []models.DetectedSegment
	s.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&segments)

	// Load commercial segments
	var commercials []models.CommercialSegment
	s.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&commercials)

	// Merge all sources into a unified response
	var result []chapterResponse

	for _, ch := range chapters {
		result = append(result, chapterResponse{
			ID:           ch.ID,
			FileID:       ch.FileID,
			Title:        ch.Title,
			StartTime:    ch.StartTime,
			EndTime:      ch.EndTime,
			Type:         ch.Type,
			Thumbnail:    ch.Thumbnail,
			AutoDetected: ch.AutoDetected,
			Source:       "chapter",
		})
	}

	for _, seg := range segments {
		// Skip if there is already a chapter marker covering this segment
		if chapterCoversSegment(chapters, seg.StartTime, seg.EndTime) {
			continue
		}
		result = append(result, chapterResponse{
			ID:           seg.ID,
			FileID:       seg.FileID,
			Title:        chapterSegmentTitle(seg.Type),
			StartTime:    seg.StartTime,
			EndTime:      seg.EndTime,
			Type:         seg.Type,
			AutoDetected: true,
			Source:       "segment",
		})
	}

	for _, com := range commercials {
		if chapterCoversSegment(chapters, com.StartTime, com.EndTime) {
			continue
		}
		result = append(result, chapterResponse{
			ID:           com.ID,
			FileID:       fileIDFromCommercial(com),
			Title:        "Commercial Break",
			StartTime:    com.StartTime,
			EndTime:      com.EndTime,
			Type:         "commercial",
			AutoDetected: true,
			Source:       "commercial",
		})
	}

	// Sort by start time
	sort.Slice(result, func(i, j int) bool {
		return result[i].StartTime < result[j].StartTime
	})

	c.JSON(http.StatusOK, gin.H{
		"chapters": result,
		"count":    len(result),
		"fileId":   fileID,
	})
}

// addFileChapter adds a manual chapter marker to a DVR file.
//
// POST /dvr/v2/files/:id/chapters
func (s *Server) addFileChapter(c *gin.Context) {
	fileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	// Verify the file exists
	var file models.DVRFile
	if err := s.db.First(&file, fileID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	var req struct {
		Title     string  `json:"title" binding:"required"`
		StartTime float64 `json:"startTime" binding:"required"`
		EndTime   float64 `json:"endTime"`
		Type      string  `json:"type"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	if req.StartTime < 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "StartTime must be non-negative"})
		return
	}

	// Default end time to start time if not provided
	endTime := req.EndTime
	if endTime <= 0 {
		endTime = req.StartTime
	}

	if endTime < req.StartTime {
		c.JSON(http.StatusBadRequest, gin.H{"error": "EndTime must be greater than or equal to startTime"})
		return
	}

	// Validate type
	chapterType := req.Type
	if chapterType == "" {
		chapterType = "manual"
	}
	if !isValidChapterType(chapterType) {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Type must be one of: scene, commercial, intro, outro, credits, manual",
		})
		return
	}

	chapter := models.ChapterMarker{
		FileID:       uint(fileID),
		Title:        req.Title,
		StartTime:    req.StartTime,
		EndTime:      endTime,
		Type:         chapterType,
		AutoDetected: false,
	}

	if err := s.db.Create(&chapter).Error; err != nil {
		logger.Errorf("Failed to create chapter marker: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create chapter marker"})
		return
	}

	// Generate thumbnail in background if the file exists on disk
	if s.clipManager != nil && file.FilePath != "" {
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()

			thumbResult, thumbErr := s.clipManager.GenerateThumbnail(ctx, file.FilePath, req.StartTime)
			if thumbErr != nil {
				logger.Warnf("Thumbnail generation failed for chapter %d: %v", chapter.ID, thumbErr)
				return
			}

			s.db.Model(&chapter).Update("thumbnail", thumbResult)
			logger.Infof("Thumbnail generated for chapter %d", chapter.ID)
		}()
	}

	c.JSON(http.StatusCreated, gin.H{"chapter": chapter})
}

// updateFileChapter updates an existing chapter marker.
//
// PUT /dvr/v2/files/:id/chapters/:chapterId
func (s *Server) updateFileChapter(c *gin.Context) {
	fileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	chapterID, err := strconv.ParseUint(c.Param("chapterId"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chapter ID"})
		return
	}

	var chapter models.ChapterMarker
	if err := s.db.Where("id = ? AND file_id = ?", chapterID, fileID).First(&chapter).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Chapter marker not found"})
		return
	}

	var req struct {
		Title     *string  `json:"title"`
		StartTime *float64 `json:"startTime"`
		EndTime   *float64 `json:"endTime"`
		Type      *string  `json:"type"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	updates := map[string]interface{}{}

	if req.Title != nil {
		updates["title"] = *req.Title
	}
	if req.StartTime != nil {
		if *req.StartTime < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "StartTime must be non-negative"})
			return
		}
		updates["start_time"] = *req.StartTime
	}
	if req.EndTime != nil {
		updates["end_time"] = *req.EndTime
	}
	if req.Type != nil {
		if !isValidChapterType(*req.Type) {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Type must be one of: scene, commercial, intro, outro, credits, manual",
			})
			return
		}
		updates["type"] = *req.Type
	}

	if len(updates) == 0 {
		c.JSON(http.StatusOK, gin.H{"chapter": chapter})
		return
	}

	// Mark as manually edited (no longer auto-detected)
	updates["auto_detected"] = false

	if err := s.db.Model(&chapter).Updates(updates).Error; err != nil {
		logger.Errorf("Failed to update chapter marker %d: %v", chapterID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update chapter marker"})
		return
	}

	// Reload
	s.db.First(&chapter, chapterID)

	c.JSON(http.StatusOK, gin.H{"chapter": chapter})
}

// deleteFileChapter deletes a chapter marker.
//
// DELETE /dvr/v2/files/:id/chapters/:chapterId
func (s *Server) deleteFileChapter(c *gin.Context) {
	fileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	chapterID, err := strconv.ParseUint(c.Param("chapterId"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chapter ID"})
		return
	}

	var chapter models.ChapterMarker
	if err := s.db.Where("id = ? AND file_id = ?", chapterID, fileID).First(&chapter).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Chapter marker not found"})
		return
	}

	if err := s.db.Delete(&chapter).Error; err != nil {
		logger.Errorf("Failed to delete chapter marker %d: %v", chapterID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete chapter marker"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Chapter marker deleted"})
}

// detectFileChapters triggers auto-detection of chapter markers for a file.
// Detection runs in the background via the job queue if available, or as a
// simple goroutine otherwise.
//
// POST /dvr/v2/files/:id/chapters/detect
func (s *Server) detectFileChapters(c *gin.Context) {
	fileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	// Verify the file exists and has a path
	var file models.DVRFile
	if err := s.db.First(&file, fileID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	if file.FilePath == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File has no file path"})
		return
	}

	fID := uint(fileID)

	// Try to use the job queue for background processing
	if s.jobQueue != nil {
		jobID := s.jobQueue.Submit("chapter-detect", map[string]interface{}{
			"fileId":   fID,
			"filePath": file.FilePath,
		})

		if jobID != "" {
			c.JSON(http.StatusAccepted, gin.H{
				"message": "Chapter detection started",
				"jobId":   jobID,
				"fileId":  fID,
			})
			return
		}
		// If submit returned empty (worker not registered), fall through to goroutine
	}

	// Fall back to a simple background goroutine
	go s.runChapterDetection(fID, file.FilePath)

	c.JSON(http.StatusAccepted, gin.H{
		"message": "Chapter detection started in background",
		"fileId":  fID,
	})
}

// runChapterDetection performs the actual chapter detection work. It is called
// from either the job queue worker or a background goroutine.
func (s *Server) runChapterDetection(fileID uint, filePath string) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	detector := dvr.NewChapterDetector(s.db, "", s.config.Transcode.FFmpegPath)

	chapters, err := detector.DetectChapters(ctx, filePath)
	if err != nil {
		logger.Errorf("Chapter detection failed for file %d: %v", fileID, err)
		return
	}

	// Merge with existing segments
	merged := detector.MergeWithExisting(fileID, chapters)

	// Save to database
	if err := detector.SaveChapters(fileID, merged); err != nil {
		logger.Errorf("Failed to save chapters for file %d: %v", fileID, err)
		return
	}

	// Generate thumbnails
	dataDir := s.config.GetDataDir()
	thumbDir := filepath.Join(dataDir, "chapters", "thumbnails")
	detector.GenerateChapterThumbnails(ctx, filePath, merged, thumbDir)

	logger.Infof("Chapter detection complete for file %d: %d chapters", fileID, len(merged))
}

// ============ Helper functions ============

// chapterCoversSegment checks if any chapter marker already covers the given
// time range (within a 2-second tolerance).
func chapterCoversSegment(chapters []models.ChapterMarker, startTime, endTime float64) bool {
	for _, ch := range chapters {
		if ch.StartTime <= startTime+2.0 && ch.EndTime >= endTime-2.0 {
			return true
		}
	}
	return false
}

// chapterSegmentTitle returns a display title for a detected segment type.
func chapterSegmentTitle(segType string) string {
	switch segType {
	case "intro":
		return "Intro"
	case "outro":
		return "Outro"
	case "credits":
		return "Credits"
	case "commercial":
		return "Commercial Break"
	default:
		return "Segment"
	}
}

// fileIDFromCommercial extracts the file ID from a CommercialSegment,
// falling back to 0 if no FileID is set.
func fileIDFromCommercial(com models.CommercialSegment) uint {
	if com.FileID != nil {
		return *com.FileID
	}
	return 0
}

// isValidChapterType checks if the given type string is a valid chapter type.
func isValidChapterType(t string) bool {
	switch t {
	case "scene", "commercial", "intro", "outro", "credits", "manual":
		return true
	default:
		return false
	}
}
