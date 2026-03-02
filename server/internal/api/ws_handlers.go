package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/logger"
)

// wsHub is the package-level WebSocket hub instance, initialized by InitWebSocketHub.
var wsHub *dvr.WebSocketHub

// InitWebSocketHub creates and starts the WebSocket hub for DVR events.
// It should be called once during server initialization after the recorder
// (and its EventBus) is available. Returns the hub so callers can reference it.
func InitWebSocketHub(eventBus *dvr.EventBus) *dvr.WebSocketHub {
	if eventBus == nil {
		logger.Warn("Cannot initialize WebSocket hub: EventBus is nil")
		return nil
	}

	hub := dvr.NewWebSocketHub(eventBus)
	wsHub = hub
	go hub.Run()
	logger.Info("DVR WebSocket event hub started")
	return hub
}

// dvrEventsWS handles GET /dvr/v2/events/ws
// It upgrades the HTTP connection to a WebSocket and streams real-time DVR events.
func (s *Server) dvrEventsWS(c *gin.Context) {
	if wsHub == nil {
		// Try to lazily initialize from the recorder's event bus
		if s.recorder != nil {
			if eb := s.recorder.GetEventBus(); eb != nil {
				InitWebSocketHub(eb)
			}
		}
	}

	if wsHub == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "WebSocket hub not available. DVR may not be enabled.",
		})
		return
	}

	wsHub.HandleWebSocket(c.Writer, c.Request)
}
