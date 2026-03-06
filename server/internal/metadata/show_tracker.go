package metadata

import (
	"context"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// NotifyFn is a callback used to send a notification without importing the notify package
// (which would create an import cycle via notify → dvr → metadata).
type NotifyFn func(title, message string)

// MonitorNewSeasons checks all tracked shows for new seasons via TMDB and
// updates the show_trackers table with the latest season/episode air date info.
// When a new season is detected, it calls notifyFn if provided.
func MonitorNewSeasons(ctx context.Context, db *gorm.DB, tmdb *TMDBAgent, notifyFn NotifyFn) error {
	if !tmdb.IsConfigured() {
		return nil
	}

	// Only check TV shows (movies don't have seasons)
	var trackers []models.ShowTracker
	if err := db.Where("media_type = ?", "tv").Find(&trackers).Error; err != nil {
		return err
	}

	cutoff := time.Now().Add(-12 * time.Hour)

	for i := range trackers {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		t := &trackers[i]

		// Skip if checked recently
		if t.LastCheckedAt != nil && t.LastCheckedAt.After(cutoff) {
			continue
		}

		details, err := tmdb.GetTVDetailsFull(t.TMDBId)
		if err != nil {
			logger.Warnf("[show_tracker] failed to fetch TMDB details for %q (id=%d): %v", t.ShowTitle, t.TMDBId, err)
			continue
		}

		now := time.Now()
		updates := map[string]interface{}{
			"last_checked_at":    &now,
			"last_season_count":  details.NumberOfSeasons,
			"last_episode_count": details.NumberOfEpisodes,
		}

		// Check for new seasons
		newSeasonDetected := details.NumberOfSeasons > t.LastSeasonCount && t.LastSeasonCount > 0

		// Capture next episode air date from TMDB
		if details.NextEpisodeToAir != nil {
			updates["next_episode_air_date"] = details.NextEpisodeToAir.AirDate
			updates["next_season_number"] = details.NextEpisodeToAir.SeasonNumber
		} else {
			updates["next_episode_air_date"] = ""
			updates["next_season_number"] = 0
		}

		if err := db.Model(t).Updates(updates).Error; err != nil {
			logger.Warnf("[show_tracker] failed to update tracker for %q: %v", t.ShowTitle, err)
			continue
		}

		if newSeasonDetected && notifyFn != nil {
			msg := t.ShowTitle + " has a new season available on TMDB"
			if details.NextEpisodeToAir != nil {
				msg = t.ShowTitle + ": Season " + itoa(details.NumberOfSeasons) + " - next episode airs " + details.NextEpisodeToAir.AirDate
			}
			notifyFn("New Season: "+t.ShowTitle, msg)
		}

		logger.Debugf("[show_tracker] checked %q: seasons=%d, next_air=%s",
			t.ShowTitle, details.NumberOfSeasons, safeStr(updates["next_episode_air_date"]))
	}

	return nil
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	result := ""
	neg := n < 0
	if neg {
		n = -n
	}
	for n > 0 {
		result = string(rune('0'+n%10)) + result
		n /= 10
	}
	if neg {
		result = "-" + result
	}
	return result
}

func safeStr(v interface{}) string {
	if v == nil {
		return ""
	}
	if s, ok := v.(string); ok {
		return s
	}
	return ""
}
