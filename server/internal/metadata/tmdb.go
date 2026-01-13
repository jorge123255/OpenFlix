package metadata

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"time"

	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

const (
	tmdbBaseURL  = "https://api.themoviedb.org/3"
	tmdbImageURL = "https://image.tmdb.org/t/p"
)

// TMDBAgent handles metadata fetching from The Movie Database
type TMDBAgent struct {
	apiKey     string
	httpClient *http.Client
	db         *gorm.DB
	dataDir    string
}

// NewTMDBAgent creates a new TMDB metadata agent
func NewTMDBAgent(apiKey string, db *gorm.DB, dataDir string) *TMDBAgent {
	return &TMDBAgent{
		apiKey: apiKey,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		db:      db,
		dataDir: dataDir,
	}
}

// IsConfigured returns true if the TMDB API key is set
func (t *TMDBAgent) IsConfigured() bool {
	return t.apiKey != ""
}

// TMDB API response structures
type tmdbSearchResult struct {
	Page         int           `json:"page"`
	Results      []tmdbMovie   `json:"results"`
	TotalResults int           `json:"total_results"`
	TotalPages   int           `json:"total_pages"`
}

type tmdbTVSearchResult struct {
	Page         int        `json:"page"`
	Results      []tmdbShow `json:"results"`
	TotalResults int        `json:"total_results"`
	TotalPages   int        `json:"total_pages"`
}

type tmdbMovie struct {
	ID               int     `json:"id"`
	Title            string  `json:"title"`
	OriginalTitle    string  `json:"original_title"`
	Overview         string  `json:"overview"`
	Tagline          string  `json:"tagline"`
	PosterPath       string  `json:"poster_path"`
	BackdropPath     string  `json:"backdrop_path"`
	ReleaseDate      string  `json:"release_date"`
	VoteAverage      float64 `json:"vote_average"`
	VoteCount        int     `json:"vote_count"`
	Popularity       float64 `json:"popularity"`
	Adult            bool    `json:"adult"`
	Runtime          int     `json:"runtime"`
	Status           string  `json:"status"`
	Budget           int64   `json:"budget"`
	Revenue          int64   `json:"revenue"`
	Genres           []tmdbGenre `json:"genres"`
	ProductionCompanies []struct {
		ID   int    `json:"id"`
		Name string `json:"name"`
	} `json:"production_companies"`
	// Release dates with certifications (from append_to_response=release_dates)
	ReleaseDates struct {
		Results []struct {
			ISO3166_1    string `json:"iso_3166_1"`
			ReleaseDates []struct {
				Certification string `json:"certification"`
				ReleaseDate   string `json:"release_date"`
				Type          int    `json:"type"`
			} `json:"release_dates"`
		} `json:"results"`
	} `json:"release_dates"`
}

type tmdbShow struct {
	ID               int     `json:"id"`
	Name             string  `json:"name"`
	OriginalName     string  `json:"original_name"`
	Overview         string  `json:"overview"`
	Tagline          string  `json:"tagline"`
	PosterPath       string  `json:"poster_path"`
	BackdropPath     string  `json:"backdrop_path"`
	FirstAirDate     string  `json:"first_air_date"`
	VoteAverage      float64 `json:"vote_average"`
	VoteCount        int     `json:"vote_count"`
	Popularity       float64 `json:"popularity"`
	Status           string  `json:"status"`
	NumberOfSeasons  int     `json:"number_of_seasons"`
	NumberOfEpisodes int     `json:"number_of_episodes"`
	Genres           []tmdbGenre `json:"genres"`
	Networks         []struct {
		ID   int    `json:"id"`
		Name string `json:"name"`
	} `json:"networks"`
	ContentRatings   struct {
		Results []struct {
			ISO3166_1 string `json:"iso_3166_1"`
			Rating    string `json:"rating"`
		} `json:"results"`
	} `json:"content_ratings"`
}

type tmdbSeason struct {
	ID           int    `json:"id"`
	Name         string `json:"name"`
	Overview     string `json:"overview"`
	PosterPath   string `json:"poster_path"`
	SeasonNumber int    `json:"season_number"`
	AirDate      string `json:"air_date"`
	Episodes     []tmdbEpisode `json:"episodes"`
}

