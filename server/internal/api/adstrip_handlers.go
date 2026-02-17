package api

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/logger"
)

// stripAds triggers ad stripping for a DVR file.
// POST /dvr/v2/files/:id/strip-ads
func (s *Server) stripAds(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}
	fileID := uint(id)

	// Parse request body
	var req struct {
		Mode         string `json:"mode"`         // "copy" (default) or "reencode"
		KeepOriginal bool   `json:"keepOriginal"` // always true for now; original is always kept as backup
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		// Default values if body is empty or malformed
		req.Mode = "copy"
		req.KeepOriginal = true
	}
	if req.Mode == "" {
		req.Mode = "copy"
	}
	if req.Mode != "copy" && req.Mode != "reencode" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "mode must be 'copy' or 'reencode'"})
		return
	}

	// Create ad stripper
	stripper := dvr.NewAdStripper(s.db, "")

	// Run asynchronously
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Hour)
		defer cancel()

		var outputPath string
		var stripErr error

		if req.Mode == "copy" {
			outputPath, stripErr = stripper.StripAdsStreamCopy(ctx, fileID)
		} else {
			outputPath, stripErr = stripper.StripAds(ctx, fileID)
		}

		if stripErr != nil {
			logger.Log.WithFields(map[string]interface{}{
				"file_id": fileID,
				"mode":    req.Mode,
				"error":   stripErr.Error(),
			}).Error("Ad stripping failed")
		} else {
			logger.Log.WithFields(map[string]interface{}{
				"file_id":     fileID,
				"mode":        req.Mode,
				"output_path": outputPath,
			}).Info("Ad stripping completed")
		}
	}()

	c.JSON(http.StatusAccepted, gin.H{
		"message": "Ad stripping started",
		"fileId":  fileID,
		"mode":    req.Mode,
	})
}

// getStripAdsStatus returns the current ad-strip status for a file.
// GET /dvr/v2/files/:id/strip-ads/status
func (s *Server) getStripAdsStatus(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}
	fileID := uint(id)

	stripper := dvr.NewAdStripper(s.db, "")
	status, err := stripper.GetStripStatus(fileID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, status)
}

// undoStripAds restores the original file, removing the ad-stripped version.
// POST /dvr/v2/files/:id/strip-ads/undo
func (s *Server) undoStripAds(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}
	fileID := uint(id)

	stripper := dvr.NewAdStripper(s.db, "")
	if err := stripper.UndoStripAds(context.Background(), fileID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Original file restored successfully",
		"fileId":  fileID,
	})
}
