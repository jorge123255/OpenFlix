package api

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// ConfigExport represents the full configuration export
type ConfigExport struct {
	Version     string    `json:"version"`
	ExportedAt  time.Time `json:"exportedAt"`

	// Live TV Sources
	M3USources    []M3USourceExport    `json:"m3uSources"`
	XtreamSources []XtreamSourceExport `json:"xtreamSources"`
	EPGSources    []models.EPGSource   `json:"epgSources"`

	// Channels
	Channels      []ChannelExport       `json:"channels"`
	ChannelGroups []ChannelGroupExport  `json:"channelGroups"`

	// DVR
	SeriesRules []models.SeriesRule `json:"seriesRules"`
	TeamPasses  []models.TeamPass   `json:"teamPasses"`

	// Libraries
	Libraries []LibraryExport `json:"libraries"`

	// Users
	Users []UserExport `json:"users"`

	// Playlists and Collections
	Playlists   []PlaylistExport   `json:"playlists"`
	Collections []CollectionExport `json:"collections"`
}

// M3USourceExport is M3USource with all fields
type M3USourceExport struct {
	models.M3USource
}

// XtreamSourceExport includes password for backup
type XtreamSourceExport struct {
	ID              uint       `json:"id"`
	Name            string     `json:"name"`
	ServerURL       string     `json:"serverUrl"`
	Username        string     `json:"username"`
	Password        string     `json:"password"` // Include for backup!
	Enabled         bool       `json:"enabled"`
	ImportLive      bool       `json:"importLive"`
	ImportVOD       bool       `json:"importVod"`
	ImportSeries    bool       `json:"importSeries"`
	VODLibraryID    *uint      `json:"vodLibraryId,omitempty"`
	SeriesLibraryID *uint      `json:"seriesLibraryId,omitempty"`
}

// ChannelExport is Channel for export
type ChannelExport struct {
	models.Channel
	SourceName string `json:"sourceName,omitempty"`
}

// ChannelGroupExport includes members
type ChannelGroupExport struct {
	models.ChannelGroup
	MemberChannelIDs []uint `json:"memberChannelIds"`
	MemberPriorities []int  `json:"memberPriorities"`
}

// LibraryExport includes paths
type LibraryExport struct {
	models.Library
	Paths []string `json:"paths"`
}

// UserExport includes profiles
type UserExport struct {
	ID          uint                 `json:"id"`
	UUID        string               `json:"uuid"`
	Username    string               `json:"username"`
	Email       string               `json:"email,omitempty"`
	DisplayName string               `json:"displayName"`
	IsAdmin     bool                 `json:"isAdmin"`
	Profiles    []models.UserProfile `json:"profiles,omitempty"`
}

// PlaylistExport includes items
type PlaylistExport struct {
	models.Playlist
	ItemIDs []uint `json:"itemIds"`
}

// CollectionExport includes items
type CollectionExport struct {
	models.Collection
	ItemIDs []uint `json:"itemIds"`
}