type tmdbEpisode struct {
	ID            int     `json:"id"`
	Name          string  `json:"name"`
	Overview      string  `json:"overview"`
	StillPath     string  `json:"still_path"`
	EpisodeNumber int     `json:"episode_number"`
	SeasonNumber  int     `json:"season_number"`
	AirDate       string  `json:"air_date"`
	VoteAverage   float64 `json:"vote_average"`
	Runtime       int     `json:"runtime"`
}

type tmdbGenre struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type tmdbCredits struct {
	Cast []struct {
		ID          int    `json:"id"`
		Name        string `json:"name"`
		Character   string `json:"character"`
		ProfilePath string `json:"profile_path"`
		Order       int    `json:"order"`
	} `json:"cast"`
	Crew []struct {
		ID          int    `json:"id"`
		Name        string `json:"name"`
		Job         string `json:"job"`
		Department  string `json:"department"`
		ProfilePath string `json:"profile_path"`
	} `json:"crew"`
}

// SearchMovie searches TMDB for a movie by title and optional year
func (t *TMDBAgent) SearchMovie(title string, year int) (*tmdbMovie, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)
	params.Set("query", title)
	params.Set("include_adult", "false")
	if year > 0 {
		params.Set("year", strconv.Itoa(year))
	}

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/search/movie?%s", tmdbBaseURL, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var result tmdbSearchResult
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	if len(result.Results) == 0 {
		return nil, fmt.Errorf("no results found for %s", title)
	}

	// Return the first (most relevant) result
	return &result.Results[0], nil
}

// GetMovieDetails fetches full details for a movie by TMDB ID
func (t *TMDBAgent) GetMovieDetails(tmdbID int) (*tmdbMovie, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)
	params.Set("append_to_response", "release_dates") // Get certifications

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/movie/%d?%s", tmdbBaseURL, tmdbID, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var movie tmdbMovie
	if err := json.NewDecoder(resp.Body).Decode(&movie); err != nil {
		return nil, err
	}

	return &movie, nil
}

// GetMovieCredits fetches cast and crew for a movie
func (t *TMDBAgent) GetMovieCredits(tmdbID int) (*tmdbCredits, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/movie/%d/credits?%s", tmdbBaseURL, tmdbID, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var credits tmdbCredits
	if err := json.NewDecoder(resp.Body).Decode(&credits); err != nil {
		return nil, err
	}

	return &credits, nil
}

// SearchTV searches TMDB for a TV show by title and optional year
func (t *TMDBAgent) SearchTV(title string, year int) (*tmdbShow, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)
	params.Set("query", title)
	if year > 0 {
		params.Set("first_air_date_year", strconv.Itoa(year))
	}

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/search/tv?%s", tmdbBaseURL, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var result tmdbTVSearchResult
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	if len(result.Results) == 0 {
		return nil, fmt.Errorf("no results found for %s", title)
	}

	return &result.Results[0], nil
}

// GetTVDetails fetches full details for a TV show by TMDB ID
func (t *TMDBAgent) GetTVDetails(tmdbID int) (*tmdbShow, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)
	params.Set("append_to_response", "content_ratings")

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/tv/%d?%s", tmdbBaseURL, tmdbID, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var show tmdbShow
	if err := json.NewDecoder(resp.Body).Decode(&show); err != nil {
		return nil, err
	}

	return &show, nil
}

// GetTVCredits fetches cast and crew for a TV show
func (t *TMDBAgent) GetTVCredits(tmdbID int) (*tmdbCredits, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/tv/%d/credits?%s", tmdbBaseURL, tmdbID, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var credits tmdbCredits
	if err := json.NewDecoder(resp.Body).Decode(&credits); err != nil {
		return nil, err
	}

	return &credits, nil
}

