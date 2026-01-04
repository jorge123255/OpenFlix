package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

// WatchParty represents an active watch party session
type WatchParty struct {
	ID          string              `json:"id"`
	Name        string              `json:"name"`
	HostID      uint                `json:"hostId"`
	HostName    string              `json:"hostName"`
	MediaKey    string              `json:"mediaKey"`
	MediaTitle  string              `json:"mediaTitle"`
	MediaType   string              `json:"mediaType"`
	CreatedAt   time.Time           `json:"createdAt"`
	Participants map[string]*Participant `json:"-"`
	State       *PlaybackState      `json:"state"`
	mutex       sync.RWMutex
}

// Participant represents a user in a watch party
type Participant struct {
	ID       string          `json:"id"`
	UserID   uint            `json:"userId"`
	UserName string          `json:"userName"`
	IsHost   bool            `json:"isHost"`
	Conn     *websocket.Conn `json:"-"`
	JoinedAt time.Time       `json:"joinedAt"`
}

// PlaybackState represents the synchronized playback state
type PlaybackState struct {
	Playing    bool    `json:"playing"`
	Position   float64 `json:"position"` // seconds
	Speed      float64 `json:"speed"`
	UpdatedAt  int64   `json:"updatedAt"` // Unix timestamp
	UpdatedBy  string  `json:"updatedBy"` // User who made the update
}

// WatchPartyMessage represents a message in the watch party
type WatchPartyMessage struct {
	Type    string      `json:"type"`
	Payload interface{} `json:"payload,omitempty"`
	From    string      `json:"from,omitempty"`
}

// WatchPartyManager manages all active watch parties
type WatchPartyManager struct {
	parties map[string]*WatchParty
	mutex   sync.RWMutex
}

var (
	partyManager = &WatchPartyManager{
		parties: make(map[string]*WatchParty),
	}

	upgrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true // Allow all origins for now
		},
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}
)

// RegisterWatchPartyRoutes adds watch party routes to the router
func (s *Server) RegisterWatchPartyRoutes(r *gin.Engine) {
	party := r.Group("/watchparty")
	party.Use(s.authRequired())
	{
		// Create a new watch party
		party.POST("", s.createWatchParty)
		// List active parties
		party.GET("", s.listWatchParties)
		// Get party details
		party.GET("/:id", s.getWatchParty)
		// Join party via WebSocket
		party.GET("/:id/ws", s.joinWatchPartyWS)
		// Leave party
		party.POST("/:id/leave", s.leaveWatchParty)
		// Close party (host only)
		party.DELETE("/:id", s.closeWatchParty)
	}
}

