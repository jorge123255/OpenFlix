package api

import (
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/auth"
	"github.com/openflix/openflix-server/internal/library"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// Server identity - used by clients to identify this server
var (
	machineIdentifier = uuid.New().String()
	serverVersion     = "1.0.0"
	serverName        = "OpenFlix Server"
)

// ============ Server Info Handlers ============

func (s *Server) getServerInfo(c *gin.Context) {
	hostname, _ := os.Hostname()

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":              0,
			"machineIdentifier": machineIdentifier,
			"version":           serverVersion,
			"friendlyName":      serverName,
			"platform":          runtime.GOOS,
			"platformVersion":   runtime.Version(),
			"myPlex":            false,
			"myPlexMappingState": "unknown",
			"myPlexSigninState": "none",
			"transcoderActiveVideoSessions": 0,
		},
	})
	_ = hostname
}

func (s *Server) getServerIdentity(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":              0,
			"machineIdentifier": machineIdentifier,
			"version":           serverVersion,
		},
	})
}

func (s *Server) getServerPrefs(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size": 0,
			"Setting": []gin.H{
				{"id": "FriendlyName", "value": serverName},
				{"id": "MachineIdentifier", "value": machineIdentifier},
			},
		},
	})
}

// ============ Auth Handlers ============

func (s *Server) register(c *gin.Context) {
	// Check if signup is allowed
	if !s.config.Auth.AllowSignup {
		// Check if there are any users - allow first user regardless
		users, _ := s.authService.GetAllUsers()
		if len(users) > 0 {
			c.JSON(http.StatusForbidden, gin.H{"error": "Registration is disabled"})
			return
		}
	}

	var input auth.RegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := s.authService.Register(input)
	if err != nil {
		if errors.Is(err, auth.ErrUserExists) {
			c.JSON(http.StatusConflict, gin.H{"error": "Username or email already exists"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, response)
}

func (s *Server) login(c *gin.Context) {
	var input auth.LoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := s.authService.Login(input)
	if err != nil {
		if errors.Is(err, auth.ErrInvalidCredentials) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid username or password"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

func (s *Server) logout(c *gin.Context) {
	// JWT tokens are stateless, so just return success
	// In production, you might want to add token to a blacklist
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) getCurrentUser(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	user, err := s.authService.GetUserByID(userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       user.ID,
		"uuid":     user.UUID,
		"username": user.Username,
		"email":    user.Email,
		"title":    user.DisplayName,
		"thumb":    user.Thumb,
		"admin":    user.IsAdmin,
	})
}

func (s *Server) updateCurrentUser(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	var input auth.UpdateUserInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := s.authService.UpdateUser(userID.(uint), input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       user.ID,
		"uuid":     user.UUID,
		"username": user.Username,
		"email":    user.Email,
		"title":    user.DisplayName,
		"thumb":    user.Thumb,
		"admin":    user.IsAdmin,
	})
}

func (s *Server) changePassword(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	var input struct {
		OldPassword string `json:"oldPassword" binding:"required"`
		NewPassword string `json:"newPassword" binding:"required,min=6"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := s.authService.UpdatePassword(userID.(uint), input.OldPassword, input.NewPassword)
	if err != nil {
		if errors.Is(err, auth.ErrInvalidCredentials) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Current password is incorrect"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Profile Handlers ============

func (s *Server) getProfiles(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profiles, err := s.authService.GetUserProfiles(userID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	profileList := make([]gin.H, len(profiles))
	for i, p := range profiles {
		profileList[i] = gin.H{
			"id":    p.ID,
			"uuid":  p.UUID,
			"name":  p.Name,
			"thumb": p.Thumb,
			"isKid": p.IsKid,
		}
	}

	c.JSON(http.StatusOK, gin.H{"profiles": profileList})
}

func (s *Server) createProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	var input auth.CreateProfileInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, err := s.authService.CreateProfile(userID.(uint), input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":    profile.ID,
		"uuid":  profile.UUID,
		"name":  profile.Name,
		"thumb": profile.Thumb,
		"isKid": profile.IsKid,
	})
}

func (s *Server) getProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid profile ID"})
		return
	}

	profile, err := s.authService.GetProfile(uint(profileID), userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":    profile.ID,
		"uuid":  profile.UUID,
		"name":  profile.Name,
		"thumb": profile.Thumb,
		"isKid": profile.IsKid,
	})
}

func (s *Server) updateProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid profile ID"})
		return
	}

	var input auth.UpdateProfileInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, err := s.authService.UpdateProfile(uint(profileID), userID.(uint), input)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":    profile.ID,
		"uuid":  profile.UUID,
		"name":  profile.Name,
		"thumb": profile.Thumb,
		"isKid": profile.IsKid,
	})
}

func (s *Server) deleteProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid profile ID"})
		return
	}

	err = s.authService.DeleteProfile(uint(profileID), userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) switchProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid profile ID"})
		return
	}

	user, err := s.authService.GetUserByID(userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	token, err := s.authService.SwitchProfile(user, uint(profileID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"authToken": token})
}

// Plex-compatible auth endpoints

func (s *Server) createPin(c *gin.Context) {
	// Generate a PIN for authentication
	pin := s.authService.CreatePIN()
	c.JSON(http.StatusCreated, gin.H{
		"id":        pin.ID,
		"code":      pin.Code,
		"product":   "OpenFlix",
		"expiresAt": pin.ExpiresAt.Format(time.RFC3339),
		"authToken": pin.Token,
	})
}

func (s *Server) checkPin(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid PIN ID"})
		return
	}

	pin := s.authService.GetPIN(id)
	if pin == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "PIN not found"})
		return
	}

	if time.Now().After(pin.ExpiresAt) {
		c.JSON(http.StatusGone, gin.H{"error": "PIN expired"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":        pin.ID,
		"code":      pin.Code,
		"authToken": pin.Token, // Will be nil until claimed
	})
}

func (s *Server) getUser(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		// Return a default user for unauthenticated requests (dev mode)
		c.JSON(http.StatusOK, gin.H{
			"id":       0,
			"uuid":     uuid.New().String(),
			"username": "guest",
			"email":    "",
			"thumb":    "",
			"authToken": c.GetString("token"),
			"subscription": gin.H{
				"active": true,
			},
		})
		return
	}

	user, err := s.authService.GetUserByID(userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       user.ID,
		"uuid":     user.UUID,
		"username": user.Username,
		"email":    user.Email,
		"thumb":    user.Thumb,
		"authToken": c.GetString("token"),
		"subscription": gin.H{
			"active": true,
		},
	})
}

func (s *Server) getResources(c *gin.Context) {
	// Return this server as a resource
	c.JSON(http.StatusOK, []gin.H{
		{
			"name":             serverName,
			"product":          "OpenFlix Media Server",
			"productVersion":   serverVersion,
			"platform":         runtime.GOOS,
			"clientIdentifier": machineIdentifier,
			"accessToken":      c.GetString("token"),
			"provides":         "server",
			"owned":            true,
			"presence":         true,
			"connections": []gin.H{
				{
					"protocol": "http",
					"address":  s.config.Server.Host,
					"port":     s.config.Server.Port,
					"uri":      "http://" + s.config.Server.Host + ":32400",
					"local":    true,
					"relay":    false,
				},
			},
		},
	})
}

func (s *Server) getHomeUsers(c *gin.Context) {
	users, err := s.authService.GetAllUsers()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	userList := make([]gin.H, len(users))
	for i, user := range users {
		userList[i] = gin.H{
			"id":          user.ID,
			"uuid":        user.UUID,
			"title":       user.DisplayName,
			"username":    user.Username,
			"thumb":       user.Thumb,
			"hasPassword": user.HasPassword,
			"restricted":  user.IsRestricted,
			"admin":       user.IsAdmin,
			"guest":       false,
			"protected":   user.HasPassword,
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"id":    1,
		"name":  "OpenFlix Home",
		"users": userList,
	})
}

func (s *Server) switchUser(c *gin.Context) {
	userUUID := c.Param("uuid")

	// Get the user by UUID
	user, err := s.authService.GetUserByUUID(userUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Check if PIN is required
	pin := c.Query("pin")
	if user.HasPassword && user.PIN != "" && pin != user.PIN {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "PIN required"})
		return
	}

	// Generate new token for this user
	input := auth.LoginInput{
		Username: user.Username,
		Password: "", // Skip password check for user switch
	}
	_ = input // We'll generate token directly

	// For now, generate a simple token (in production, use proper auth flow)
	token, err := s.authService.SwitchProfile(user, 0)
	if err != nil {
		// Generate token using internal method
		c.JSON(http.StatusOK, gin.H{
			"authToken": "openflix-switch-" + userUUID,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"authToken": token,
	})
}

// ============ Library Handlers ============

func (s *Server) getLibrarySections(c *gin.Context) {
	libraries, err := s.libraryService.GetAllLibraries()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	sections := make([]gin.H, len(libraries))
	for i, lib := range libraries {
		// Get item count for this library
		count := s.libraryService.GetMediaItemCount(lib.ID)

		sections[i] = gin.H{
			"key":       strconv.Itoa(int(lib.ID)),
			"title":     lib.Title,
			"type":      lib.Type,
			"agent":     lib.Agent,
			"scanner":   lib.Scanner,
			"language":  lib.Language,
			"uuid":      lib.UUID,
			"updatedAt": lib.UpdatedAt.Unix(),
			"createdAt": lib.CreatedAt.Unix(),
			"count":     count,
		}
		if lib.ScannedAt != nil {
			sections[i]["scannedAt"] = lib.ScannedAt.Unix()
		}
	}
	s.respondWithDirectory(c, sections, len(sections))
}

func (s *Server) getLibraryContent(c *gin.Context) {
	libraryID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	offset, limit := s.getPaginationParams(c)

	// Get the library to determine its type
	lib, err := s.libraryService.GetLibrary(uint(libraryID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
		return
	}

	// Determine what type of items to fetch based on library type
	var itemTypes []string
	switch lib.Type {
	case "movie":
		itemTypes = []string{"movie"}
	case "show":
		itemTypes = []string{"show"} // For shows, return top-level shows
	default:
		itemTypes = []string{lib.Type}
	}

	// Get total count
	var totalCount int64
	s.db.Model(&models.MediaItem{}).
		Where("library_id = ? AND type IN ?", libraryID, itemTypes).
		Count(&totalCount)

	// Get paginated items
	var items []models.MediaItem
	query := s.db.Where("library_id = ? AND type IN ?", libraryID, itemTypes).
		Preload("MediaFiles").
		Preload("Genres").
		Order("sort_title ASC").
		Offset(offset).
		Limit(limit)

	if err := query.Find(&items).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Convert to Plex-compatible format
	metadata := make([]gin.H, len(items))
	for i, item := range items {
		metadata[i] = s.mediaItemToMetadata(&item, lib)
	}

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":             len(metadata),
			"totalSize":        totalCount,
			"offset":           offset,
			"librarySectionID": libraryID,
			"Metadata":         metadata,
		},
	})
}

func (s *Server) getLibraryFilters(c *gin.Context) {
	filters := []gin.H{
		{"filter": "genre", "filterType": "string", "title": "Genre"},
		{"filter": "year", "filterType": "integer", "title": "Year"},
		{"filter": "contentRating", "filterType": "string", "title": "Content Rating"},
		{"filter": "resolution", "filterType": "string", "title": "Resolution"},
	}
	s.respondWithDirectory(c, filters, len(filters))
}

func (s *Server) getLibrarySorts(c *gin.Context) {
	sorts := []gin.H{
		{"key": "titleSort", "title": "Title"},
		{"key": "addedAt:desc", "title": "Date Added"},
		{"key": "year:desc", "title": "Release Date"},
		{"key": "rating:desc", "title": "Rating"},
	}
	s.respondWithDirectory(c, sorts, len(sorts))
}

func (s *Server) getLibraryCollections(c *gin.Context) {
	// TODO: Return collections from database
	s.respondWithMediaContainer(c, []gin.H{}, 0, 0, 0)
}

func (s *Server) refreshLibrary(c *gin.Context) {
	libraryID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	lib, err := s.libraryService.GetLibrary(uint(libraryID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
		return
	}

	// Trigger scan in background
	go func() {
		s.scanner.ScanLibrary(lib)
	}()

	c.JSON(http.StatusOK, gin.H{"status": "scanning"})
}

func (s *Server) getLibraryFolders(c *gin.Context) {
	// TODO: Return folder structure
	s.respondWithMediaContainer(c, []gin.H{}, 0, 0, 0)
}

func (s *Server) getLibraryHubs(c *gin.Context) {
	// TODO: Return recommendation hubs
	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size": 0,
			"Hub":  []gin.H{},
		},
	})
}

// ============ Helper Functions ============

// mediaItemToMetadata converts a MediaItem to Plex-compatible metadata format
func (s *Server) mediaItemToMetadata(item *models.MediaItem, lib *models.Library) gin.H {
	metadata := gin.H{
		"ratingKey":        item.ID,
		"key":              fmt.Sprintf("/library/metadata/%d", item.ID),
		"guid":             item.UUID,
		"type":             item.Type,
		"title":            item.Title,
		"librarySectionID": item.LibraryID,
		"addedAt":          item.AddedAt.Unix(),
		"updatedAt":        item.UpdatedAt.Unix(),
	}

	// Add optional fields if present
	if item.OriginalTitle != "" {
		metadata["originalTitle"] = item.OriginalTitle
	}
	if item.SortTitle != "" {
		metadata["titleSort"] = item.SortTitle
	}
	if item.Summary != "" {
		metadata["summary"] = item.Summary
	}
	if item.Tagline != "" {
		metadata["tagline"] = item.Tagline
	}
	if item.ContentRating != "" {
		metadata["contentRating"] = item.ContentRating
	}
	if item.Studio != "" {
		metadata["studio"] = item.Studio
	}
	if item.Year > 0 {
		metadata["year"] = item.Year
	}
	if item.Duration > 0 {
		metadata["duration"] = item.Duration
	}
	if item.Rating > 0 {
		metadata["rating"] = item.Rating
	}
	if item.AudienceRating > 0 {
		metadata["audienceRating"] = item.AudienceRating
	}
	if item.Thumb != "" {
		metadata["thumb"] = item.Thumb
	} else {
		// Generate placeholder thumb URL
		metadata["thumb"] = fmt.Sprintf("/library/metadata/%d/thumb", item.ID)
	}
	if item.Art != "" {
		metadata["art"] = item.Art
	}

	// Add hierarchy info for episodes/seasons
	if item.ParentID != nil {
		metadata["parentRatingKey"] = *item.ParentID
		metadata["parentKey"] = fmt.Sprintf("/library/metadata/%d", *item.ParentID)
	}
	if item.GrandparentID != nil {
		metadata["grandparentRatingKey"] = *item.GrandparentID
		metadata["grandparentKey"] = fmt.Sprintf("/library/metadata/%d", *item.GrandparentID)
	}
	if item.Index > 0 {
		metadata["index"] = item.Index
	}
	if item.ParentIndex > 0 {
		metadata["parentIndex"] = item.ParentIndex
	}
	if item.ParentTitle != "" {
		metadata["parentTitle"] = item.ParentTitle
	}
	if item.GrandparentTitle != "" {
		metadata["grandparentTitle"] = item.GrandparentTitle
	}
	if item.ParentThumb != "" {
		metadata["parentThumb"] = item.ParentThumb
	}
	if item.GrandparentThumb != "" {
		metadata["grandparentThumb"] = item.GrandparentThumb
	}

	// Add child/leaf counts for shows/seasons
	if item.ChildCount > 0 {
		metadata["childCount"] = item.ChildCount
	}
	if item.LeafCount > 0 {
		metadata["leafCount"] = item.LeafCount
	}
	if item.ViewedLeafCount > 0 {
		metadata["viewedLeafCount"] = item.ViewedLeafCount
	}

	// Add genres
	if len(item.Genres) > 0 {
		genres := make([]gin.H, len(item.Genres))
		for i, genre := range item.Genres {
			genres[i] = gin.H{"tag": genre.Tag}
		}
		metadata["Genre"] = genres
	}

	// Add media files
	if len(item.MediaFiles) > 0 {
		media := make([]gin.H, len(item.MediaFiles))
		for i, file := range item.MediaFiles {
			media[i] = gin.H{
				"id":         file.ID,
				"duration":   file.Duration,
				"bitrate":    file.Bitrate,
				"width":      file.Width,
				"height":     file.Height,
				"container":  file.Container,
				"videoCodec": file.VideoCodec,
				"audioCodec": file.AudioCodec,
				"Part": []gin.H{
					{
						"id":        file.ID,
						"key":       fmt.Sprintf("/library/parts/%d/file", file.ID),
						"duration":  file.Duration,
						"file":      file.FilePath,
						"size":      file.FileSize,
						"container": file.Container,
					},
				},
			}
		}
		metadata["Media"] = media
	}

	return metadata
}

// ============ Metadata Handlers ============

func (s *Server) getMetadata(c *gin.Context) {
	key, err := strconv.ParseUint(c.Param("key"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid metadata key"})
		return
	}

	var item models.MediaItem
	if err := s.db.Preload("MediaFiles").Preload("Genres").Preload("Cast").First(&item, key).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	lib, _ := s.libraryService.GetLibrary(item.LibraryID)

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":     1,
			"Metadata": []gin.H{s.mediaItemToMetadata(&item, lib)},
		},
	})
}

func (s *Server) getMetadataChildren(c *gin.Context) {
	key, err := strconv.ParseUint(c.Param("key"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid metadata key"})
		return
	}

	// Get the parent item
	var parent models.MediaItem
	if err := s.db.First(&parent, key).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	lib, _ := s.libraryService.GetLibrary(parent.LibraryID)

	// Get children (seasons for shows, episodes for seasons)
	var children []models.MediaItem
	if err := s.db.Where("parent_id = ?", key).
		Preload("MediaFiles").
		Order("`index` ASC").
		Find(&children).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	metadata := make([]gin.H, len(children))
	for i, child := range children {
		// Add parent info to each child
		child.ParentTitle = parent.Title
		if parent.Type == "season" {
			child.ParentIndex = parent.Index
			// Get grandparent (show) info
			if parent.ParentID != nil {
				var show models.MediaItem
				if err := s.db.First(&show, parent.ParentID).Error; err == nil {
					child.GrandparentTitle = show.Title
					child.GrandparentThumb = show.Thumb
				}
			}
		}
		metadata[i] = s.mediaItemToMetadata(&child, lib)
	}

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":                  len(metadata),
			"key":                   fmt.Sprintf("/library/metadata/%d/children", key),
			"parentRatingKey":       parent.ID,
			"parentTitle":           parent.Title,
			"parentYear":            parent.Year,
			"librarySectionID":      parent.LibraryID,
			"Metadata":              metadata,
		},
	})
}

func (s *Server) setMetadataPrefs(c *gin.Context) {
	// TODO: Set audio/subtitle preferences
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) selectStreams(c *gin.Context) {
	// TODO: Select audio/subtitle streams
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Browsing Handlers ============

func (s *Server) getRecentlyAdded(c *gin.Context) {
	offset, limit := s.getPaginationParams(c)
	if limit > 100 {
		limit = 100
	}

	// Get recently added movies and episodes (not shows/seasons which are containers)
	var items []models.MediaItem
	if err := s.db.Where("type IN ?", []string{"movie", "episode"}).
		Preload("MediaFiles").
		Order("added_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&items).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	metadata := make([]gin.H, len(items))
	for i, item := range items {
		lib, _ := s.libraryService.GetLibrary(item.LibraryID)
		metadata[i] = s.mediaItemToMetadata(&item, lib)
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), 0, offset)
}

func (s *Server) getOnDeck(c *gin.Context) {
	userID := c.GetUint("userID")

	// Get items with progress that are not completed
	var histories []models.WatchHistory
	s.db.Where("user_id = ? AND completed = ? AND view_offset > 0", userID, false).
		Order("last_viewed_at DESC").
		Limit(20).
		Find(&histories)

	if len(histories) == 0 {
		s.respondWithMediaContainer(c, []gin.H{}, 0, 0, 0)
		return
	}

	// Get the media item IDs
	itemIDs := make([]uint, len(histories))
	historyMap := make(map[uint]models.WatchHistory)
	for i, h := range histories {
		itemIDs[i] = h.MediaItemID
		historyMap[h.MediaItemID] = h
	}

	// Fetch the media items
	var items []models.MediaItem
	s.db.Preload("Files").Where("id IN ?", itemIDs).Find(&items)

	// Build response with view offset
	metadata := make([]gin.H, 0, len(items))
	for _, item := range items {
		var lib models.Library
		s.db.First(&lib, item.LibraryID)

		m := s.mediaItemToMetadata(&item, &lib)
		// Add view offset from history
		if h, ok := historyMap[item.ID]; ok {
			m["viewOffset"] = h.ViewOffset
		}
		metadata = append(metadata, m)
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), len(metadata), 0)
}

func (s *Server) search(c *gin.Context) {
	query := c.Query("query")
	_ = query
	// TODO: Implement search
	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size": 0,
			"Hub":  []gin.H{},
		},
	})
}

// ============ Playback Handlers ============

func (s *Server) markWatched(c *gin.Context) {
	keyStr := c.Query("key")
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	userID := c.GetUint("userID")

	// Get or create watch history
	var history models.WatchHistory
	result := s.db.Where("user_id = ? AND media_item_id = ?", userID, key).First(&history)

	if result.Error != nil {
		// Create new history
		history = models.WatchHistory{
			UserID:       userID,
			MediaItemID:  uint(key),
			ViewCount:    1,
			LastViewedAt: time.Now(),
			Completed:    true,
		}
		s.db.Create(&history)
	} else {
		// Update existing
		s.db.Model(&history).Updates(map[string]interface{}{
			"view_count":     history.ViewCount + 1,
			"last_viewed_at": time.Now(),
			"completed":      true,
			"view_offset":    0, // Reset offset since it's complete
		})
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) markUnwatched(c *gin.Context) {
	keyStr := c.Query("key")
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	userID := c.GetUint("userID")

	// Delete watch history
	s.db.Where("user_id = ? AND media_item_id = ?", userID, key).Delete(&models.WatchHistory{})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) updateTimeline(c *gin.Context) {
	keyStr := c.Query("ratingKey")
	if keyStr == "" {
		keyStr = c.Query("key")
	}
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	// Get time/offset from query params
	timeStr := c.Query("time")
	offset, _ := strconv.ParseInt(timeStr, 10, 64)

	// Get duration for calculating completion
	durationStr := c.Query("duration")
	duration, _ := strconv.ParseInt(durationStr, 10, 64)

	// Check if state is stopped or playing
	state := c.Query("state")

	userID := c.GetUint("userID")

	// Determine if completed (watched 90% or more)
	completed := false
	if duration > 0 && offset > 0 {
		progress := float64(offset) / float64(duration)
		completed = progress >= 0.9
	}

	// Get or create watch history
	var history models.WatchHistory
	result := s.db.Where("user_id = ? AND media_item_id = ?", userID, key).First(&history)

	if result.Error != nil {
		// Create new history
		history = models.WatchHistory{
			UserID:       userID,
			MediaItemID:  uint(key),
			ViewOffset:   offset,
			ViewCount:    0,
			LastViewedAt: time.Now(),
			Completed:    completed,
		}
		s.db.Create(&history)
	} else {
		updates := map[string]interface{}{
			"view_offset":    offset,
			"last_viewed_at": time.Now(),
		}
		if completed && !history.Completed {
			updates["completed"] = true
			updates["view_count"] = history.ViewCount + 1
		}
		s.db.Model(&history).Updates(updates)
	}

	// If stopped and completed, increment view count
	if state == "stopped" && completed {
		s.db.Model(&history).Update("view_count", history.ViewCount+1)
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) removeFromContinueWatching(c *gin.Context) {
	keyStr := c.Query("ratingKey")
	if keyStr == "" {
		keyStr = c.Query("key")
	}
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	userID := c.GetUint("userID")

	// Mark as completed to remove from continue watching
	s.db.Model(&models.WatchHistory{}).
		Where("user_id = ? AND media_item_id = ?", userID, key).
		Updates(map[string]interface{}{
			"completed":   true,
			"view_offset": 0,
		})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) getSessions(c *gin.Context) {
	// TODO: Return active playback sessions
	s.respondWithMediaContainer(c, []gin.H{}, 0, 0, 0)
}

// ============ Playlist Handlers ============

func (s *Server) getPlaylists(c *gin.Context) {
	userID := c.GetUint("userID")

	var playlists []models.Playlist
	s.db.Where("user_id = ?", userID).Find(&playlists)

	metadata := make([]gin.H, len(playlists))
	for i, p := range playlists {
		metadata[i] = gin.H{
			"ratingKey":    p.ID,
			"key":          fmt.Sprintf("/playlists/%d/items", p.ID),
			"guid":         p.UUID,
			"type":         "playlist",
			"title":        p.Title,
			"summary":      p.Summary,
			"playlistType": p.PlaylistType,
			"smart":        p.Smart,
			"leafCount":    p.LeafCount,
			"duration":     p.Duration,
			"addedAt":      p.AddedAt.Unix(),
			"updatedAt":    p.UpdatedAt.Unix(),
		}
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), len(metadata), 0)
}

func (s *Server) createPlaylist(c *gin.Context) {
	userID := c.GetUint("userID")

	title := c.Query("title")
	if title == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Title is required"})
		return
	}

	playlistType := c.Query("type")
	if playlistType == "" {
		playlistType = "video"
	}

	playlist := models.Playlist{
		UUID:         uuid.New().String(),
		UserID:       userID,
		Title:        title,
		PlaylistType: playlistType,
		AddedAt:      time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := s.db.Create(&playlist).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// If items provided, add them
	if uri := c.Query("uri"); uri != "" {
		// Parse server://uuid/com.plexapp.plugins.library/library/metadata/123
		// or just the key number
		parts := strings.Split(uri, "/")
		if len(parts) > 0 {
			keyStr := parts[len(parts)-1]
			if key, err := strconv.Atoi(keyStr); err == nil {
				item := models.PlaylistItem{
					PlaylistID:  playlist.ID,
					MediaItemID: uint(key),
					Order:       0,
				}
				s.db.Create(&item)
				playlist.LeafCount = 1
				s.db.Save(&playlist)
			}
		}
	}

	c.JSON(http.StatusCreated, gin.H{
		"MediaContainer": gin.H{
			"size": 1,
			"Metadata": []gin.H{{
				"ratingKey":    playlist.ID,
				"key":          fmt.Sprintf("/playlists/%d/items", playlist.ID),
				"guid":         playlist.UUID,
				"type":         "playlist",
				"title":        playlist.Title,
				"playlistType": playlist.PlaylistType,
				"leafCount":    playlist.LeafCount,
			}},
		},
	})
}

func (s *Server) getPlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	var playlist models.Playlist
	if err := s.db.First(&playlist, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Playlist not found"})
		return
	}

	metadata := []gin.H{{
		"ratingKey":    playlist.ID,
		"key":          fmt.Sprintf("/playlists/%d/items", playlist.ID),
		"guid":         playlist.UUID,
		"type":         "playlist",
		"title":        playlist.Title,
		"summary":      playlist.Summary,
		"playlistType": playlist.PlaylistType,
		"smart":        playlist.Smart,
		"leafCount":    playlist.LeafCount,
		"duration":     playlist.Duration,
		"addedAt":      playlist.AddedAt.Unix(),
		"updatedAt":    playlist.UpdatedAt.Unix(),
	}}

	s.respondWithMediaContainer(c, metadata, 1, 1, 0)
}

func (s *Server) getPlaylistItems(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	var items []models.PlaylistItem
	s.db.Where("playlist_id = ?", id).Order("`order` ASC").Find(&items)

	if len(items) == 0 {
		s.respondWithMediaContainer(c, []gin.H{}, 0, 0, 0)
		return
	}

	// Get media item IDs
	itemIDs := make([]uint, len(items))
	for i, item := range items {
		itemIDs[i] = item.MediaItemID
	}

	// Fetch media items
	var mediaItems []models.MediaItem
	s.db.Preload("Files").Where("id IN ?", itemIDs).Find(&mediaItems)

	// Build map for lookup
	mediaMap := make(map[uint]models.MediaItem)
	for _, m := range mediaItems {
		mediaMap[m.ID] = m
	}

	// Build response
	metadata := make([]gin.H, 0, len(items))
	for _, item := range items {
		if mi, ok := mediaMap[item.MediaItemID]; ok {
			var lib models.Library
			s.db.First(&lib, mi.LibraryID)
			m := s.mediaItemToMetadata(&mi, &lib)
			m["playlistItemID"] = item.ID
			metadata = append(metadata, m)
		}
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), len(metadata), 0)
}

func (s *Server) addToPlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	uri := c.Query("uri")
	if uri == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "URI is required"})
		return
	}

	// Parse the key from URI
	parts := strings.Split(uri, "/")
	keyStr := parts[len(parts)-1]
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid URI"})
		return
	}

	// Get current max order
	var maxOrder int
	s.db.Model(&models.PlaylistItem{}).Where("playlist_id = ?", id).Select("COALESCE(MAX(`order`), -1)").Scan(&maxOrder)

	// Create playlist item
	item := models.PlaylistItem{
		PlaylistID:  uint(id),
		MediaItemID: uint(key),
		Order:       maxOrder + 1,
	}
	s.db.Create(&item)

	// Update playlist counts
	var playlist models.Playlist
	s.db.First(&playlist, id)
	s.db.Model(&playlist).Updates(map[string]interface{}{
		"leaf_count": playlist.LeafCount + 1,
		"updated_at": time.Now(),
	})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) removeFromPlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	itemIDStr := c.Param("itemId")
	itemID, err := strconv.Atoi(itemIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	s.db.Delete(&models.PlaylistItem{}, itemID)

	// Update playlist counts
	var playlist models.Playlist
	s.db.First(&playlist, id)
	if playlist.LeafCount > 0 {
		s.db.Model(&playlist).Updates(map[string]interface{}{
			"leaf_count": playlist.LeafCount - 1,
			"updated_at": time.Now(),
		})
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) movePlaylistItem(c *gin.Context) {
	itemIDStr := c.Param("itemId")
	itemID, err := strconv.Atoi(itemIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	afterStr := c.Query("after")
	afterID, _ := strconv.Atoi(afterStr)

	var item models.PlaylistItem
	if err := s.db.First(&item, itemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	// Get the order of the item after which to place
	newOrder := 0
	if afterID > 0 {
		var afterItem models.PlaylistItem
		if err := s.db.First(&afterItem, afterID).Error; err == nil {
			newOrder = afterItem.Order + 1
		}
	}

	// Update orders
	s.db.Model(&models.PlaylistItem{}).
		Where("playlist_id = ? AND `order` >= ?", item.PlaylistID, newOrder).
		Update("order", gorm.Expr("`order` + 1"))

	s.db.Model(&item).Update("order", newOrder)

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) clearPlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	s.db.Where("playlist_id = ?", id).Delete(&models.PlaylistItem{})

	// Update playlist
	s.db.Model(&models.Playlist{}).Where("id = ?", id).Updates(map[string]interface{}{
		"leaf_count": 0,
		"duration":   0,
		"updated_at": time.Now(),
	})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) deletePlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	userID := c.GetUint("userID")

	// Delete items first
	s.db.Where("playlist_id = ?", id).Delete(&models.PlaylistItem{})

	// Delete playlist (soft delete)
	s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Playlist{})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Collection Handlers ============

func (s *Server) getCollectionItems(c *gin.Context) {
	s.respondWithMediaContainer(c, []gin.H{}, 0, 0, 0)
}

func (s *Server) createCollection(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"ratingKey": "1"})
}

func (s *Server) addToCollection(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) removeFromCollection(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) deleteCollection(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Play Queue Handlers ============

func (s *Server) createPlayQueue(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{
		"MediaContainer": gin.H{
			"playQueueID":       1,
			"playQueueVersion":  1,
			"playQueueShuffled": false,
			"size":              0,
			"Metadata":          []gin.H{},
		},
	})
}

func (s *Server) getPlayQueue(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"playQueueID":       c.Param("id"),
			"playQueueVersion":  1,
			"playQueueShuffled": false,
			"size":              0,
			"Metadata":          []gin.H{},
		},
	})
}

func (s *Server) shufflePlayQueue(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) clearPlayQueue(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Media Streaming Handlers ============

func (s *Server) streamMedia(c *gin.Context) {
	partIDStr := c.Param("partId")
	partID, err := strconv.Atoi(partIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid part ID"})
		return
	}

	// Get the media file
	var file models.MediaFile
	if err := s.db.First(&file, partID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media file not found"})
		return
	}

	// Check if file exists on disk
	if _, err := os.Stat(file.FilePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found on disk"})
		return
	}

	// Determine content type based on container
	contentType := "video/mp4"
	switch file.Container {
	case "mkv":
		contentType = "video/x-matroska"
	case "avi":
		contentType = "video/x-msvideo"
	case "mov":
		contentType = "video/quicktime"
	case "webm":
		contentType = "video/webm"
	case "ts", "m2ts":
		contentType = "video/mp2t"
	}

	// Set headers for streaming
	c.Header("Content-Type", contentType)
	c.Header("Accept-Ranges", "bytes")

	// Serve file with range request support
	c.File(file.FilePath)
}

func (s *Server) transcodeStart(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	// Get parameters
	path := c.Query("path")
	if path == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Path is required"})
		return
	}

	// Parse media key from path (e.g., /library/metadata/123)
	parts := strings.Split(path, "/")
	var mediaKey int
	for i, p := range parts {
		if p == "metadata" && i+1 < len(parts) {
			mediaKey, _ = strconv.Atoi(parts[i+1])
			break
		}
	}

	if mediaKey == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid path"})
		return
	}

	// Get media item
	var item models.MediaItem
	if err := s.db.First(&item, mediaKey).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media not found"})
		return
	}

	// Get media file
	var file models.MediaFile
	if err := s.db.Where("media_item_id = ?", mediaKey).First(&file).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No media file found"})
		return
	}

	// Get quality/offset parameters
	offset, _ := strconv.ParseInt(c.Query("offset"), 10, 64)
	quality := c.DefaultQuery("videoQuality", "original")

	// Start transcode session
	session, err := s.transcoder.StartSession(file.ID, file.FilePath, offset, quality)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Wait a moment for transcoding to start and generate initial segment
	time.Sleep(500 * time.Millisecond)

	// Return HLS playlist
	playlistPath := s.transcoder.GetPlaylistPath(session.ID)
	c.Header("Content-Type", "application/vnd.apple.mpegurl")
	c.File(playlistPath)
}

func (s *Server) transcodeSegment(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	sessionID := c.Param("sessionId")
	segment := c.Param("segment")

	// Validate session
	session := s.transcoder.GetSession(sessionID)
	if session == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	// Update last access time
	s.transcoder.UpdateLastAccess(sessionID)

	// Get segment path
	segmentPath := s.transcoder.GetSegmentPath(sessionID, segment)

	// Wait for segment to be available (with timeout)
	timeout := time.After(30 * time.Second)
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-timeout:
			c.JSON(http.StatusRequestTimeout, gin.H{"error": "Segment not available"})
			return
		case <-ticker.C:
			if _, err := os.Stat(segmentPath); err == nil {
				c.Header("Content-Type", "video/mp2t")
				c.File(segmentPath)
				return
			}
		case <-session.Done:
			if session.Error != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Transcode failed"})
				return
			}
			// Check one more time
			if _, err := os.Stat(segmentPath); err == nil {
				c.Header("Content-Type", "video/mp2t")
				c.File(segmentPath)
				return
			}
			c.JSON(http.StatusNotFound, gin.H{"error": "Segment not found"})
			return
		}
	}
}

func (s *Server) getThumb(c *gin.Context) {
	keyStr := c.Param("key")
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	// Get media item
	var item models.MediaItem
	if err := s.db.First(&item, key).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	// If no thumb URL, return 404
	if item.Thumb == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "No poster available"})
		return
	}

	// Check if we have a local copy
	dataDir := s.config.GetDataDir()
	localPath := filepath.Join(dataDir, "metadata", "posters", fmt.Sprintf("%d.jpg", item.ID))

	if _, err := os.Stat(localPath); err == nil {
		// Serve local file
		c.Header("Cache-Control", "public, max-age=86400")
		c.File(localPath)
		return
	}

	// Redirect to TMDB URL
	// Convert relative TMDB path to full URL if needed
	posterURL := item.Thumb
	if strings.HasPrefix(posterURL, "/") {
		posterURL = "https://image.tmdb.org/t/p/w500" + posterURL
	}

	c.Redirect(http.StatusTemporaryRedirect, posterURL)
}

func (s *Server) getArt(c *gin.Context) {
	keyStr := c.Param("key")
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	// Get media item
	var item models.MediaItem
	if err := s.db.First(&item, key).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	// If no art URL, return 404
	if item.Art == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "No art available"})
		return
	}

	// Check if we have a local copy
	dataDir := s.config.GetDataDir()
	localPath := filepath.Join(dataDir, "metadata", "backdrops", fmt.Sprintf("%d.jpg", item.ID))

	if _, err := os.Stat(localPath); err == nil {
		// Serve local file
		c.Header("Cache-Control", "public, max-age=86400")
		c.File(localPath)
		return
	}

	// Redirect to TMDB URL
	// Convert relative TMDB path to full URL if needed
	artURL := item.Art
	if strings.HasPrefix(artURL, "/") {
		artURL = "https://image.tmdb.org/t/p/original" + artURL
	}

	c.Redirect(http.StatusTemporaryRedirect, artURL)
}

// ============ Admin Library Management Handlers ============

func (s *Server) adminGetLibraries(c *gin.Context) {
	libraries, err := s.libraryService.GetAllLibraries()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	result := make([]gin.H, len(libraries))
	for i, lib := range libraries {
		paths := make([]gin.H, len(lib.Paths))
		for j, p := range lib.Paths {
			paths[j] = gin.H{"id": p.ID, "path": p.Path}
		}

		result[i] = gin.H{
			"id":        lib.ID,
			"uuid":      lib.UUID,
			"title":     lib.Title,
			"type":      lib.Type,
			"agent":     lib.Agent,
			"scanner":   lib.Scanner,
			"language":  lib.Language,
			"hidden":    lib.Hidden,
			"paths":     paths,
			"itemCount": s.libraryService.GetMediaItemCount(lib.ID),
			"createdAt": lib.CreatedAt.Unix(),
			"updatedAt": lib.UpdatedAt.Unix(),
		}
		if lib.ScannedAt != nil {
			result[i]["scannedAt"] = lib.ScannedAt.Unix()
		}
	}

	c.JSON(http.StatusOK, gin.H{"libraries": result})
}

func (s *Server) adminCreateLibrary(c *gin.Context) {
	var input library.CreateLibraryInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	lib, err := s.libraryService.CreateLibrary(input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	paths := make([]gin.H, len(lib.Paths))
	for i, p := range lib.Paths {
		paths[i] = gin.H{"id": p.ID, "path": p.Path}
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":       lib.ID,
		"uuid":     lib.UUID,
		"title":    lib.Title,
		"type":     lib.Type,
		"agent":    lib.Agent,
		"scanner":  lib.Scanner,
		"language": lib.Language,
		"paths":    paths,
	})
}

func (s *Server) adminGetLibrary(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	lib, err := s.libraryService.GetLibrary(uint(id))
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	paths := make([]gin.H, len(lib.Paths))
	for i, p := range lib.Paths {
		paths[i] = gin.H{"id": p.ID, "path": p.Path}
	}

	c.JSON(http.StatusOK, gin.H{
		"id":        lib.ID,
		"uuid":      lib.UUID,
		"title":     lib.Title,
		"type":      lib.Type,
		"agent":     lib.Agent,
		"scanner":   lib.Scanner,
		"language":  lib.Language,
		"hidden":    lib.Hidden,
		"paths":     paths,
		"itemCount": s.libraryService.GetMediaItemCount(lib.ID),
	})
}

func (s *Server) adminUpdateLibrary(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	var input library.UpdateLibraryInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	lib, err := s.libraryService.UpdateLibrary(uint(id), input)
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       lib.ID,
		"uuid":     lib.UUID,
		"title":    lib.Title,
		"type":     lib.Type,
		"language": lib.Language,
		"hidden":   lib.Hidden,
	})
}

func (s *Server) adminDeleteLibrary(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	err = s.libraryService.DeleteLibrary(uint(id))
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) adminAddLibraryPath(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	var input struct {
		Path string `json:"path" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = s.libraryService.AddPath(uint(id), input.Path)
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		if errors.Is(err, library.ErrInvalidPath) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid path - must be an absolute path to an existing directory"})
			return
		}
		if errors.Is(err, library.ErrPathExists) {
			c.JSON(http.StatusConflict, gin.H{"error": "Path already exists in library"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return updated library
	lib, _ := s.libraryService.GetLibrary(uint(id))
	paths := make([]gin.H, len(lib.Paths))
	for i, p := range lib.Paths {
		paths[i] = gin.H{"id": p.ID, "path": p.Path}
	}

	c.JSON(http.StatusOK, gin.H{"paths": paths})
}

func (s *Server) adminRemoveLibraryPath(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	pathId, err := strconv.ParseUint(c.Param("pathId"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid path ID"})
		return
	}

	err = s.libraryService.RemovePath(uint(id), uint(pathId))
	if err != nil {
		if errors.Is(err, library.ErrPathNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Path not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) adminScanLibrary(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	lib, err := s.libraryService.GetLibrary(uint(id))
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Run scan (this could be async in production)
	result, err := s.scanner.ScanLibrary(lib)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"libraryId":    result.LibraryID,
		"filesFound":   result.FilesFound,
		"filesAdded":   result.FilesAdded,
		"filesUpdated": result.FilesUpdated,
		"filesRemoved": result.FilesRemoved,
		"errors":       result.Errors,
	})
}
