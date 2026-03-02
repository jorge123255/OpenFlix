package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ DVR V2: Conflict Resolution ============

// getV2Conflicts lists all conflict groups with resolution suggestions.
// GET /dvr/v2/conflicts
func (s *Server) getV2Conflicts(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")

	var resolveUserID uint
	if !isAdmin {
		resolveUserID = userID
	}

	resolver := dvr.NewConflictResolver(s.db)
	conflicts, err := resolver.ResolveConflicts(resolveUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to detect conflicts: " + err.Error()})
		return
	}

	if conflicts == nil {
		conflicts = []dvr.JobConflictGroup{}
	}

	c.JSON(http.StatusOK, gin.H{
		"conflicts":    conflicts,
		"hasConflicts": len(conflicts) > 0,
		"totalCount":   len(conflicts),
	})
}

// getV2ConflictAlternatives returns alternative airings for a specific job.
// GET /dvr/v2/conflicts/:jobId/alternatives
func (s *Server) getV2ConflictAlternatives(c *gin.Context) {
	jobID, err := strconv.ParseUint(c.Param("jobId"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")

	var job models.DVRJob
	query := s.db.First(&job, uint(jobID))
	if query.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}

	if !isAdmin && job.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	resolver := dvr.NewConflictResolver(s.db)
	alternatives, err := resolver.FindAlternativeAirings(&job)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find alternatives: " + err.Error()})
		return
	}

	if alternatives == nil {
		alternatives = []dvr.AlternativeAiring{}
	}

	c.JSON(http.StatusOK, gin.H{
		"jobId":        job.ID,
		"title":        job.Title,
		"subtitle":     job.Subtitle,
		"alternatives": alternatives,
		"totalCount":   len(alternatives),
	})
}

// resolveV2Conflict resolves a specific conflict by applying an action to a job.
// POST /dvr/v2/conflicts/:jobId/resolve
func (s *Server) resolveV2Conflict(c *gin.Context) {
	jobID, err := strconv.ParseUint(c.Param("jobId"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")

	var job models.DVRJob
	if s.db.First(&job, uint(jobID)).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}

	if !isAdmin && job.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	var req struct {
		Action             string `json:"action" binding:"required"` // "cancel", "reschedule", "keep"
		AlternativeProgramID *uint `json:"alternativeProgramId"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Action != "cancel" && req.Action != "reschedule" && req.Action != "keep" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Action must be one of: cancel, reschedule, keep"})
		return
	}

	if req.Action == "reschedule" && req.AlternativeProgramID == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "alternativeProgramId is required when action is reschedule"})
		return
	}

	resolver := dvr.NewConflictResolver(s.db)
	result, err := resolver.ResolveJob(uint(jobID), req.Action, req.AlternativeProgramID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to resolve conflict: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// autoResolveV2Conflicts automatically resolves all conflicts using
// priority-based logic and alternative airing rescheduling.
// POST /dvr/v2/conflicts/auto-resolve
func (s *Server) autoResolveV2Conflicts(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")

	var resolveUserID uint
	if !isAdmin {
		resolveUserID = userID
	}

	resolver := dvr.NewConflictResolver(s.db)
	result, err := resolver.AutoResolve(resolveUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Auto-resolve failed: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}