// createWatchParty creates a new watch party
func (s *Server) createWatchParty(c *gin.Context) {
	userID, _ := c.Get("userID")
	claims, _ := c.Get("claims")

	var req struct {
		Name       string `json:"name"`
		MediaKey   string `json:"mediaKey" binding:"required"`
		MediaTitle string `json:"mediaTitle"`
		MediaType  string `json:"mediaType"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user name from claims
	userName := "Unknown"
	if claimsMap, ok := claims.(map[string]interface{}); ok {
		if name, ok := claimsMap["username"].(string); ok {
			userName = name
		}
	}

	party := &WatchParty{
		ID:           uuid.New().String()[:8],
		Name:         req.Name,
		HostID:       userID.(uint),
		HostName:     userName,
		MediaKey:     req.MediaKey,
		MediaTitle:   req.MediaTitle,
		MediaType:    req.MediaType,
		CreatedAt:    time.Now(),
		Participants: make(map[string]*Participant),
		State: &PlaybackState{
			Playing:   false,
			Position:  0,
			Speed:     1.0,
			UpdatedAt: time.Now().Unix(),
		},
	}

	partyManager.mutex.Lock()
	partyManager.parties[party.ID] = party
	partyManager.mutex.Unlock()

	c.JSON(http.StatusCreated, gin.H{
		"party":   party,
		"joinUrl": fmt.Sprintf("/watchparty/%s/join", party.ID),
	})
}

// listWatchParties returns all active watch parties
func (s *Server) listWatchParties(c *gin.Context) {
	partyManager.mutex.RLock()
	defer partyManager.mutex.RUnlock()

	parties := make([]gin.H, 0, len(partyManager.parties))
	for _, party := range partyManager.parties {
		party.mutex.RLock()
		parties = append(parties, gin.H{
			"id":           party.ID,
			"name":         party.Name,
			"hostName":     party.HostName,
			"mediaTitle":   party.MediaTitle,
			"participants": len(party.Participants),
			"createdAt":    party.CreatedAt,
		})
		party.mutex.RUnlock()
	}

	c.JSON(http.StatusOK, gin.H{"parties": parties})
}

// getWatchParty returns details about a specific party
func (s *Server) getWatchParty(c *gin.Context) {
	partyID := c.Param("id")

	partyManager.mutex.RLock()
	party, exists := partyManager.parties[partyID]
	partyManager.mutex.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Party not found"})
		return
	}

	party.mutex.RLock()
	defer party.mutex.RUnlock()

	participants := make([]gin.H, 0, len(party.Participants))
	for _, p := range party.Participants {
		participants = append(participants, gin.H{
			"id":       p.ID,
			"userName": p.UserName,
			"isHost":   p.IsHost,
			"joinedAt": p.JoinedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"party": gin.H{
			"id":           party.ID,
			"name":         party.Name,
			"hostName":     party.HostName,
			"mediaKey":     party.MediaKey,
			"mediaTitle":   party.MediaTitle,
			"mediaType":    party.MediaType,
			"createdAt":    party.CreatedAt,
			"state":        party.State,
			"participants": participants,
		},
	})
}

// joinWatchPartyWS handles WebSocket connections to a watch party
func (s *Server) joinWatchPartyWS(c *gin.Context) {
	partyID := c.Param("id")
	userID, _ := c.Get("userID")
	claims, _ := c.Get("claims")

	partyManager.mutex.RLock()
	party, exists := partyManager.parties[partyID]
	partyManager.mutex.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Party not found"})
		return
	}

	// Upgrade to WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}

	// Get user name from claims
	userName := "Guest"
	if claimsMap, ok := claims.(map[string]interface{}); ok {
		if name, ok := claimsMap["username"].(string); ok {
			userName = name
		}
	}

	participantID := uuid.New().String()[:8]
	participant := &Participant{
		ID:       participantID,
		UserID:   userID.(uint),
		UserName: userName,
		IsHost:   party.HostID == userID.(uint),
		Conn:     conn,
		JoinedAt: time.Now(),
	}

	// Add participant to party
	party.mutex.Lock()
	party.Participants[participantID] = participant
	party.mutex.Unlock()

	// Notify others that someone joined
	broadcastToParty(party, &WatchPartyMessage{
		Type: "participant_joined",
		Payload: gin.H{
			"id":       participant.ID,
			"userName": participant.UserName,
			"isHost":   participant.IsHost,
		},
	}, participantID)

	// Send current state to the new participant
	party.mutex.RLock()
	currentState := party.State
	party.mutex.RUnlock()

	sendToParticipant(conn, &WatchPartyMessage{
		Type:    "state_sync",
		Payload: currentState,
	})

	// Handle incoming messages
	go handleParticipantMessages(party, participant)
}

// handleParticipantMessages handles messages from a participant
func handleParticipantMessages(party *WatchParty, participant *Participant) {
	defer func() {
		// Remove participant when they disconnect
		party.mutex.Lock()
		delete(party.Participants, participant.ID)
		party.mutex.Unlock()

		participant.Conn.Close()

		// Notify others
		broadcastToParty(party, &WatchPartyMessage{
			Type: "participant_left",
			Payload: gin.H{
				"id":       participant.ID,
				"userName": participant.UserName,
			},
		}, participant.ID)

		// If host leaves, close the party
		if participant.IsHost {
			partyManager.mutex.Lock()
			delete(partyManager.parties, party.ID)
			partyManager.mutex.Unlock()

			broadcastToParty(party, &WatchPartyMessage{
				Type: "party_closed",
				Payload: gin.H{
					"reason": "Host left the party",
				},
			}, "")
		}
	}()

	for {
		_, message, err := participant.Conn.ReadMessage()
		if err != nil {
			break
		}

		var msg WatchPartyMessage
		if err := json.Unmarshal(message, &msg); err != nil {
			continue
		}

		handlePartyMessage(party, participant, &msg)
	}
}

// handlePartyMessage processes a message from a participant
func handlePartyMessage(party *WatchParty, participant *Participant, msg *WatchPartyMessage) {
	switch msg.Type {
	case "play":
		if participant.IsHost || allowGuestControl(party) {
			party.mutex.Lock()
			party.State.Playing = true
			party.State.UpdatedAt = time.Now().Unix()
			party.State.UpdatedBy = participant.UserName
			party.mutex.Unlock()

			broadcastToParty(party, &WatchPartyMessage{
				Type:    "state_update",
				Payload: party.State,
				From:    participant.UserName,
			}, "")
		}

	case "pause":
		if participant.IsHost || allowGuestControl(party) {
			party.mutex.Lock()
			party.State.Playing = false
			party.State.UpdatedAt = time.Now().Unix()
			party.State.UpdatedBy = participant.UserName
			party.mutex.Unlock()

			broadcastToParty(party, &WatchPartyMessage{
				Type:    "state_update",
				Payload: party.State,
				From:    participant.UserName,
			}, "")
		}

	case "seek":
		if participant.IsHost || allowGuestControl(party) {
			if payload, ok := msg.Payload.(map[string]interface{}); ok {
				if position, ok := payload["position"].(float64); ok {
					party.mutex.Lock()
					party.State.Position = position
					party.State.UpdatedAt = time.Now().Unix()
					party.State.UpdatedBy = participant.UserName
					party.mutex.Unlock()

					broadcastToParty(party, &WatchPartyMessage{
						Type:    "state_update",
						Payload: party.State,
						From:    participant.UserName,
					}, "")
				}
			}
		}

	case "sync_request":
		// A participant is requesting current state
		party.mutex.RLock()
		currentState := party.State
		party.mutex.RUnlock()

		sendToParticipant(participant.Conn, &WatchPartyMessage{
			Type:    "state_sync",
			Payload: currentState,
		})

	case "chat":
		// Broadcast chat message
		if payload, ok := msg.Payload.(map[string]interface{}); ok {
			if text, ok := payload["text"].(string); ok {
				broadcastToParty(party, &WatchPartyMessage{
					Type: "chat",
					Payload: gin.H{
						"text":   text,
						"from":   participant.UserName,
						"sentAt": time.Now().Unix(),
					},
				}, "")
			}
		}

	case "reaction":
		// Broadcast reaction (emoji)
		if payload, ok := msg.Payload.(map[string]interface{}); ok {
			if emoji, ok := payload["emoji"].(string); ok {
				broadcastToParty(party, &WatchPartyMessage{
					Type: "reaction",
					Payload: gin.H{
						"emoji": emoji,
						"from":  participant.UserName,
					},
				}, "")
			}
		}
	}
}

// allowGuestControl returns whether guests can control playback
func allowGuestControl(party *WatchParty) bool {
	// For now, only host can control. Could be a setting.
	return false
}

// broadcastToParty sends a message to all participants except the excluded one
func broadcastToParty(party *WatchParty, msg *WatchPartyMessage, excludeID string) {
	data, err := json.Marshal(msg)
	if err != nil {
		return
	}

	party.mutex.RLock()
	defer party.mutex.RUnlock()

	for id, participant := range party.Participants {
		if id != excludeID {
			participant.Conn.WriteMessage(websocket.TextMessage, data)
		}
	}
}

// sendToParticipant sends a message to a specific participant
func sendToParticipant(conn *websocket.Conn, msg *WatchPartyMessage) {
	data, err := json.Marshal(msg)
	if err != nil {
		return
	}
	conn.WriteMessage(websocket.TextMessage, data)
}

// leaveWatchParty allows a participant to leave a party
func (s *Server) leaveWatchParty(c *gin.Context) {
	// This is handled by WebSocket disconnection
	c.JSON(http.StatusOK, gin.H{"message": "Left party"})
}

// closeWatchParty closes a watch party (host only)
func (s *Server) closeWatchParty(c *gin.Context) {
	partyID := c.Param("id")
	userID, _ := c.Get("userID")

	partyManager.mutex.Lock()
	party, exists := partyManager.parties[partyID]

	if !exists {
		partyManager.mutex.Unlock()
		c.JSON(http.StatusNotFound, gin.H{"error": "Party not found"})
		return
	}

	if party.HostID != userID.(uint) {
		partyManager.mutex.Unlock()
		c.JSON(http.StatusForbidden, gin.H{"error": "Only host can close the party"})
		return
	}

	delete(partyManager.parties, partyID)
	partyManager.mutex.Unlock()

	// Notify all participants
	broadcastToParty(party, &WatchPartyMessage{
		Type: "party_closed",
		Payload: gin.H{
			"reason": "Host closed the party",
		},
	}, "")

	// Close all connections
	party.mutex.Lock()
	for _, p := range party.Participants {
		p.Conn.Close()
	}
	party.mutex.Unlock()

	c.JSON(http.StatusOK, gin.H{"message": "Party closed"})
}
