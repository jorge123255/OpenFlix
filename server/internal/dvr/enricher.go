package dvr

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/metadata"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

const tmdbImageURL = "https://image.tmdb.org/t/p"

// Enricher handles fetching and applying TMDB metadata to DVR recordings
type Enricher struct {
	db        *gorm.DB
	tmdb      *metadata.TMDBAgent
	logger    *logrus.Entry
}

// NewEnricher creates a new DVR metadata enricher
func NewEnricher(db *gorm.DB, tmdb *metadata.TMDBAgent) *Enricher {
	return &Enricher{
		db:     db,
		tmdb:   tmdb,
		logger: logrus.WithField("component", "dvr-enricher"),
	}
}

// EnrichRecording fetches TMDB metadata for a recording and updates it
func (e *Enricher) EnrichRecording(recording *models.Recording) error {
	if e.tmdb == nil || !e.tmdb.IsConfigured() {
		e.logger.Debug("TMDB not configured, skipping enrichment")
		return nil
	}

	// First, try to get channel info
	e.enrichChannelInfo(recording)

	// Parse season/episode from title or episodeNum field
	seasonNum, episodeNum, cleanTitle := e.parseEpisodeInfo(recording.Title, recording.EpisodeNum)

	// Determine if this is likely a movie based on category or duration
	isMovie := e.isLikelyMovie(recording)

	if isMovie {
		return e.enrichMovieRecording(recording, cleanTitle)
	}
	return e.enrichTVRecording(recording, cleanTitle, seasonNum, episodeNum)
}

// enrichChannelInfo adds channel name and logo to recording
func (e *Enricher) enrichChannelInfo(recording *models.Recording) {
	if recording.ChannelID == 0 {
		return
	}

	var channel models.Channel
	if err := e.db.First(&channel, recording.ChannelID).Error; err == nil {
		recording.ChannelName = channel.Name
		if channel.Logo != "" {
			recording.ChannelLogo = channel.Logo
		}
	}
}

// parseEpisodeInfo extracts season/episode numbers from title or episodeNum field
func (e *Enricher) parseEpisodeInfo(title, episodeNum string) (*int, *int, string) {
	var seasonNum, epNum *int
	cleanTitle := title

	// Try parsing episodeNum field first (e.g., "S01E05", "1x05", "105")
	if episodeNum != "" {
		if s, ep := parseSeasonEpisode(episodeNum); s != nil {
			seasonNum = s
			epNum = ep
		}
	}

	// Try parsing from title (e.g., "Show Name S01E05" or "Show Name - Episode Title")
	patterns := []string{
		`(?i)[\s\-\.]+S(\d{1,2})E(\d{1,2})`,           // S01E05
		`(?i)[\s\-\.]+(\d{1,2})x(\d{1,2})`,            // 1x05
		`(?i)[\s\-\.]+Season\s*(\d+)\s*Episode\s*(\d+)`, // Season 1 Episode 5
	}

	for _, pattern := range patterns {
		re := regexp.MustCompile(pattern)
		if matches := re.FindStringSubmatch(title); len(matches) >= 3 {
			if s, _ := strconv.Atoi(matches[1]); s > 0 {
				seasonNum = &s
			}
			if ep, _ := strconv.Atoi(matches[2]); ep > 0 {
				epNum = &ep
			}
			// Remove the pattern from title
			cleanTitle = strings.TrimSpace(re.ReplaceAllString(title, ""))
			break
		}
	}

	// Remove common suffixes like "(New)" or episode titles after " - "
	cleanTitle = regexp.MustCompile(`\s*\([^)]*\)\s*$`).ReplaceAllString(cleanTitle, "")
	if idx := strings.Index(cleanTitle, " - "); idx > 0 {
		cleanTitle = strings.TrimSpace(cleanTitle[:idx])
	}

	return seasonNum, epNum, cleanTitle
}

