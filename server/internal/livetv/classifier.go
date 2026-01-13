package livetv

import (
	"strings"

	"github.com/openflix/openflix-server/internal/models"
)

// ContentClassifier classifies EPG programs by content type
type ContentClassifier struct{}

// NewContentClassifier creates a new content classifier
func NewContentClassifier() *ContentClassifier {
	return &ContentClassifier{}
}

// ClassifyProgram analyzes a program and sets content type flags
func (c *ContentClassifier) ClassifyProgram(p *models.Program) {
	// Build searchable text from title, description, and category
	title := strings.ToLower(p.Title)
	desc := strings.ToLower(p.Description)
	cat := strings.ToLower(p.Category)

	// Classify content type
	p.IsMovie = c.isMovie(cat, title, desc)
	p.IsSports = c.isSports(cat, title, desc)
	p.IsKids = c.isKids(cat, title, desc)
	p.IsNews = c.isNews(cat, title, desc)
	p.IsLive = c.isLive(cat, title, desc)

	// Extract teams and league for sports content
	if p.IsSports {
		// Only search title for team names to avoid false positives from descriptions
		teams := FindTeamInText(title)
		if len(teams) > 0 {
			var teamNames []string
			leagueSet := make(map[string]bool)

			for _, team := range teams {
				teamNames = append(teamNames, team.Name)
				leagueSet[team.League] = true
			}

			p.Teams = strings.Join(teamNames, ",")

			// Set league if all teams are from the same league
			if len(leagueSet) == 1 {
				for league := range leagueSet {
					p.League = league
				}
			} else if len(leagueSet) > 0 {
				// Multiple leagues, try to determine from title/desc
				p.League = c.detectLeague(title, desc)
			}
		} else {
			// No teams found, try to detect league anyway
			p.League = c.detectLeague(title, desc)
		}
	}
}

// Movie detection keywords
var movieKeywords = []string{
	"movie", "film", "feature", "cinema", "theatrical",
}

var movieCategories = []string{
	"movie", "film", "feature", "cinema",
	"action", "comedy", "drama", "horror", "thriller", "romance",
	"sci-fi", "science fiction", "fantasy", "western", "documentary film",
}

func (c *ContentClassifier) isMovie(cat, title, desc string) bool {
	// Check category
	for _, keyword := range movieCategories {
		if strings.Contains(cat, keyword) {
			return true
		}
	}

	// Check title/description keywords
	for _, keyword := range movieKeywords {
		if strings.Contains(title, keyword) || strings.Contains(desc, keyword) {
			return true
		}
	}

	return false
}

// Sports detection keywords
var sportsKeywords = []string{
	"game", "match", "championship", "tournament", "playoffs", "playoff",
	"finals", "semifinal", "quarterfinal", "super bowl", "world series",
	"stanley cup", "nba finals", "world cup", "olympics", "olympic",
	"racing", "race", "golf", "tennis", "boxing", "wrestling", "mma",
	"ufc", "wwe", "nascar", "formula 1", "f1", "motorsports",
}

var sportsCategories = []string{
	"sport", "sports", "athletics", "football", "basketball", "baseball",
	"hockey", "soccer", "golf", "tennis", "racing", "motorsports",
	"boxing", "wrestling", "mma", "fighting", "olympics", "college sports",
}

var leagueKeywords = map[string][]string{
	"NFL":  {"nfl", "football", "super bowl", "gridiron", "touchdown"},
	"NBA":  {"nba", "basketball"},
	"MLB":  {"mlb", "baseball", "world series"},
	"NHL":  {"nhl", "hockey", "stanley cup"},
	"MLS":  {"mls", "major league soccer"},
	"NCAA": {"ncaa", "college football", "college basketball", "march madness"},
	"PGA":  {"pga", "golf", "masters", "us open golf"},
	"UFC":  {"ufc", "mma", "mixed martial arts"},
}

func (c *ContentClassifier) isSports(cat, title, desc string) bool {
	// Check category - most reliable indicator
	for _, keyword := range sportsCategories {
		if strings.Contains(cat, keyword) {
			return true
		}
	}

	// Check league keywords in title (not description to avoid false positives)
	for _, keywords := range leagueKeywords {
		for _, keyword := range keywords {
			if strings.Contains(title, keyword) {
				return true
			}
		}
	}

	// Check general sports keywords in title only
	for _, keyword := range sportsKeywords {
		if strings.Contains(title, keyword) {
			return true
		}
	}

	// DO NOT use team name detection here - it causes too many false positives
	// (e.g., any show mentioning "Chicago" would match Chicago Bears/Bulls/etc.)
	return false
}

func (c *ContentClassifier) detectLeague(title, desc string) string {
	combined := title + " " + desc

	for league, keywords := range leagueKeywords {
		for _, keyword := range keywords {
			if strings.Contains(combined, keyword) {
				return league
			}
		}
	}

	return ""
}

// Kids detection keywords
var kidsKeywords = []string{
	"kids", "children", "child", "cartoon", "animated", "animation",
	"preschool", "toddler", "family", "educational", "disney",
	"nickelodeon", "nick jr", "pbs kids", "sesame", "bluey",
	"peppa", "paw patrol", "dora", "spongebob",
}

var kidsCategories = []string{
	"children", "kids", "cartoon", "animation", "family", "educational",
	"preschool",
}

func (c *ContentClassifier) isKids(cat, title, desc string) bool {
	// Check category
	for _, keyword := range kidsCategories {
		if strings.Contains(cat, keyword) {
			return true
		}
	}

	// Check title/description keywords
	combined := title + " " + desc
	for _, keyword := range kidsKeywords {
		if strings.Contains(combined, keyword) {
			return true
		}
	}

	return false
}

// News detection keywords
var newsKeywords = []string{
	"news", "breaking", "headlines", "newscast", "bulletin",
	"world news", "local news", "evening news", "morning news",
	"nightly news", "abc news", "cbs news", "nbc news", "cnn",
	"fox news", "msnbc", "bbc news",
}

var newsCategories = []string{
	"news", "current affairs", "public affairs", "newscast",
	"documentary", "talk show", "interview",
}

func (c *ContentClassifier) isNews(cat, title, desc string) bool {
	// Check category
	for _, keyword := range newsCategories {
		if strings.Contains(cat, keyword) {
			return true
		}
	}

	// Check title/description keywords
	combined := title + " " + desc
	for _, keyword := range newsKeywords {
		if strings.Contains(combined, keyword) {
			return true
		}
	}

	return false
}

// Live content detection
var liveKeywords = []string{
	"live", "simulcast", "real-time", "breaking",
}

func (c *ContentClassifier) isLive(cat, title, desc string) bool {
	combined := title + " " + desc + " " + cat

	for _, keyword := range liveKeywords {
		if strings.Contains(combined, keyword) {
			return true
		}
	}

	return false
}

// ClassifyPrograms classifies a batch of programs
func (c *ContentClassifier) ClassifyPrograms(programs []*models.Program) {
	for _, p := range programs {
		c.ClassifyProgram(p)
	}
}

// ClassifyProgramsList classifies a batch of programs (value receivers)
func (c *ContentClassifier) ClassifyProgramsList(programs []models.Program) {
	for i := range programs {
		c.ClassifyProgram(&programs[i])
	}
}
