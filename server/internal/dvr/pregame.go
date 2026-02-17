package dvr

import (
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// PrePostGameDetector finds pre-game and post-game shows surrounding a sports event
type PrePostGameDetector struct {
	db *gorm.DB
}

// NewPrePostGameDetector creates a new detector instance
func NewPrePostGameDetector(db *gorm.DB) *PrePostGameDetector {
	return &PrePostGameDetector{db: db}
}

// preGameKeywords are title keywords that indicate a pre-game show
var preGameKeywords = []string{
	"pre-game", "pregame", "pre game",
	"countdown", "preview",
	"kickoff", "kick-off", "kick off",
	"tip-off", "tipoff", "tip off",
	"first pitch",
	"puck drop",
	"warmup", "warm-up", "warm up",
	"tailgate",
	"pre-match", "prematch", "pre match",
	"buildup", "build-up", "build up",
	"pregame show", "pre-game show",
}

// postGameKeywords are title keywords that indicate a post-game show
var postGameKeywords = []string{
	"post-game", "postgame", "post game",
	"wrap-up", "wrapup", "wrap up",
	"highlights",
	"analysis",
	"recap",
	"post-match", "postmatch", "post match",
	"overtime show",
	"after the game",
	"final score",
	"postgame show", "post-game show",
	"extra time",
	"reaction",
}

// getSportsKeywords returns sport-specific keywords for a given league
func getSportsKeywords(league string) []string {
	switch strings.ToUpper(league) {
	case "NFL":
		return []string{"football", "nfl", "gridiron", "touchdown"}
	case "NBA":
		return []string{"basketball", "nba", "hoops", "court"}
	case "MLB":
		return []string{"baseball", "mlb", "diamond"}
	case "NHL":
		return []string{"hockey", "nhl", "ice"}
	case "MLS", "SOCCER":
		return []string{"soccer", "mls", "football", "pitch"}
	case "NCAA", "COLLEGE":
		return []string{"college", "ncaa", "university"}
	default:
		return nil
	}
}

// candidate holds a program and its match score for ranking
type candidate struct {
	program *models.Program
	score   int
}

// FindPreGame searches EPG for a pre-game show on the same channel before the main event.
// It looks for programs ending at or before gameStart within the windowMinutes range,
// scoring candidates by keyword and team/league relevance.
// Returns nil if no suitable pre-game show is found.
func (d *PrePostGameDetector) FindPreGame(channelID string, gameStart time.Time, teamName string, league string, windowMinutes int) *models.Program {
	if windowMinutes <= 0 {
		windowMinutes = 30
	}

	windowStart := gameStart.Add(-time.Duration(windowMinutes) * time.Minute)

	var programs []models.Program
	d.db.Where("channel_id = ? AND end <= ? AND start >= ?",
		channelID, gameStart, windowStart).
		Order("start DESC").
		Find(&programs)

	if len(programs) == 0 {
		return nil
	}

	best := d.scorePreGameCandidates(programs, teamName, league)
	if best == nil {
		return nil
	}

	logger.Log.WithFields(map[string]interface{}{
		"channel_id":  channelID,
		"game_start":  gameStart.Format("2006-01-02 15:04"),
		"team":        teamName,
		"pregame":     best.Title,
		"pregame_start": best.Start.Format("2006-01-02 15:04"),
	}).Info("Found pre-game show for sports event")

	return best
}

// FindPostGame searches EPG for a post-game show on the same channel after the main event.
// It looks for programs starting at or after gameEnd within the windowMinutes range,
// scoring candidates by keyword and team/league relevance.
// Returns nil if no suitable post-game show is found.
func (d *PrePostGameDetector) FindPostGame(channelID string, gameEnd time.Time, teamName string, league string, windowMinutes int) *models.Program {
	if windowMinutes <= 0 {
		windowMinutes = 60
	}

	windowEnd := gameEnd.Add(time.Duration(windowMinutes) * time.Minute)

	var programs []models.Program
	d.db.Where("channel_id = ? AND start >= ? AND start < ?",
		channelID, gameEnd, windowEnd).
		Order("start ASC").
		Find(&programs)

	if len(programs) == 0 {
		return nil
	}

	best := d.scorePostGameCandidates(programs, teamName, league)
	if best == nil {
		return nil
	}

	logger.Log.WithFields(map[string]interface{}{
		"channel_id":   channelID,
		"game_end":     gameEnd.Format("2006-01-02 15:04"),
		"team":         teamName,
		"postgame":     best.Title,
		"postgame_start": best.Start.Format("2006-01-02 15:04"),
	}).Info("Found post-game show for sports event")

	return best
}

// scorePreGameCandidates evaluates programs for pre-game relevance and returns the best match
func (d *PrePostGameDetector) scorePreGameCandidates(programs []models.Program, teamName string, league string) *models.Program {
	var best *candidate

	for i := range programs {
		prog := &programs[i]
		score := d.scoreCandidate(prog, teamName, league, preGameKeywords)
		if score <= 0 {
			continue
		}

		if best == nil || score > best.score {
			best = &candidate{program: prog, score: score}
		}
	}

	if best == nil {
		return nil
	}
	return best.program
}

// scorePostGameCandidates evaluates programs for post-game relevance and returns the best match
func (d *PrePostGameDetector) scorePostGameCandidates(programs []models.Program, teamName string, league string) *models.Program {
	var best *candidate

	for i := range programs {
		prog := &programs[i]
		score := d.scoreCandidate(prog, teamName, league, postGameKeywords)
		if score <= 0 {
			continue
		}

		if best == nil || score > best.score {
			best = &candidate{program: prog, score: score}
		}
	}

	if best == nil {
		return nil
	}
	return best.program
}

// scoreCandidate scores a program based on how well it matches as a pre/post-game show.
// Returns 0 if the program does not match at all.
// Scoring:
//   - +10 for each keyword found in the title
//   - +5 for each keyword found in the description
//   - +8 for team name appearing in the title
//   - +4 for team name appearing in the description
//   - +3 for league keyword appearing in the title or description
//   - +2 for being flagged as sports content
func (d *PrePostGameDetector) scoreCandidate(prog *models.Program, teamName string, league string, keywords []string) int {
	score := 0

	titleLower := strings.ToLower(prog.Title)
	descLower := strings.ToLower(prog.Description)
	teamLower := strings.ToLower(teamName)

	// Check for pre/post-game keywords in title (strongest signal)
	for _, kw := range keywords {
		if strings.Contains(titleLower, kw) {
			score += 10
		}
		if strings.Contains(descLower, kw) {
			score += 5
		}
	}

	// If no keywords matched at all, this is not a pre/post-game show
	if score == 0 {
		return 0
	}

	// Bonus for team name in title or description
	if teamLower != "" {
		if strings.Contains(titleLower, teamLower) {
			score += 8
		}
		if strings.Contains(descLower, teamLower) {
			score += 4
		}

		// Also check individual words of the team name (e.g., "Bears" from "Chicago Bears")
		teamParts := strings.Fields(teamLower)
		if len(teamParts) > 1 {
			nickname := teamParts[len(teamParts)-1]
			if len(nickname) >= 4 {
				if strings.Contains(titleLower, nickname) {
					score += 6
				}
				if strings.Contains(descLower, nickname) {
					score += 3
				}
			}
		}
	}

	// Bonus for sport/league keywords
	leagueKeywords := getSportsKeywords(league)
	for _, lkw := range leagueKeywords {
		if strings.Contains(titleLower, lkw) || strings.Contains(descLower, lkw) {
			score += 3
			break // Only count league match once
		}
	}

	// Bonus if program is tagged as sports
	if prog.IsSports {
		score += 2
	}

	return score
}