// exportConfig exports the full server configuration
func (s *Server) exportConfig(c *gin.Context) {
	export := ConfigExport{
		Version:    "1.0",
		ExportedAt: time.Now(),
	}

	// Export M3U Sources
	var m3uSources []models.M3USource
	s.db.Find(&m3uSources)
	for _, src := range m3uSources {
		export.M3USources = append(export.M3USources, M3USourceExport{M3USource: src})
	}

	// Export Xtream Sources (including password)
	var xtreamSources []models.XtreamSource
	s.db.Find(&xtreamSources)
	for _, src := range xtreamSources {
		export.XtreamSources = append(export.XtreamSources, XtreamSourceExport{
			ID:              src.ID,
			Name:            src.Name,
			ServerURL:       src.ServerURL,
			Username:        src.Username,
			Password:        src.Password,
			Enabled:         src.Enabled,
			ImportLive:      src.ImportLive,
			ImportVOD:       src.ImportVOD,
			ImportSeries:    src.ImportSeries,
			VODLibraryID:    src.VODLibraryID,
			SeriesLibraryID: src.SeriesLibraryID,
		})
	}

	// Export EPG Sources
	s.db.Find(&export.EPGSources)

	// Export Channels with source name
	var channels []models.Channel
	s.db.Find(&channels)
	for _, ch := range channels {
		chExport := ChannelExport{Channel: ch}
		// Get source name
		if ch.M3USourceID > 0 {
			var src models.M3USource
			if s.db.First(&src, ch.M3USourceID).Error == nil {
				chExport.SourceName = src.Name
			}
		}
		export.Channels = append(export.Channels, chExport)
	}

	// Export Channel Groups with members
	var groups []models.ChannelGroup
	s.db.Find(&groups)
	for _, grp := range groups {
		grpExport := ChannelGroupExport{ChannelGroup: grp}
		var members []models.ChannelGroupMember
		s.db.Where("channel_group_id = ?", grp.ID).Order("priority ASC").Find(&members)
		for _, m := range members {
			grpExport.MemberChannelIDs = append(grpExport.MemberChannelIDs, m.ChannelID)
			grpExport.MemberPriorities = append(grpExport.MemberPriorities, m.Priority)
		}
		export.ChannelGroups = append(export.ChannelGroups, grpExport)
	}

	// Export Series Rules
	s.db.Find(&export.SeriesRules)

	// Export Team Passes
	s.db.Find(&export.TeamPasses)

	// Export Libraries with paths
	var libraries []models.Library
	s.db.Preload("Paths").Find(&libraries)
	for _, lib := range libraries {
		libExport := LibraryExport{Library: lib}
		for _, p := range lib.Paths {
			libExport.Paths = append(libExport.Paths, p.Path)
		}
		export.Libraries = append(export.Libraries, libExport)
	}

	// Export Users with profiles (no passwords)
	var users []models.User
	s.db.Preload("Profiles").Find(&users)
	for _, u := range users {
		export.Users = append(export.Users, UserExport{
			ID:          u.ID,
			UUID:        u.UUID,
			Username:    u.Username,
			Email:       u.Email,
			DisplayName: u.DisplayName,
			IsAdmin:     u.IsAdmin,
			Profiles:    u.Profiles,
		})
	}

	// Export Playlists with items
	var playlists []models.Playlist
	s.db.Preload("Items").Find(&playlists)
	for _, pl := range playlists {
		plExport := PlaylistExport{Playlist: pl}
		for _, item := range pl.Items {
			plExport.ItemIDs = append(plExport.ItemIDs, item.MediaItemID)
		}
		export.Playlists = append(export.Playlists, plExport)
	}

	// Export Collections with items
	var collections []models.Collection
	s.db.Preload("Items").Find(&collections)
	for _, col := range collections {
		colExport := CollectionExport{Collection: col}
		for _, item := range col.Items {
			colExport.ItemIDs = append(colExport.ItemIDs, item.MediaItemID)
		}
		export.Collections = append(export.Collections, colExport)
	}

	// Set filename header
	filename := fmt.Sprintf("openflix-config-%s.json", time.Now().Format("2006-01-02"))
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.JSON(http.StatusOK, export)
}

