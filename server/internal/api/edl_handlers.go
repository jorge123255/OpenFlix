package api

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// exportRecordingEDL generates an EDL (Edit Decision List) file for a recording's
// commercial segments. EDL files are used by media players (Kodi, MPC-HC, etc.)
// to automatically skip commercial breaks during playback.
//
// Supported formats:
//   - Standard EDL (default): "start\tend\taction_type" (type 3 = commercial break)
//   - MPlayer EDL (?format=mplayer): "start end 0" (type 0 = skip/cut)
//
// GET /dvr/recordings/:id/export.edl
func (s *Server) exportRecordingEDL(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	// Verify user has access to this recording
	var recording models.Recording
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id IN ?", []uint{userID, 0})
	}
	if err := query.First(&recording).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	// Get commercial segments for this recording
	var segments []models.CommercialSegment
	if err := s.db.Where("recording_id = ?", id).Order("start_time").Find(&segments).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch commercial segments"})
		return
	}

	if len(segments) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "No commercial segments found for this recording"})
		return
	}

	// Determine format
	format := c.DefaultQuery("format", "standard")

	// Build EDL content
	edlContent := buildEDLContent(segments, format)

	// Build filename from recording title
	filename := sanitizeFilename(recording.Title) + ".edl"

	c.Header("Content-Type", "text/plain; charset=utf-8")
	c.Header("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, filename))
	c.String(http.StatusOK, edlContent)
}

// exportFileEDL generates an EDL file for a DVR file's detected segments
// (commercial type). This uses the DVR v2 DetectedSegment model where
// type="commercial".
//
// Supported formats:
//   - Standard EDL (default): "start\tend\taction_type" (type 3 = commercial break)
//   - MPlayer EDL (?format=mplayer): "start end 0" (type 0 = skip/cut)
//
// GET /dvr/v2/files/:id/export.edl
func (s *Server) exportFileEDL(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	// Verify the file exists
	var file models.DVRFile
	if err := s.db.Where("id = ? AND deleted = ?", id, false).First(&file).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	// Determine which segment types to include
	// By default, include "commercial" segments. The ?types query param allows
	// exporting other types too (e.g., ?types=commercial,intro,outro,credits).
	typesParam := c.DefaultQuery("types", "commercial")
	segmentTypes := strings.Split(typesParam, ",")
	for i := range segmentTypes {
		segmentTypes[i] = strings.TrimSpace(segmentTypes[i])
	}

	// Query DetectedSegments for this file
	var detectedSegments []models.DetectedSegment
	if err := s.db.Where("file_id = ? AND type IN ?", id, segmentTypes).
		Order("start_time").Find(&detectedSegments).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch segments"})
		return
	}

	// Also check CommercialSegment table (linked via FileID) if "commercial" is
	// in the requested types, since some recordings store commercials there.
	if contains(segmentTypes, "commercial") {
		var commercialSegments []models.CommercialSegment
		s.db.Where("file_id = ?", id).Order("start_time").Find(&commercialSegments)
		// Convert CommercialSegments to DetectedSegments for unified handling
		for _, cs := range commercialSegments {
			// Check if this segment is already present (avoid duplicates)
			isDuplicate := false
			for _, ds := range detectedSegments {
				if ds.StartTime == cs.StartTime && ds.EndTime == cs.EndTime {
					isDuplicate = true
					break
				}
			}
			if !isDuplicate {
				detectedSegments = append(detectedSegments, models.DetectedSegment{
					FileID:    uint(id),
					Type:      "commercial",
					StartTime: cs.StartTime,
					EndTime:   cs.EndTime,
				})
			}
		}
	}

	if len(detectedSegments) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "No matching segments found for this file"})
		return
	}

	// Determine format
	format := c.DefaultQuery("format", "standard")

	// Build EDL content from detected segments
	edlContent := buildEDLFromDetectedSegments(detectedSegments, format)

	// Build filename
	filename := sanitizeFilename(file.Title) + ".edl"

	c.Header("Content-Type", "text/plain; charset=utf-8")
	c.Header("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, filename))
	c.String(http.StatusOK, edlContent)
}

// buildEDLContent formats commercial segments as EDL text.
//
// Standard EDL format (used by Kodi, MPC-HC, etc.):
//
//	start_seconds\tend_seconds\taction_type
//
// Where action_type values are:
//
//	0 = cut (remove segment)
//	1 = mute
//	2 = scene marker
//	3 = commercial break (skip with indicator)
//
// MPlayer EDL format:
//
//	start_seconds end_seconds 0
func buildEDLContent(segments []models.CommercialSegment, format string) string {
	var sb strings.Builder

	for _, seg := range segments {
		if format == "mplayer" {
			// MPlayer format: space-separated, action type 0 (cut/skip)
			sb.WriteString(fmt.Sprintf("%.2f %.2f 0\n", seg.StartTime, seg.EndTime))
		} else {
			// Standard EDL format: tab-separated, type 3 (commercial break)
			sb.WriteString(fmt.Sprintf("%.2f\t%.2f\t3\n", seg.StartTime, seg.EndTime))
		}
	}

	return sb.String()
}

// buildEDLFromDetectedSegments formats DetectedSegments as EDL text.
// Maps segment types to EDL action codes:
//   - commercial -> 3 (commercial break) in standard, 0 (cut) in mplayer
//   - intro, outro, credits -> 3 (commercial break) in standard, 0 (cut) in mplayer
func buildEDLFromDetectedSegments(segments []models.DetectedSegment, format string) string {
	var sb strings.Builder

	for _, seg := range segments {
		if format == "mplayer" {
			sb.WriteString(fmt.Sprintf("%.2f %.2f 0\n", seg.StartTime, seg.EndTime))
		} else {
			// Standard EDL: use type 3 for commercial, 2 for scene markers (intro/outro/credits)
			actionType := 3 // commercial break
			if seg.Type == "intro" || seg.Type == "outro" || seg.Type == "credits" {
				actionType = 2 // scene marker for non-commercial segments
			}
			sb.WriteString(fmt.Sprintf("%.2f\t%.2f\t%d\n", seg.StartTime, seg.EndTime, actionType))
		}
	}

	return sb.String()
}

// sanitizeFilename removes characters that are not safe for filenames
func sanitizeFilename(name string) string {
	if name == "" {
		return "recording"
	}

	// Replace common unsafe characters
	replacer := strings.NewReplacer(
		"/", "_",
		"\\", "_",
		":", "_",
		"*", "_",
		"?", "",
		"\"", "",
		"<", "",
		">", "",
		"|", "_",
	)
	result := replacer.Replace(name)

	// Trim spaces and dots from edges
	result = strings.TrimSpace(result)
	result = strings.Trim(result, ".")

	if result == "" {
		return "recording"
	}
	return result
}

// contains checks if a string slice contains a specific value
func contains(slice []string, val string) bool {
	for _, s := range slice {
		if s == val {
			return true
		}
	}
	return false
}
