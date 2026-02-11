package sports

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sort"
	"sync"
	"time"
)

// SportsScoreManager handles live sports scores overlay
type SportsScoreManager struct {
	mu           sync.RWMutex
	games        map[string]*LiveGame    // gameID -> game
	favorites    map[string][]string     // userID -> team codes
	alerts       map[string][]*GameAlert // userID -> alerts
	providers    []ScoreProvider
	updateTicker *time.Ticker
	ctx          context.Context
	cancel       context.CancelFunc
}

// LiveGame represents a game in progress
type LiveGame struct {
	ID            string    `json:"id"`
	Sport         string    `json:"sport"`          // nfl, nba, mlb, nhl, ncaaf, ncaab, soccer
	League        string    `json:"league"`         // NFL, NBA, Premier League, etc.
	Status        string    `json:"status"`         // scheduled, live, final, delayed
	HomeTeam      Team      `json:"home_team"`
	AwayTeam      Team      `json:"away_team"`
	HomeScore     int       `json:"home_score"`
	AwayScore     int       `json:"away_score"`
	Period        string    `json:"period"`         // Q1, 2nd Half, 3rd Period, etc.
	Clock         string    `json:"clock"`          // 4:32, 12:00, etc.
	StartTime     time.Time `json:"start_time"`
	LastUpdated   time.Time `json:"last_updated"`
	IsClose       bool      `json:"is_close"`       // close game alert
	IsRedZone     bool      `json:"is_red_zone"`    // football red zone
	Possession    string    `json:"possession"`     // team code with ball
	BroadcastInfo string    `json:"broadcast_info"` // "ESPN, FOX"
}

// Team represents a sports team
type Team struct {
	Code       string `json:"code"`       // KC, LAL, NYY
	Name       string `json:"name"`       // Chiefs, Lakers, Yankees
	FullName   string `json:"full_name"`  // Kansas City Chiefs
	Logo       string `json:"logo"`       // URL to logo
	Record     string `json:"record"`     // 10-2, 45-30
	Rank       int    `json:"rank"`       // for college sports
	Conference string `json:"conference"` // AFC West, Eastern
}

// GameAlert for notifications
type GameAlert struct {
	GameID    string `json:"game_id"`
	Type      string `json:"type"`      // close_game, score_update, game_start, game_end
	Threshold int    `json:"threshold"` // point difference for close game
	Triggered bool   `json:"triggered"`
}

// OverlayData is the data sent to the client for rendering
type OverlayData struct {
	Games         []*LiveGame `json:"games"`
	LastUpdated   time.Time   `json:"last_updated"`
	FavoriteCount int         `json:"favorite_count"`
}

// ScoreProvider interface for different data sources
type ScoreProvider interface {
	Name() string
	GetLiveGames(ctx context.Context) ([]*LiveGame, error)
	GetSports() []string
}

// NewSportsScoreManager creates a new score manager
func NewSportsScoreManager() *SportsScoreManager {
	ctx, cancel := context.WithCancel(context.Background())

	sm := &SportsScoreManager{
		games:     make(map[string]*LiveGame),
		favorites: make(map[string][]string),
		alerts:    make(map[string][]*GameAlert),
		providers: make([]ScoreProvider, 0),
		ctx:       ctx,
		cancel:    cancel,
	}

	return sm
}

// AddProvider adds a score data provider
func (sm *SportsScoreManager) AddProvider(provider ScoreProvider) {
	sm.providers = append(sm.providers, provider)
}

// Start begins fetching scores
func (sm *SportsScoreManager) Start(updateInterval time.Duration) {
	sm.updateTicker = time.NewTicker(updateInterval)

	// Initial fetch
	go sm.fetchAllScores()

	// Periodic updates
	go func() {
		for {
			select {
			case <-sm.ctx.Done():
				return
			case <-sm.updateTicker.C:
				sm.fetchAllScores()
			}
		}
	}()
}

// Stop halts score fetching
func (sm *SportsScoreManager) Stop() {
	sm.cancel()
	if sm.updateTicker != nil {
		sm.updateTicker.Stop()
	}
}

// fetchAllScores fetches from all providers
func (sm *SportsScoreManager) fetchAllScores() {
	for _, provider := range sm.providers {
		games, err := provider.GetLiveGames(sm.ctx)
		if err != nil {
			continue
		}

		sm.mu.Lock()
		for _, game := range games {
			// Check for close game
			scoreDiff := abs(game.HomeScore - game.AwayScore)
			if game.Status == "live" && scoreDiff <= 7 {
				game.IsClose = true
			}

			sm.games[game.ID] = game
		}
		sm.mu.Unlock()
	}

	// Check alerts
	sm.checkAlerts()
}

