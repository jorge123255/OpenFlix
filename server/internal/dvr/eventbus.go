package dvr

import (
	"encoding/json"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/openflix/openflix-server/internal/logger"
)

const (
	// Time allowed to write a message to the peer.
	wsWriteWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer.
	wsPongWait = 60 * time.Second

	// Send pings to peer with this period. Must be less than pongWait.
	wsPingPeriod = (wsPongWait * 9) / 10

	// Maximum message size allowed from peer.
	wsMaxMessageSize = 4096
)

var wsUpgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for local server
	},
}

// WebSocketHub manages WebSocket clients and bridges the EventBus to them.
type WebSocketHub struct {
	clients    map[*wsClient]bool
	broadcast  chan []byte
	register   chan *wsClient
	unregister chan *wsClient
	mu         sync.RWMutex
	eventBus   *EventBus
}

// wsClient represents a single WebSocket connection.
type wsClient struct {
	hub     *WebSocketHub
	conn    *websocket.Conn
	send    chan []byte
	filters []string // optional event type filters
}

// WSMessage is the envelope sent over the WebSocket to clients.
type WSMessage struct {
	Type      string      `json:"type"`
	Timestamp time.Time   `json:"timestamp"`
	Data      interface{} `json:"data"`
}

// NewWebSocketHub creates a new WebSocketHub that bridges events from the
// given EventBus to all connected WebSocket clients.
func NewWebSocketHub(eventBus *EventBus) *WebSocketHub {
	return &WebSocketHub{
		clients:    make(map[*wsClient]bool),
		broadcast:  make(chan []byte, 256),
		register:   make(chan *wsClient),
		unregister: make(chan *wsClient),
		eventBus:   eventBus,
	}
}

// Run starts the hub's main event loop. It should be called in its own goroutine.
// It listens for client registration/unregistration, broadcasts messages to all
// connected clients, and subscribes to the underlying EventBus to forward DVR
// events over WebSocket.
func (h *WebSocketHub) Run() {
	// Subscribe to the EventBus so we receive all DVR events
	const subscriberID = "websocket-hub"
	eventCh := h.eventBus.Subscribe(subscriberID)
	defer h.eventBus.Unsubscribe(subscriberID)

	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()
			logger.Infof("WebSocket client connected (total: %d)", h.ClientCount())

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
			h.mu.Unlock()
			logger.Infof("WebSocket client disconnected (total: %d)", h.ClientCount())

		case message := <-h.broadcast:
			h.mu.RLock()
			for client := range h.clients {
				select {
				case client.send <- message:
				default:
					// Client buffer full; drop it
					h.mu.RUnlock()
					h.mu.Lock()
					delete(h.clients, client)
					close(client.send)
					h.mu.Unlock()
					h.mu.RLock()
				}
			}
			h.mu.RUnlock()

		case rawEvent, ok := <-eventCh:
			if !ok {
				return
			}
			// Forward the raw event JSON to all WebSocket clients
			h.mu.RLock()
			for client := range h.clients {
				if client.matchesFilters(rawEvent) {
					select {
					case client.send <- rawEvent:
					default:
						// Client buffer full; drop it
					}
				}
			}
			h.mu.RUnlock()
		}
	}
}

// HandleWebSocket upgrades an HTTP connection to a WebSocket and registers
// the resulting client with the hub.
func (h *WebSocketHub) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := wsUpgrader.Upgrade(w, r, nil)
	if err != nil {
		logger.Errorf("WebSocket upgrade failed: %v", err)
		return
	}

	client := &wsClient{
		hub:  h,
		conn: conn,
		send: make(chan []byte, 256),
	}
	h.register <- client

	// Send welcome message
	welcome := WSMessage{
		Type:      "connected",
		Timestamp: time.Now(),
		Data: map[string]interface{}{
			"message":     "DVR WebSocket event stream connected",
			"clientCount": h.ClientCount(),
		},
	}
	if data, err := json.Marshal(welcome); err == nil {
		client.send <- data
	}

	// Start read and write pumps in separate goroutines
	go client.writePump()
	go client.readPump()
}

// BroadcastEvent sends an event with the given type and data to all connected
// WebSocket clients.
func (h *WebSocketHub) BroadcastEvent(eventType string, data interface{}) {
	msg := WSMessage{
		Type:      eventType,
		Timestamp: time.Now(),
		Data:      data,
	}
	encoded, err := json.Marshal(msg)
	if err != nil {
		logger.Errorf("Failed to marshal WebSocket broadcast event: %v", err)
		return
	}

	h.broadcast <- encoded
}

// ClientCount returns the number of currently connected WebSocket clients.
func (h *WebSocketHub) ClientCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// writePump pumps messages from the hub to the WebSocket connection.
// A goroutine running writePump is started for each connection.
func (c *wsClient) writePump() {
	ticker := time.NewTicker(wsPingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(wsWriteWait))
			if !ok {
				// The hub closed the channel
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(wsWriteWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// readPump pumps messages from the WebSocket connection to the hub.
// It reads filter subscription messages from the client and detects disconnects.
func (c *wsClient) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(wsMaxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(wsPongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(wsPongWait))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				logger.Warnf("WebSocket unexpected close: %v", err)
			}
			return
		}

		// Try to parse as a filter subscription message
		var filterMsg struct {
			Action  string   `json:"action"`
			Filters []string `json:"filters"`
		}
		if json.Unmarshal(message, &filterMsg) == nil && filterMsg.Action == "subscribe" {
			c.filters = filterMsg.Filters
			logger.Infof("WebSocket client updated filters: %v", c.filters)
		}
	}
}

// matchesFilters returns true if the raw event JSON matches the client's
// filter list. If the client has no filters set, all events match.
func (c *wsClient) matchesFilters(rawEvent []byte) bool {
	if len(c.filters) == 0 {
		return true
	}

	// Parse just the "type" field from the event
	var envelope struct {
		Type string `json:"type"`
	}
	if err := json.Unmarshal(rawEvent, &envelope); err != nil {
		return true // On parse error, deliver the event anyway
	}

	for _, f := range c.filters {
		if f == envelope.Type {
			return true
		}
	}
	return false
}
