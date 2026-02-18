package api

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/scheduler"
)

// ============ Scheduler API (Admin Only) ============

// listScheduledTasks returns all scheduled tasks with their current status.
// GET /api/scheduler/tasks
func (s *Server) listScheduledTasks(c *gin.Context) {
	if s.taskScheduler == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Scheduler not available"})
		return
	}

	tasks := s.taskScheduler.ListTasks()
	c.JSON(http.StatusOK, gin.H{
		"tasks": tasks,
		"count": len(tasks),
	})
}

// getScheduledTask returns a single task with its full run history.
// GET /api/scheduler/tasks/:id
func (s *Server) getScheduledTask(c *gin.Context) {
	if s.taskScheduler == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Scheduler not available"})
		return
	}

	id := c.Param("id")
	task, err := s.taskScheduler.GetTask(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, task)
}

// updateScheduledTask updates a task's configuration.
// PUT /api/scheduler/tasks/:id
func (s *Server) updateScheduledTask(c *gin.Context) {
	if s.taskScheduler == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Scheduler not available"})
		return
	}

	id := c.Param("id")

	var req struct {
		Schedule *string `json:"schedule"`
		Enabled  *bool   `json:"enabled"`
		Timeout  *int    `json:"timeout"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get the current task to use as defaults.
	current, err := s.taskScheduler.GetTask(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	cfg := scheduler.TaskConfig{
		Schedule: current.Schedule,
		Enabled:  current.Enabled,
		Timeout:  current.Timeout,
	}

	if req.Schedule != nil {
		cfg.Schedule = *req.Schedule
	}
	if req.Enabled != nil {
		cfg.Enabled = *req.Enabled
	}
	if req.Timeout != nil {
		cfg.Timeout = *req.Timeout
	}

	if err := s.taskScheduler.UpdateTaskConfig(id, cfg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Persist the updated configs.
	s.persistSchedulerConfig()

	// Return the updated task.
	updated, _ := s.taskScheduler.GetTask(id)
	c.JSON(http.StatusOK, updated)
}

// triggerScheduledTask triggers immediate execution of a task.
// POST /api/scheduler/tasks/:id/run
func (s *Server) triggerScheduledTask(c *gin.Context) {
	if s.taskScheduler == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Scheduler not available"})
		return
	}

	id := c.Param("id")
	if err := s.taskScheduler.TriggerTask(id); err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusAccepted, gin.H{
		"message": "Task triggered",
		"taskId":  id,
	})
}

// getSchedulerHistory returns recent task execution history across all tasks.
// GET /api/scheduler/history
func (s *Server) getSchedulerHistory(c *gin.Context) {
	if s.taskScheduler == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Scheduler not available"})
		return
	}

	limit := 50
	if l := c.Query("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 {
			limit = v
		}
	}

	history := s.taskScheduler.RecentHistory(limit)
	c.JSON(http.StatusOK, gin.H{
		"history": history,
		"count":   len(history),
	})
}

// ============ Scheduler Config Persistence ============

const schedulerSettingKey = "scheduler_config"

// persistSchedulerConfig serialises all task configs to JSON and saves them
// in the settings table so they survive server restarts.
func (s *Server) persistSchedulerConfig() {
	if s.taskScheduler == nil {
		return
	}

	configs := s.taskScheduler.GetAllConfigs()
	data, err := json.Marshal(configs)
	if err != nil {
		logger.Warnf("Failed to marshal scheduler config: %v", err)
		return
	}

	s.setSetting(schedulerSettingKey, string(data))
}

// loadSchedulerConfig reads the persisted scheduler configuration from the
// settings table and applies it to the registered tasks. Called during startup
// before the scheduler is started.
func (s *Server) loadSchedulerConfig() {
	if s.taskScheduler == nil {
		return
	}

	jsonStr := s.getSettingString(schedulerSettingKey, "")
	if jsonStr == "" {
		return
	}

	var configs map[string]scheduler.TaskConfig
	if err := json.Unmarshal([]byte(jsonStr), &configs); err != nil {
		logger.Warnf("Failed to parse stored scheduler config: %v", err)
		return
	}

	s.taskScheduler.ApplyConfigs(configs)
	logger.Infof("Scheduler config restored from settings (%d tasks)", len(configs))
}