// GetLiveGames returns all live games
func (sm *SportsScoreManager) GetLiveGames(sport string) []*LiveGame {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	var games []*LiveGame
	for _, game := range sm.games {
		if sport == "" || sport == "all" || game.Sport == sport {
			if game.Status == "live" || game.Status == "scheduled" {
				games = append(games, game)
			}
		}
	}

	// Sort: live first, then by start time
	sort.Slice(games, func(i, j int) bool {
		if games[i].Status == "live" && games[j].Status != "live" {
			return true
		}
		if games[j].Status == "live" && games[i].Status != "live" {
			return false
		}
		return games[i].StartTime.Before(games[j].StartTime)
	})

	return games
}

// GetFavoriteGames returns games for user's favorite teams
func (sm *SportsScoreManager) GetFavoriteGames(userID string) []*LiveGame {
	sm.mu.RLock()
	favTeams := sm.favorites[userID]
	sm.mu.RUnlock()

	if len(favTeams) == 0 {
		return nil
	}

	teamSet := make(map[string]bool)
	for _, team := range favTeams {
		teamSet[team] = true
	}

	sm.mu.RLock()
	defer sm.mu.RUnlock()

	var games []*LiveGame
	for _, game := range sm.games {
		if teamSet[game.HomeTeam.Code] || teamSet[game.AwayTeam.Code] {
			games = append(games, game)
		}
	}

	return games
}

// SetFavorites sets a user's favorite teams
func (sm *SportsScoreManager) SetFavorites(userID string, teamCodes []string) {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.favorites[userID] = teamCodes
}

// GetFavorites returns a user's favorite teams
func (sm *SportsScoreManager) GetFavorites(userID string) []string {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	return sm.favorites[userID]
}

// AddAlert adds a game alert for a user
func (sm *SportsScoreManager) AddAlert(userID, gameID, alertType string, threshold int) {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	alert := &GameAlert{
		GameID:    gameID,
		Type:      alertType,
		Threshold: threshold,
		Triggered: false,
	}

	sm.alerts[userID] = append(sm.alerts[userID], alert)
}

// checkAlerts checks and triggers alerts
func (sm *SportsScoreManager) checkAlerts() {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	for userID, alerts := range sm.alerts {
		for _, alert := range alerts {
			if alert.Triggered {
				continue
			}

			game, exists := sm.games[alert.GameID]
			if !exists {
				continue
			}

			switch alert.Type {
			case "close_game":
				diff := abs(game.HomeScore - game.AwayScore)
				if game.Status == "live" && diff <= alert.Threshold {
					alert.Triggered = true
					_ = userID // Will use for notification
				}
			case "game_start":
				if game.Status == "live" {
					alert.Triggered = true
				}
			case "game_end":
				if game.Status == "final" {
					alert.Triggered = true
				}
			}
		}
	}
}

// GetOverlayData returns formatted data for the on-screen overlay
func (sm *SportsScoreManager) GetOverlayData(userID string, maxGames int) *OverlayData {
	// Get favorites first
	favGames := sm.GetFavoriteGames(userID)

	// Then other live games
	allGames := sm.GetLiveGames("all")

	// Combine: favorites first, then others (no duplicates)
	seenIDs := make(map[string]bool)
	var orderedGames []*LiveGame

	for _, g := range favGames {
		if !seenIDs[g.ID] {
			seenIDs[g.ID] = true
			orderedGames = append(orderedGames, g)
		}
	}

	for _, g := range allGames {
		if !seenIDs[g.ID] && len(orderedGames) < maxGames {
			seenIDs[g.ID] = true
			orderedGames = append(orderedGames, g)
		}
	}

	// Limit
	if len(orderedGames) > maxGames {
		orderedGames = orderedGames[:maxGames]
	}

	return &OverlayData{
		Games:         orderedGames,
		LastUpdated:   time.Now(),
		FavoriteCount: len(favGames),
	}
}

// Stats returns manager statistics
func (sm *SportsScoreManager) Stats() map[string]interface{} {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	liveCount := 0
	for _, g := range sm.games {
		if g.Status == "live" {
			liveCount++
		}
	}

	return map[string]interface{}{
		"total_games":   len(sm.games),
		"live_games":    liveCount,
		"providers":     len(sm.providers),
		"users_tracked": len(sm.favorites),
	}
}

