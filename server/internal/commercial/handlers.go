package commercial

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all commercial skip API routes with Gin
func RegisterRoutes(r *gin.RouterGroup, detector *CommercialDetector) {
	r.POST("/detect", detectHandler(detector))
	r.GET("/get", getHandler(detector))
	r.GET("/check", checkHandler(detector))
	r.POST("/mark", markHandler(detector))
	r.POST("/unmark", unmarkHandler(detector))
	r.GET("/config", getConfigHandler(detector))
	r.POST("/config", setConfigHandler(detector))
	r.GET("/stats", statsHandler(detector))
}

// SetupCommercialSkip creates and returns the commercial detector
func SetupCommercialSkip() *CommercialDetector {
	config := DefaultDetectorConfig()
	return NewCommercialDetector(config)
}

// detectHandler triggers commercial detection for a recording
func detectHandler(d *CommercialDetector) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			RecordingID string `json:"recording_id"`
			VideoPath   string `json:"video_path"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		// Run detection in background
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
			defer cancel()
			d.DetectCommercials(ctx, req.RecordingID, req.VideoPath)
		}()

		c.JSON(http.StatusOK, gin.H{
			"success":      true,
			"message":      "Detection started",
			"recording_id": req.RecordingID,
		})
	}
}

// getHandler returns detected commercials for a recording
func getHandler(d *CommercialDetector) gin.HandlerFunc {
	return func(c *gin.Context) {
		recordingID := c.Query("recording_id")
		if recordingID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "recording_id required"})
			return
		}

		data := d.GetCommercials(recordingID)
		if data == nil {
			c.JSON(http.StatusOK, gin.H{
				"success":  true,
				"detected": false,
				"message":  "No commercial data available",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success":  true,
			"detected": true,
			"data":     data,
		})
	}
}

// checkHandler checks if current position is in a commercial
func checkHandler(d *CommercialDetector) gin.HandlerFunc {
	return func(c *gin.Context) {
		recordingID := c.Query("recording_id")
		positionStr := c.Query("position")

		if recordingID == "" || positionStr == "" {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "recording_id and position required"})
			return
		}

		var position float64
		if _, err := fmt.Sscanf(positionStr, "%f", &position); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid position"})
			return
		}

		shouldSkip, skipTo := d.ShouldSkip(recordingID, position)

		c.JSON(http.StatusOK, gin.H{
			"success":     true,
			"should_skip": shouldSkip,
			"skip_to":     skipTo,
			"position":    position,
		})
	}
}

// markHandler manually marks a segment as commercial
func markHandler(d *CommercialDetector) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			RecordingID string  `json:"recording_id"`
			StartTime   float64 `json:"start_time"`
			EndTime     float64 `json:"end_time"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		d.MarkAsCommercial(req.RecordingID, req.StartTime, req.EndTime)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Marked as commercial",
		})
	}
}

// unmarkHandler marks a segment as NOT a commercial (user correction)
func unmarkHandler(d *CommercialDetector) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			RecordingID string  `json:"recording_id"`
			StartTime   float64 `json:"start_time"`
			EndTime     float64 `json:"end_time"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		d.MarkAsContent(req.RecordingID, req.StartTime, req.EndTime)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Marked as content (not commercial)",
		})
	}
}

// getConfigHandler returns detection config
func getConfigHandler(d *CommercialDetector) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"config":  d.Config,
		})
	}
}

// setConfigHandler updates detection config
func setConfigHandler(d *CommercialDetector) gin.HandlerFunc {
	return func(c *gin.Context) {
		var config DetectorConfig
		if err := c.ShouldBindJSON(&config); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid config"})
			return
		}

		d.Config = config

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Config updated",
		})
	}
}

// statsHandler returns detection statistics
func statsHandler(d *CommercialDetector) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"stats":   d.GetStats(),
		})
	}
}