// GetSeason fetches season details including episodes
func (t *TMDBAgent) GetSeason(tmdbID int, seasonNumber int) (*tmdbSeason, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/tv/%d/season/%d?%s", tmdbBaseURL, tmdbID, seasonNumber, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var season tmdbSeason
	if err := json.NewDecoder(resp.Body).Decode(&season); err != nil {
		return nil, err
	}

	return &season, nil
}

// UpdateMovieMetadata fetches and updates metadata for a movie
func (t *TMDBAgent) UpdateMovieMetadata(item *models.MediaItem) error {
	if !t.IsConfigured() {
		return nil // Silently skip if not configured
	}

	// Search for the movie
	result, err := t.SearchMovie(item.Title, item.Year)
	if err != nil {
		return err
	}

	// Get full details
	movie, err := t.GetMovieDetails(result.ID)
	if err != nil {
		return err
	}

	// Update the media item
	updates := map[string]interface{}{
		"summary":        movie.Overview,
		"tagline":        movie.Tagline,
		"rating":         movie.VoteAverage,
		"original_title": movie.OriginalTitle,
	}

	if movie.PosterPath != "" {
		updates["thumb"] = fmt.Sprintf("%s/w500%s", tmdbImageURL, movie.PosterPath)
	}
	if movie.BackdropPath != "" {
		updates["art"] = fmt.Sprintf("%s/w1280%s", tmdbImageURL, movie.BackdropPath)
	}
	if movie.Runtime > 0 {
		updates["duration"] = int64(movie.Runtime) * 60 * 1000 // Convert minutes to milliseconds
	}
	if len(movie.ProductionCompanies) > 0 {
		updates["studio"] = movie.ProductionCompanies[0].Name
	}

	// Parse release date for year
	if movie.ReleaseDate != "" {
		if releaseTime, err := time.Parse("2006-01-02", movie.ReleaseDate); err == nil {
			updates["year"] = releaseTime.Year()
			updates["originally_available_at"] = releaseTime
		}
	}

	// Get content rating (US certification from release_dates)
	for _, rd := range movie.ReleaseDates.Results {
		if rd.ISO3166_1 == "US" {
			// Find the theatrical or digital release certification
			for _, release := range rd.ReleaseDates {
				if release.Certification != "" {
					updates["content_rating"] = release.Certification
					break
				}
			}
			break
		}
	}

	if err := t.db.Model(item).Updates(updates).Error; err != nil {
		return err
	}

	// Update genres
	if len(movie.Genres) > 0 {
		t.updateGenres(item, movie.Genres)
	}

	// Get and update credits
	if credits, err := t.GetMovieCredits(result.ID); err == nil {
		t.updateCast(item, credits)
	}

	return nil
}

// UpdateShowMetadata fetches and updates metadata for a TV show
func (t *TMDBAgent) UpdateShowMetadata(item *models.MediaItem) error {
	if !t.IsConfigured() {
		return nil
	}

	// Search for the show
	result, err := t.SearchTV(item.Title, item.Year)
	if err != nil {
		return err
	}

	// Get full details
	show, err := t.GetTVDetails(result.ID)
	if err != nil {
		return err
	}

	// Update the media item
	updates := map[string]interface{}{
		"summary":        show.Overview,
		"tagline":        show.Tagline,
		"rating":         show.VoteAverage,
		"original_title": show.OriginalName,
		"leaf_count":     show.NumberOfEpisodes,
		"child_count":    show.NumberOfSeasons,
	}

	if show.PosterPath != "" {
		updates["thumb"] = fmt.Sprintf("%s/w500%s", tmdbImageURL, show.PosterPath)
	}
	if show.BackdropPath != "" {
		updates["art"] = fmt.Sprintf("%s/w1280%s", tmdbImageURL, show.BackdropPath)
	}
	if len(show.Networks) > 0 {
		updates["studio"] = show.Networks[0].Name
	}

	// Get content rating (US)
	for _, cr := range show.ContentRatings.Results {
		if cr.ISO3166_1 == "US" {
			updates["content_rating"] = cr.Rating
			break
		}
	}

	// Parse first air date
	if show.FirstAirDate != "" {
		if airTime, err := time.Parse("2006-01-02", show.FirstAirDate); err == nil {
			updates["year"] = airTime.Year()
			updates["originally_available_at"] = airTime
		}
	}

	if err := t.db.Model(item).Updates(updates).Error; err != nil {
		return err
	}

	// Update genres
	if len(show.Genres) > 0 {
		t.updateGenres(item, show.Genres)
	}

	// Get and update credits
	if credits, err := t.GetTVCredits(result.ID); err == nil {
		t.updateCast(item, credits)
	}

	// Store TMDB ID for season/episode lookups (in UUID field with prefix)
	t.db.Model(item).Update("uuid", fmt.Sprintf("tmdb://%d", result.ID))

	return nil
}