// Helper
func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

// ESPNProvider implements ScoreProvider for ESPN API (FREE, no API key!)
type ESPNProvider struct {
	client  *http.Client
	baseURL string
}

// NewESPNProvider creates an ESPN score provider
func NewESPNProvider() *ESPNProvider {
	return &ESPNProvider{
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
		baseURL: "https://site.api.espn.com/apis/site/v2/sports",
	}
}

func (e *ESPNProvider) Name() string {
	return "ESPN"
}

func (e *ESPNProvider) GetSports() []string {
	return []string{"nfl", "nba", "mlb", "nhl", "ncaaf", "ncaab"}
}

func (e *ESPNProvider) GetLiveGames(ctx context.Context) ([]*LiveGame, error) {
	var allGames []*LiveGame

	sports := map[string]string{
		"nfl":   "football/nfl",
		"nba":   "basketball/nba",
		"mlb":   "baseball/mlb",
		"nhl":   "hockey/nhl",
		"ncaaf": "football/college-football",
		"ncaab": "basketball/mens-college-basketball",
	}

	for sport, path := range sports {
		url := fmt.Sprintf("%s/%s/scoreboard", e.baseURL, path)

		req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
		if err != nil {
			continue
		}

		resp, err := e.client.Do(req)
		if err != nil {
			continue
		}

		if resp.StatusCode == http.StatusOK {
			games := e.parseESPNResponse(resp.Body, sport)
			allGames = append(allGames, games...)
		}
		resp.Body.Close()
	}

	return allGames, nil
}

func (e *ESPNProvider) parseESPNResponse(body io.Reader, sport string) []*LiveGame {
	var result struct {
		Events []struct {
			ID     string `json:"id"`
			Name   string `json:"name"`
			Status struct {
				Type struct {
					State       string `json:"state"`
					Description string `json:"description"`
				} `json:"type"`
				Period       int    `json:"period"`
				DisplayClock string `json:"displayClock"`
			} `json:"status"`
			Competitions []struct {
				Competitors []struct {
					ID   string `json:"id"`
					Team struct {
						Abbreviation     string `json:"abbreviation"`
						DisplayName      string `json:"displayName"`
						ShortDisplayName string `json:"shortDisplayName"`
						Logo             string `json:"logo"`
					} `json:"team"`
					Score    string `json:"score"`
					HomeAway string `json:"homeAway"`
					Records  []struct {
						Summary string `json:"summary"`
					} `json:"records"`
				} `json:"competitors"`
				Broadcasts []struct {
					Names []string `json:"names"`
				} `json:"broadcasts"`
			} `json:"competitions"`
			Date string `json:"date"`
		} `json:"events"`
	}

	if err := json.NewDecoder(body).Decode(&result); err != nil {
		return nil
	}

	var games []*LiveGame
	for _, event := range result.Events {
		if len(event.Competitions) == 0 || len(event.Competitions[0].Competitors) < 2 {
			continue
		}

		comp := event.Competitions[0]

		var home, away Team
		var homeScore, awayScore int

		for _, team := range comp.Competitors {
			t := Team{
				Code:     team.Team.Abbreviation,
				Name:     team.Team.ShortDisplayName,
				FullName: team.Team.DisplayName,
				Logo:     team.Team.Logo,
			}
			if len(team.Records) > 0 {
				t.Record = team.Records[0].Summary
			}

			score := 0
			fmt.Sscanf(team.Score, "%d", &score)

			if team.HomeAway == "home" {
				home = t
				homeScore = score
			} else {
				away = t
				awayScore = score
			}
		}

		status := "scheduled"
		switch event.Status.Type.State {
		case "in":
			status = "live"
		case "post":
			status = "final"
		case "pre":
			status = "scheduled"
		}

		var broadcasts []string
		for _, b := range comp.Broadcasts {
			broadcasts = append(broadcasts, b.Names...)
		}

		startTime, _ := time.Parse(time.RFC3339, event.Date)

		game := &LiveGame{
			ID:            event.ID,
			Sport:         sport,
			League:        sport,
			Status:        status,
			HomeTeam:      home,
			AwayTeam:      away,
			HomeScore:     homeScore,
			AwayScore:     awayScore,
			Period:        event.Status.Type.Description,
			Clock:         event.Status.DisplayClock,
			StartTime:     startTime,
			LastUpdated:   time.Now(),
			BroadcastInfo: fmt.Sprintf("%v", broadcasts),
		}

		games = append(games, game)
	}

	return games
}
