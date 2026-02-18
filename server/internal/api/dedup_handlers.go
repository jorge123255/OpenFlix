package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// ============ DVR V2: Duplicate Detection ============

// getDuplicates lists all jobs flagged as duplicates.
// GET /dvr/v2/duplicates
func (s *Server) getDuplicates(c *gin.Context) {
	if s.recorder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "DVR not enabled"})
		return
	}

	dedup := s.recorder.GetDuplicateDetector()
	if dedup == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "duplicate detector not available"})
		return
	}

	jobs := dedup.GetDuplicateJobs()

	c.JSON(http.StatusOK, gin.H{
		"duplicates": jobs,
		"count":      len(jobs),
	})
}

// checkDuplicate checks whether a specific program would be a duplicate
// if scheduled as a recording.
// GET /dvr/v2/duplicates/check?programId=123&title=...
func (s *Server) checkDuplicate(c *gin.Context) {
	if s.recorder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "DVR not enabled"})
		return
	}

	dedup := s.recorder.GetDuplicateDetector()
	if dedup == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "duplicate detector not available"})
		return
	}

	userID := c.GetUint("userID")

	// Check by programId if provided
	if pidStr := c.Query("programId"); pidStr != "" {
		pid, err := strconv.ParseUint(pidStr, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid programId"})
			return
		}

		isDup, match := dedup.CheckProgramDuplicate(uint(pid), userID)
		result := gin.H{
			"isDuplicate": isDup,
			"programId":   pid,
		}
		if match != nil {
			result["matchType"] = match.MatchType
			if match.MatchedFile != nil {
				result["matchedFileId"] = match.MatchedFile.ID
				result["matchedFileTitle"] = match.MatchedFile.Title
			}
			if match.MatchedJob != nil {
				result["matchedJobId"] = match.MatchedJob.ID
				result["matchedJobTitle"] = match.MatchedJob.Title
				result["matchedJobStatus"] = match.MatchedJob.Status
			}
		}
		c.JSON(http.StatusOK, result)
		return
	}

	// Check by title if provided
	title := c.Query("title")
	if title == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "programId or title is required"})
		return
	}

	files, jobs := dedup.FindDuplicates(title)
	c.JSON(http.StatusOK, gin.H{
		"isDuplicate":  len(files) > 0 || len(jobs) > 0,
		"title":        title,
		"matchedFiles": files,
		"matchedJobs":  jobs,
		"fileCount":    len(files),
		"jobCount":     len(jobs),
	})
}

// overrideDuplicate marks a duplicate job as accepted, allowing it
// to proceed with recording.
// POST /dvr/v2/duplicates/:jobId/override
func (s *Server) overrideDuplicate(c *gin.Context) {
	if s.recorder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "DVR not enabled"})
		return
	}

	dedup := s.recorder.GetDuplicateDetector()
	if dedup == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "duplicate detector not available"})
		return
	}

	jobID, err := strconv.ParseUint(c.Param("jobId"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid job ID"})
		return
	}

	if err := dedup.MarkAsAcceptedDuplicate(uint(jobID)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "duplicate override accepted",
		"jobId":   jobID,
	})
}

// getDuplicateStats returns statistics about duplicate detection.
// GET /dvr/v2/duplicates/stats
func (s *Server) getDuplicateStats(c *gin.Context) {
	if s.recorder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "DVR not enabled"})
		return
	}

	dedup := s.recorder.GetDuplicateDetector()
	if dedup == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "duplicate detector not available"})
		return
	}

	stats := dedup.GetDuplicateStats()
	c.JSON(http.StatusOK, stats)
}