// UpdateSeasonMetadata fetches and updates metadata for a season
func (t *TMDBAgent) UpdateSeasonMetadata(item *models.MediaItem, showTMDBID int) error {
	if !t.IsConfigured() || showTMDBID == 0 {
		return nil
	}

	season, err := t.GetSeason(showTMDBID, item.Index)
	if err != nil {
		return err
	}

	updates := map[string]interface{}{
		"title":   season.Name,
		"summary": season.Overview,
	}

	if season.PosterPath != "" {
		updates["thumb"] = fmt.Sprintf("%s/w500%s", tmdbImageURL, season.PosterPath)
	}

	if season.AirDate != "" {
		if airTime, err := time.Parse("2006-01-02", season.AirDate); err == nil {
			updates["originally_available_at"] = airTime
		}
	}

	return t.db.Model(item).Updates(updates).Error
}

// UpdateEpisodeMetadata fetches and updates metadata for an episode
func (t *TMDBAgent) UpdateEpisodeMetadata(item *models.MediaItem, showTMDBID int, seasonNumber int) error {
	if !t.IsConfigured() || showTMDBID == 0 {
		return nil
	}

	season, err := t.GetSeason(showTMDBID, seasonNumber)
	if err != nil {
		return err
	}

	// Find the episode in the season
	var episode *tmdbEpisode
	for _, ep := range season.Episodes {
		if ep.EpisodeNumber == item.Index {
			episode = &ep
			break
		}
	}

	if episode == nil {
		return fmt.Errorf("episode %d not found in season %d", item.Index, seasonNumber)
	}

	updates := map[string]interface{}{
		"title":   episode.Name,
		"summary": episode.Overview,
		"rating":  episode.VoteAverage,
	}

	if episode.StillPath != "" {
		updates["thumb"] = fmt.Sprintf("%s/w500%s", tmdbImageURL, episode.StillPath)
	}

	if episode.Runtime > 0 {
		updates["duration"] = int64(episode.Runtime) * 60 * 1000
	}

	if episode.AirDate != "" {
		if airTime, err := time.Parse("2006-01-02", episode.AirDate); err == nil {
			updates["originally_available_at"] = airTime
		}
	}

	return t.db.Model(item).Updates(updates).Error
}

// updateGenres updates the genres for a media item
func (t *TMDBAgent) updateGenres(item *models.MediaItem, tmdbGenres []tmdbGenre) {
	// Clear existing genres
	t.db.Model(item).Association("Genres").Clear()

	var genres []models.Genre
	for _, g := range tmdbGenres {
		var genre models.Genre
		t.db.FirstOrCreate(&genre, models.Genre{Tag: g.Name})
		genres = append(genres, genre)
	}

	t.db.Model(item).Association("Genres").Append(genres)
}

