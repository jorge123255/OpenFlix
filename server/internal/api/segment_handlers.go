package api

import (
	"context"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// SegmentHandlers groups all HTTP handlers for segment detection endpoints.
type SegmentHandlers struct {
	detector *dvr.SegmentDetector
	db       *gorm.DB
}

// NewSegmentHandlers creates a new SegmentHandlers instance. If detector is
// nil, all endpoints will return 503 Service Unavailable.
func NewSegmentHandlers(detector *dvr.SegmentDetector, db *gorm.DB) *SegmentHandlers {
	return &SegmentHandlers{
		detector: detector,
		db:       db,
	}
}

// RegisterSegmentRoutes registers segment detection routes on the given
// router groups. File and group endpoints are registered under dvrV2
// (requires auth), and status endpoints under admin (requires admin).
func RegisterSegmentRoutes(dvrV2 *gin.RouterGroup, admin *gin.RouterGroup, h *SegmentHandlers) {
	// DVR V2 file segment routes
	dvrV2.POST("/files/:id/detect-segments", h.detectFileSegments())
	dvrV2.GET("/files/:id/segments", h.getFileSegments())
	dvrV2.DELETE("/files/:id/segments", h.deleteFileSegments())

	// DVR V2 group segment routes
	dvrV2.POST("/groups/:id/detect-segments", h.detectGroupSegments())

	// Admin status route
	admin.GET("/segments/status", h.getSegmentDetectionStatus())
}

// detectFileSegments triggers intro/outro/credits segment detection for a
// single DVR file. The detection runs asynchronously; a 202 Accepted is
// returned immediately.
//
// POST /dvr/v2/files/:id/detect-segments
func (h *SegmentHandlers) detectFileSegments() gin.HandlerFunc {
	return func(c *gin.Context) {
		if h.detector == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Segment detection not available"})
			return
		}

		id, err := strconv.ParseUint(c.Param("id"), 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
			return
		}

		// Verify the file exists
		var fileCount int64
		h.db.Model(&models.DVRFile{}).Where("id = ? AND deleted = ?", id, false).Count(&fileCount)
		if fileCount == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
			return
		}

		// Run detection in background
		go func() {
			ctx := context.Background()
			result, detErr := h.detector.DetectFile(ctx, uint(id))
			if detErr != nil {
				logger.Errorf("Segment detection failed for file %d: %v", id, detErr)
				return
			}
			logger.Infof("Segment detection complete for file %d: %d segments found", id, len(result.Segments))
		}()

		c.JSON(http.StatusAccepted, gin.H{
			"message": "Segment detection started",
			"fileId":  id,
		})
	}
}

// detectGroupSegments triggers intro/outro/credits segment detection for all
// files in a DVR group with cross-episode pattern matching. The detection
// runs asynchronously; a 202 Accepted is returned immediately.
//
// POST /dvr/v2/groups/:id/detect-segments
func (h *SegmentHandlers) detectGroupSegments() gin.HandlerFunc {
	return func(c *gin.Context) {
		if h.detector == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Segment detection not available"})
			return
		}

		id, err := strconv.ParseUint(c.Param("id"), 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid group ID"})
			return
		}

		// Verify the group exists
		var groupCount int64
		h.db.Model(&models.DVRGroup{}).Where("id = ?", id).Count(&groupCount)
		if groupCount == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Group not found"})
			return
		}

		// Run detection in background
		go func() {
			ctx := context.Background()
			results, detErr := h.detector.DetectGroup(ctx, uint(id))
			if detErr != nil {
				logger.Errorf("Group segment detection failed for group %d: %v", id, detErr)
				return
			}
			totalSegments := 0
			for _, r := range results {
				totalSegments += len(r.Segments)
			}
			logger.Infof("Group segment detection complete for group %d: %d files, %d total segments",
				id, len(results), totalSegments)
		}()

		c.JSON(http.StatusAccepted, gin.H{
			"message": "Group segment detection started",
			"groupId": id,
		})
	}
}

// getFileSegments returns detected intro/outro/credits segments for a
// specific DVR file.
//
// GET /dvr/v2/files/:id/segments
func (h *SegmentHandlers) getFileSegments() gin.HandlerFunc {
	return func(c *gin.Context) {
		if h.detector == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Segment detection not available"})
			return
		}

		id, err := strconv.ParseUint(c.Param("id"), 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
			return
		}

		segments, segErr := h.detector.GetSegments(uint(id))
		if segErr != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch segments"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"fileId":   id,
			"segments": segments,
			"count":    len(segments),
		})
	}
}

// deleteFileSegments removes all detected segments for a specific DVR file.
//
// DELETE /dvr/v2/files/:id/segments
func (h *SegmentHandlers) deleteFileSegments() gin.HandlerFunc {
	return func(c *gin.Context) {
		if h.detector == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Segment detection not available"})
			return
		}

		id, err := strconv.ParseUint(c.Param("id"), 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
			return
		}

		if delErr := h.detector.DeleteSegments(uint(id)); delErr != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete segments"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Segments deleted",
			"fileId":  id,
		})
	}
}

// getSegmentDetectionStatus returns the current status of the segment
// detector, including whether it is actively processing.
//
// GET /admin/segments/status
func (h *SegmentHandlers) getSegmentDetectionStatus() gin.HandlerFunc {
	return func(c *gin.Context) {
		if h.detector == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"available": false,
				"running":   false,
				"error":     "Segment detector not initialized",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"available": true,
			"running":   h.detector.IsRunning(),
		})
	}
}