// parseSeasonEpisode parses season/episode from string like "S01E05", "1x05", "105"
func parseSeasonEpisode(s string) (*int, *int) {
	s = strings.ToUpper(strings.TrimSpace(s))

	// S01E05 format
	re := regexp.MustCompile(`S(\d{1,2})E(\d{1,2})`)
	if matches := re.FindStringSubmatch(s); len(matches) >= 3 {
		season, _ := strconv.Atoi(matches[1])
		episode, _ := strconv.Atoi(matches[2])
		return &season, &episode
	}

	// 1x05 format
	re = regexp.MustCompile(`(\d{1,2})X(\d{1,2})`)
	if matches := re.FindStringSubmatch(s); len(matches) >= 3 {
		season, _ := strconv.Atoi(matches[1])
		episode, _ := strconv.Atoi(matches[2])
		return &season, &episode
	}

	// 105 format (season 1, episode 5) - only if 3-4 digits
	if len(s) >= 3 && len(s) <= 4 {
		if num, err := strconv.Atoi(s); err == nil && num > 100 {
			season := num / 100
			episode := num % 100
			if episode > 0 && episode < 100 {
				return &season, &episode
			}
		}
	}

	return nil, nil
}

// isLikelyMovie determines if the recording is likely a movie
func (e *Enricher) isLikelyMovie(recording *models.Recording) bool {
	category := strings.ToLower(recording.Category)

	// Check category
	movieKeywords := []string{"movie", "film", "feature", "cinema"}
	for _, kw := range movieKeywords {
		if strings.Contains(category, kw) {
			return true
		}
	}

	// Check duration - movies are typically 80+ minutes
	duration := recording.EndTime.Sub(recording.StartTime)
	if duration >= 80*time.Minute && duration <= 240*time.Minute {
		// Could be a movie, but also could be a sports event
		// Check if NOT sports
		sportsKeywords := []string{"sport", "game", "match", "nfl", "nba", "mlb", "nhl", "soccer", "football"}
		for _, kw := range sportsKeywords {
			if strings.Contains(category, kw) {
				return false
			}
		}
		// Long duration without sports category - likely movie
		if duration >= 90*time.Minute {
			return true
		}
	}

	return false
}

// enrichMovieRecording fetches movie metadata from TMDB
func (e *Enricher) enrichMovieRecording(recording *models.Recording, title string) error {
	e.logger.WithField("title", title).Info("Enriching movie recording")

	// Extract year from title if present (e.g., "Movie Name (2024)")
	year := 0
	yearRe := regexp.MustCompile(`\((\d{4})\)\s*$`)
	if matches := yearRe.FindStringSubmatch(title); len(matches) >= 2 {
		year, _ = strconv.Atoi(matches[1])
		title = strings.TrimSpace(yearRe.ReplaceAllString(title, ""))
	}

	// Search TMDB
	movie, err := e.tmdb.SearchMovie(title, year)
	if err != nil {
		e.logger.WithError(err).WithField("title", title).Warn("Failed to find movie on TMDB")
		return nil // Don't fail the recording
	}

	// Get full details
	details, err := e.tmdb.GetMovieDetails(movie.ID)
	if err != nil {
		e.logger.WithError(err).Warn("Failed to get movie details")
		details = movie // Use search result
	}

	// Update recording
	recording.IsMovie = true
	recording.TMDBId = &details.ID
	recording.Summary = details.Overview

	if details.PosterPath != "" {
		recording.Thumb = fmt.Sprintf("%s/w500%s", tmdbImageURL, details.PosterPath)
	}
	if details.BackdropPath != "" {
		recording.Art = fmt.Sprintf("%s/w1280%s", tmdbImageURL, details.BackdropPath)
	}
	if details.VoteAverage > 0 {
		recording.Rating = &details.VoteAverage
	}
	if details.Runtime > 0 {
		recording.Duration = &details.Runtime
	}

	// Parse release date for year
	if details.ReleaseDate != "" {
		if releaseTime, err := time.Parse("2006-01-02", details.ReleaseDate); err == nil {
			y := releaseTime.Year()
			recording.Year = &y
			recording.OriginalAirDate = &releaseTime
		}
	}

	// Get content rating
	for _, rd := range details.ReleaseDates.Results {
		if rd.ISO3166_1 == "US" {
			for _, release := range rd.ReleaseDates {
				if release.Certification != "" {
					recording.ContentRating = release.Certification
					break
				}
			}
			break
		}
	}

	// Genres
	var genres []string
	for _, g := range details.Genres {
		genres = append(genres, g.Name)
	}
	if len(genres) > 0 {
		recording.Genres = strings.Join(genres, ", ")
	}

	// Save updates
	return e.db.Save(recording).Error
}