// updateCast updates the cast for a media item
func (t *TMDBAgent) updateCast(item *models.MediaItem, credits *tmdbCredits) {
	// Clear existing cast
	t.db.Where("media_item_id = ?", item.ID).Delete(&models.CastMember{})

	order := 0

	// Add directors and writers from crew (they come before cast in display)
	for _, crew := range credits.Crew {
		if crew.Job == "Director" || crew.Job == "Writer" || crew.Job == "Screenplay" || crew.Job == "Story" {
			var thumb string
			if crew.ProfilePath != "" {
				thumb = fmt.Sprintf("%s/w185%s", tmdbImageURL, crew.ProfilePath)
			}

			member := models.CastMember{
				MediaItemID: item.ID,
				Tag:         crew.Name,
				Role:        crew.Job, // Use job as role (Director, Writer, etc.)
				Thumb:       thumb,
				Order:       order,
			}
			t.db.Create(&member)
			order++
		}
	}

	// Add top 10 cast members (actors)
	for i, cast := range credits.Cast {
		if i >= 10 {
			break
		}

		var thumb string
		if cast.ProfilePath != "" {
			thumb = fmt.Sprintf("%s/w185%s", tmdbImageURL, cast.ProfilePath)
		}

		member := models.CastMember{
			MediaItemID: item.ID,
			Tag:         cast.Name,
			Role:        cast.Character,
			Thumb:       thumb,
			Order:       order + cast.Order,
		}
		t.db.Create(&member)
	}
}

// DownloadImage downloads an image from TMDB and returns the bytes
func (t *TMDBAgent) DownloadImage(imagePath string) ([]byte, error) {
	resp, err := t.httpClient.Get(imagePath)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to download image: %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}

// TrendingResult represents a trending item from TMDB
type TrendingResult struct {
	ID           int     `json:"id"`
	Title        string  `json:"title"`
	Name         string  `json:"name"`
	Overview     string  `json:"overview"`
	PosterPath   string  `json:"poster_path"`
	BackdropPath string  `json:"backdrop_path"`
	MediaType    string  `json:"media_type"`
	VoteAverage  float64 `json:"vote_average"`
	ReleaseDate  string  `json:"release_date"`
	FirstAirDate string  `json:"first_air_date"`
	Popularity   float64 `json:"popularity"`
}

// TrendingResponse from TMDB API
type TrendingResponse struct {
	Page         int               `json:"page"`
	Results      []TrendingResult  `json:"results"`
	TotalPages   int               `json:"total_pages"`
	TotalResults int               `json:"total_results"`
}

// GetTrending fetches trending movies and TV shows
func (t *TMDBAgent) GetTrending(mediaType string, timeWindow string) (*TrendingResponse, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	// Valid values: all, movie, tv for mediaType
	// Valid values: day, week for timeWindow
	if mediaType == "" {
		mediaType = "all"
	}
	if timeWindow == "" {
		timeWindow = "day"
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/trending/%s/%s?%s", tmdbBaseURL, mediaType, timeWindow, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var result TrendingResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}

// GetPopularMovies fetches popular movies from TMDB
func (t *TMDBAgent) GetPopularMovies(page int) (*TrendingResponse, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	if page < 1 {
		page = 1
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)
	params.Set("page", strconv.Itoa(page))

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/movie/popular?%s", tmdbBaseURL, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var result TrendingResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	// Set media type for consistency
	for i := range result.Results {
		result.Results[i].MediaType = "movie"
	}

	return &result, nil
}

// GetPopularTV fetches popular TV shows from TMDB
func (t *TMDBAgent) GetPopularTV(page int) (*TrendingResponse, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	if page < 1 {
		page = 1
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)
	params.Set("page", strconv.Itoa(page))

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/tv/popular?%s", tmdbBaseURL, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var result TrendingResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	// Set media type for consistency
	for i := range result.Results {
		result.Results[i].MediaType = "tv"
	}

	return &result, nil
}

// GetTopRatedMovies fetches top rated movies from TMDB
func (t *TMDBAgent) GetTopRatedMovies(page int) (*TrendingResponse, error) {
	if !t.IsConfigured() {
		return nil, fmt.Errorf("TMDB API key not configured")
	}

	if page < 1 {
		page = 1
	}

	params := url.Values{}
	params.Set("api_key", t.apiKey)
	params.Set("page", strconv.Itoa(page))

	resp, err := t.httpClient.Get(fmt.Sprintf("%s/movie/top_rated?%s", tmdbBaseURL, params.Encode()))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("TMDB API error: %d", resp.StatusCode)
	}

	var result TrendingResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	for i := range result.Results {
		result.Results[i].MediaType = "movie"
	}

	return &result, nil
}