// importConfig imports configuration from a JSON file
func (s *Server) importConfig(c *gin.Context) {
	var importData ConfigExport
	if err := c.ShouldBindJSON(&importData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON: " + err.Error()})
		return
	}

	// Preview mode - just return what would be imported
	preview := c.Query("preview") == "true"

	result := gin.H{
		"m3uSources":    len(importData.M3USources),
		"xtreamSources": len(importData.XtreamSources),
		"epgSources":    len(importData.EPGSources),
		"channels":      len(importData.Channels),
		"channelGroups": len(importData.ChannelGroups),
		"seriesRules":   len(importData.SeriesRules),
		"teamPasses":    len(importData.TeamPasses),
		"libraries":     len(importData.Libraries),
		"users":         len(importData.Users),
		"playlists":     len(importData.Playlists),
		"collections":   len(importData.Collections),
	}

	if preview {
		c.JSON(http.StatusOK, gin.H{
			"preview": true,
			"counts":  result,
			"version": importData.Version,
			"exportedAt": importData.ExportedAt,
		})
		return
	}

	// Track import stats
	imported := make(map[string]int)
	errors := []string{}

	// Import M3U Sources
	for _, src := range importData.M3USources {
		// Check if exists by name
		var existing models.M3USource
		if s.db.Where("name = ?", src.Name).First(&existing).Error == nil {
			// Update existing
			existing.URL = src.URL
			existing.EPGUrl = src.EPGUrl
			existing.Enabled = src.Enabled
			existing.ImportVOD = src.ImportVOD
			existing.ImportSeries = src.ImportSeries
			if err := s.db.Save(&existing).Error; err != nil {
				errors = append(errors, fmt.Sprintf("M3U %s: %v", src.Name, err))
			} else {
				imported["m3uSources"]++
			}
		} else {
			// Create new (without ID to let DB assign)
			newSrc := src.M3USource
			newSrc.ID = 0
			if err := s.db.Create(&newSrc).Error; err != nil {
				errors = append(errors, fmt.Sprintf("M3U %s: %v", src.Name, err))
			} else {
				imported["m3uSources"]++
			}
		}
	}

	// Import Xtream Sources
	for _, src := range importData.XtreamSources {
		var existing models.XtreamSource
		if s.db.Where("name = ?", src.Name).First(&existing).Error == nil {
			existing.ServerURL = src.ServerURL
			existing.Username = src.Username
			existing.Password = src.Password
			existing.Enabled = src.Enabled
			existing.ImportLive = src.ImportLive
			existing.ImportVOD = src.ImportVOD
			existing.ImportSeries = src.ImportSeries
			if err := s.db.Save(&existing).Error; err != nil {
				errors = append(errors, fmt.Sprintf("Xtream %s: %v", src.Name, err))
			} else {
				imported["xtreamSources"]++
			}
		} else {
			newSrc := models.XtreamSource{
				Name:         src.Name,
				ServerURL:    src.ServerURL,
				Username:     src.Username,
				Password:     src.Password,
				Enabled:      src.Enabled,
				ImportLive:   src.ImportLive,
				ImportVOD:    src.ImportVOD,
				ImportSeries: src.ImportSeries,
			}
			if err := s.db.Create(&newSrc).Error; err != nil {
				errors = append(errors, fmt.Sprintf("Xtream %s: %v", src.Name, err))
			} else {
				imported["xtreamSources"]++
			}
		}
	}

	// Import EPG Sources
	for _, src := range importData.EPGSources {
		var existing models.EPGSource
		if s.db.Where("name = ?", src.Name).First(&existing).Error == nil {
			existing.URL = src.URL
			existing.ProviderType = src.ProviderType
			existing.GracenoteAffiliate = src.GracenoteAffiliate
			existing.GracenotePostalCode = src.GracenotePostalCode
			existing.GracenoteHours = src.GracenoteHours
			existing.Enabled = src.Enabled
			existing.Priority = src.Priority
			if err := s.db.Save(&existing).Error; err != nil {
				errors = append(errors, fmt.Sprintf("EPG %s: %v", src.Name, err))
			} else {
				imported["epgSources"]++
			}
		} else {
			newSrc := src
			newSrc.ID = 0
			if err := s.db.Create(&newSrc).Error; err != nil {
				errors = append(errors, fmt.Sprintf("EPG %s: %v", src.Name, err))
			} else {
				imported["epgSources"]++
			}
		}
	}

	// Import Channels (match by name + source name)
	for _, ch := range importData.Channels {
		var existing models.Channel
		if s.db.Where("name = ? AND stream_url = ?", ch.Name, ch.StreamURL).First(&existing).Error == nil {
			// Update existing channel settings
			existing.Number = ch.Number
			existing.Logo = ch.Logo
			existing.Group = ch.Group
			existing.Enabled = ch.Enabled
			existing.ChannelID = ch.ChannelID
			existing.ArchiveEnabled = ch.ArchiveEnabled
			existing.ArchiveDays = ch.ArchiveDays
			if err := s.db.Save(&existing).Error; err != nil {
				errors = append(errors, fmt.Sprintf("Channel %s: %v", ch.Name, err))
			} else {
				imported["channels"]++
			}
		}
		// Don't create new channels - they come from M3U refresh
	}

	// Import Series Rules
	for _, rule := range importData.SeriesRules {
		var existing models.SeriesRule
		if s.db.Where("title = ? AND user_id = ?", rule.Title, rule.UserID).First(&existing).Error == nil {
			existing.Keywords = rule.Keywords
			existing.TimeSlot = rule.TimeSlot
			existing.DaysOfWeek = rule.DaysOfWeek
			existing.KeepCount = rule.KeepCount
			existing.PrePadding = rule.PrePadding
			existing.PostPadding = rule.PostPadding
			existing.Enabled = rule.Enabled
			if err := s.db.Save(&existing).Error; err != nil {
				errors = append(errors, fmt.Sprintf("SeriesRule %s: %v", rule.Title, err))
			} else {
				imported["seriesRules"]++
			}
		} else {
			newRule := rule
			newRule.ID = 0
			if err := s.db.Create(&newRule).Error; err != nil {
				errors = append(errors, fmt.Sprintf("SeriesRule %s: %v", rule.Title, err))
			} else {
				imported["seriesRules"]++
			}
		}
	}

	// Import Team Passes
	for _, pass := range importData.TeamPasses {
		var existing models.TeamPass
		if s.db.Where("team_name = ? AND league = ? AND user_id = ?", pass.TeamName, pass.League, pass.UserID).First(&existing).Error == nil {
			existing.TeamAliases = pass.TeamAliases
			existing.ChannelIDs = pass.ChannelIDs
			existing.PrePadding = pass.PrePadding
			existing.PostPadding = pass.PostPadding
			existing.KeepCount = pass.KeepCount
			existing.Priority = pass.Priority
			existing.Enabled = pass.Enabled
			if err := s.db.Save(&existing).Error; err != nil {
				errors = append(errors, fmt.Sprintf("TeamPass %s: %v", pass.TeamName, err))
			} else {
				imported["teamPasses"]++
			}
		} else {
			newPass := pass
			newPass.ID = 0
			if err := s.db.Create(&newPass).Error; err != nil {
				errors = append(errors, fmt.Sprintf("TeamPass %s: %v", pass.TeamName, err))
			} else {
				imported["teamPasses"]++
			}
		}
	}

	// Import Libraries
	for _, lib := range importData.Libraries {
		var existing models.Library
		if s.db.Where("title = ?", lib.Title).First(&existing).Error == nil {
			existing.Type = lib.Type
			existing.Agent = lib.Agent
			existing.Scanner = lib.Scanner
			existing.Language = lib.Language
			existing.Hidden = lib.Hidden
			if err := s.db.Save(&existing).Error; err != nil {
				errors = append(errors, fmt.Sprintf("Library %s: %v", lib.Title, err))
			} else {
				imported["libraries"]++
			}
		} else {
			newLib := lib.Library
			newLib.ID = 0
			newLib.Paths = nil
			if err := s.db.Create(&newLib).Error; err != nil {
				errors = append(errors, fmt.Sprintf("Library %s: %v", lib.Title, err))
			} else {
				// Add paths
				for _, path := range lib.Paths {
					s.db.Create(&models.LibraryPath{
						LibraryID: newLib.ID,
						Path:      path,
					})
				}
				imported["libraries"]++
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"imported": imported,
		"errors":   errors,
	})
}

// getConfigStats returns summary stats for the configuration
func (s *Server) getConfigStats(c *gin.Context) {
	var m3uCount, xtreamCount, epgCount, channelCount, groupCount int64
	var ruleCount, passCount, libCount, userCount int64

	s.db.Model(&models.M3USource{}).Count(&m3uCount)
	s.db.Model(&models.XtreamSource{}).Count(&xtreamCount)
	s.db.Model(&models.EPGSource{}).Count(&epgCount)
	s.db.Model(&models.Channel{}).Count(&channelCount)
	s.db.Model(&models.ChannelGroup{}).Count(&groupCount)
	s.db.Model(&models.SeriesRule{}).Count(&ruleCount)
	s.db.Model(&models.TeamPass{}).Count(&passCount)
	s.db.Model(&models.Library{}).Count(&libCount)
	s.db.Model(&models.User{}).Count(&userCount)

	c.JSON(http.StatusOK, gin.H{
		"m3uSources":    m3uCount,
		"xtreamSources": xtreamCount,
		"epgSources":    epgCount,
		"channels":      channelCount,
		"channelGroups": groupCount,
		"seriesRules":   ruleCount,
		"teamPasses":    passCount,
		"libraries":     libCount,
		"users":         userCount,
	})
}
