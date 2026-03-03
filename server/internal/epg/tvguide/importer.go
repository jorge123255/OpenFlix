package tvguide

import (
	"context"
	"fmt"
	"strings"
	"time"
)

// ImportResult contains the result of importing TVGuide data into the program store
type ImportResult struct {
	Imported     int
	Updated      int
	ChannelCount int
	TotalPrograms int
}

// ProgramData is a flat structure ready for database import
// (avoids importing the models package to keep tvguide package standalone)
type ProgramData struct {
	ChannelID     string
	CallSign      string
	ChannelNo     string
	AffiliateName string
	Title         string
	Description   string
	EpisodeTitle  string
	Start         time.Time
	End           time.Time
	Icon          string    // Channel logo
	Art           string    // Program showcard/poster
	Category      string
	Rating        string
	SeasonNumber  int
	EpisodeNumber int
	ReleaseYear   int
	IsNew         bool
	IsLive        bool
	IsMovie       bool
	IsSports      bool
	IsKids        bool
	IsNews        bool
	ProgramID     string    // TVGuide program ID
	Genres        string    // Comma-separated
	HasCC         bool      // Closed captions available
	Slug          string    // For URL construction
}

// ConvertToPrograms converts TVGuide API data into ProgramData structs ready for DB import
func ConvertToPrograms(
	result *FetchResult,
	details map[int]*ProgramDetail,
	providerID string,
) ([]ProgramData, int) {

	var programs []ProgramData
	channelSet := make(map[string]bool)

	for _, ch := range result.Channels {
		// Build a unique channel ID
		channelID := fmt.Sprintf("tvguide-%s-%d", providerID, ch.Channel.SourceID)
		channelSet[channelID] = true

		// Get channel logo URL
		channelLogo := ""
		if ch.Channel.Logo != "" {
			channelLogo = FullImageURL(ch.Channel.Logo)
		}

		// Channel metadata
		callSign := ch.Channel.Name
		if callSign == "" {
			callSign = ch.Channel.Name
		}
		channelNo := ch.Channel.Number

		// Get network name
		affiliateName := ""
		if ch.Channel.NetworkName != nil && *ch.Channel.NetworkName != "" {
			affiliateName = *ch.Channel.NetworkName
		} else if fn := ch.Channel.FullName; fn != "" {
			if idx := strings.LastIndex(fn, "("); idx >= 0 {
				end := strings.Index(fn[idx:], ")")
				if end > 0 {
					affiliateName = fn[idx+1 : idx+end]
				}
			}
		}

		for _, sched := range ch.ProgramSchedules {
			flags := DecodeAiringFlags(sched.AiringAttrib)

			start := time.Unix(sched.StartTime, 0).UTC()
			end := time.Unix(sched.EndTime, 0).UTC()

			// Classify by category
			catName := CategoryNames[sched.CatID]
			isMovie := sched.CatID == CategoryMovie
			isSports := sched.CatID == CategorySports || flags.IsSports
			isKids := sched.CatID == CategoryKids
			isNews := sched.CatID == CategoryNews

			p := ProgramData{
				ChannelID:     channelID,
				CallSign:      callSign,
				ChannelNo:     channelNo,
				AffiliateName: affiliateName,
				Title:         sched.Title,
				Start:         start,
				End:           end,
				Icon:          channelLogo,
				Category:      catName,
				Rating:        sched.Rating,
				IsNew:         flags.IsNew,
				IsLive:        flags.IsLive,
				IsMovie:       isMovie,
				IsSports:      isSports,
				IsKids:        isKids,
				IsNews:        isNews,
				HasCC:         flags.HasCC,
				ProgramID:     fmt.Sprintf("%d", sched.ProgramID),
			}

			// Enrich with program details if available
			if detail, ok := details[sched.ProgramID]; ok && detail != nil {
				if detail.Description != "" {
					p.Description = detail.Description
				}
				if detail.EpisodeTitle != "" {
					p.EpisodeTitle = detail.EpisodeTitle
				}
				if detail.SeasonNumber > 0 {
					p.SeasonNumber = detail.SeasonNumber
				}
				if detail.EpisodeNumber > 0 {
					p.EpisodeNumber = detail.EpisodeNumber
				}
				if detail.ReleaseYear > 0 {
					p.ReleaseYear = detail.ReleaseYear
				}
				if detail.TVRating != "" {
					p.Rating = detail.TVRating
				}
				if detail.Slug != "" {
					p.Slug = detail.Slug
				}
				if detail.IsSportsEvent {
					p.IsSports = true
				}

				// Get best artwork
				for _, img := range detail.Images {
					imgURL := FullImageURL(img.BucketPath)
					switch img.ImageType.TypeName {
					case "showcard":
						if p.Art == "" {
							p.Art = imgURL
						}
					case "poster art":
						// Poster art is higher quality, prefer it
						p.Art = imgURL
					}
				}

				// Build genres string
				var genreNames []string
				for _, g := range detail.Genres {
					genreNames = append(genreNames, g.Name)
					genreNames = append(genreNames, g.Genres...)
				}
				if len(genreNames) > 0 {
					p.Genres = strings.Join(genreNames, ", ")
				}
			}

			programs = append(programs, p)
		}
	}

	return programs, len(channelSet)
}

// FetchAndConvert is a convenience function that fetches schedule + details and converts to ProgramData
func FetchAndConvert(ctx context.Context, config ProviderConfig) ([]ProgramData, int, error) {
	client := NewClient()

	result, details, err := client.FetchFullListings(ctx, config)
	if err != nil {
		return nil, 0, err
	}

	programs, channelCount := ConvertToPrograms(result, details, config.ProviderID)
	return programs, channelCount, nil
}