// enrichTVRecording fetches TV show metadata from TMDB
func (e *Enricher) enrichTVRecording(recording *models.Recording, title string, seasonNum, episodeNum *int) error {
	e.logger.WithFields(logrus.Fields{
		"title":   title,
		"season":  seasonNum,
		"episode": episodeNum,
	}).Info("Enriching TV recording")

	// Search TMDB for the show
	show, err := e.tmdb.SearchTV(title, 0)
	if err != nil {
		e.logger.WithError(err).WithField("title", title).Warn("Failed to find show on TMDB")
		return nil
	}

	// Get full show details
	details, err := e.tmdb.GetTVDetails(show.ID)
	if err != nil {
		e.logger.WithError(err).Warn("Failed to get show details")
		details = show
	}

	// Update recording with show info
	recording.IsMovie = false
	recording.TMDBId = &details.ID

	if details.PosterPath != "" {
		recording.Thumb = fmt.Sprintf("%s/w500%s", tmdbImageURL, details.PosterPath)
	}
	if details.BackdropPath != "" {
		recording.Art = fmt.Sprintf("%s/w1280%s", tmdbImageURL, details.BackdropPath)
	}
	if details.VoteAverage > 0 {
		recording.Rating = &details.VoteAverage
	}

	// Get content rating
	for _, cr := range details.ContentRatings.Results {
		if cr.ISO3166_1 == "US" {
			recording.ContentRating = cr.Rating
			break
		}
	}

	// Genres
	var genres []string
	for _, g := range details.Genres {
		genres = append(genres, g.Name)
	}
	if len(genres) > 0 {
		recording.Genres = strings.Join(genres, ", ")
	}

	// Parse first air date for year
	if details.FirstAirDate != "" {
		if airTime, err := time.Parse("2006-01-02", details.FirstAirDate); err == nil {
			y := airTime.Year()
			recording.Year = &y
		}
	}

	// Set season/episode numbers
	recording.SeasonNumber = seasonNum
	recording.EpisodeNumber = episodeNum

	// If we have season/episode, try to get episode-specific info
	if seasonNum != nil && episodeNum != nil && *seasonNum > 0 && *episodeNum > 0 {
		e.enrichEpisodeInfo(recording, details.ID, *seasonNum, *episodeNum)
	} else {
		// Use show overview as summary
		recording.Summary = details.Overview
	}

	return e.db.Save(recording).Error
}

// enrichEpisodeInfo fetches episode-specific metadata
func (e *Enricher) enrichEpisodeInfo(recording *models.Recording, showTMDBId, seasonNum, episodeNum int) {
	season, err := e.tmdb.GetSeason(showTMDBId, seasonNum)
	if err != nil {
		e.logger.WithError(err).Warn("Failed to get season details")
		return
	}

	// Find the episode
	for _, ep := range season.Episodes {
		if ep.EpisodeNumber == episodeNum {
			recording.Subtitle = ep.Name
			recording.Summary = ep.Overview

			if ep.StillPath != "" {
				// Use episode still as thumbnail (more specific than show poster)
				recording.Thumb = fmt.Sprintf("%s/w500%s", tmdbImageURL, ep.StillPath)
			}

			if ep.Runtime > 0 {
				recording.Duration = &ep.Runtime
			}

			if ep.AirDate != "" {
				if airTime, err := time.Parse("2006-01-02", ep.AirDate); err == nil {
					recording.OriginalAirDate = &airTime
				}
			}

			if ep.VoteAverage > 0 {
				recording.Rating = &ep.VoteAverage
			}

			break
		}
	}
}

// EnrichAllPendingRecordings enriches all scheduled recordings that don't have metadata
func (e *Enricher) EnrichAllPendingRecordings() error {
	var recordings []models.Recording

	// Find recordings without TMDB metadata
	err := e.db.Where("tmdb_id IS NULL AND status IN ?", []string{"scheduled", "recording"}).
		Find(&recordings).Error
	if err != nil {
		return err
	}

	e.logger.WithField("count", len(recordings)).Info("Enriching pending recordings")

	for i := range recordings {
		if err := e.EnrichRecording(&recordings[i]); err != nil {
			e.logger.WithError(err).WithField("id", recordings[i].ID).Warn("Failed to enrich recording")
		}
		// Rate limit TMDB requests
		time.Sleep(250 * time.Millisecond)
	}

	return nil
}
