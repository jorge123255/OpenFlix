package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/auth"
	"github.com/openflix/openflix-server/internal/models"
)

// parentalControlMiddleware enforces content rating restrictions based on the
// active user profile. It checks the profile's MaxRating and the user's
// IsRestricted flag.
//
// Behavior:
//   - If the active profile has a MaxRating set, all content lookups by rating
//     key are checked against that limit.
//   - If the user is flagged as IsRestricted, a valid PIN session is required
//     to access content above the profile's MaxRating.
//   - Returns 403 Forbidden if content exceeds the allowed rating and no valid
//     PIN session exists.
//   - Unrated content (empty ContentRating) is allowed through.
//   - Sets "parentalMaxRating" in the Gin context for downstream handlers to
//     use for list filtering.
func (s *Server) parentalControlMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Skip for local access without auth
		if isLocal, exists := c.Get("isLocalAccess"); exists && isLocal.(bool) {
			c.Next()
			return
		}

		userID, exists := c.Get("userID")
		if !exists {
			c.Next()
			return
		}

		uid, ok := userID.(uint)
		if !ok || uid == 0 {
			c.Next()
			return
		}

		// Get the profile ID from JWT claims
		var profileID uint
		if claimsRaw, exists := c.Get("claims"); exists {
			if claims, ok := claimsRaw.(*auth.Claims); ok {
				profileID = claims.ProfileID
			}
		}

		// Load user to check IsRestricted
		var user models.User
		if err := s.db.First(&user, uid).Error; err != nil {
			c.Next()
			return
		}

		// Determine the effective max rating
		var maxRating string
		var isKidProfile bool

		if profileID > 0 {
			var profile models.UserProfile
			if err := s.db.Where("id = ? AND user_id = ?", profileID, uid).First(&profile).Error; err == nil {
				maxRating = profile.MaxRating
				isKidProfile = profile.IsKid
			}
		}

		// Kid profiles without an explicit MaxRating default to TV-PG
		if isKidProfile && maxRating == "" {
			maxRating = "TV-PG"
		}

		// If no restrictions apply, let the request through
		if maxRating == "" && !user.IsRestricted {
			c.Next()
			return
		}

		// Store the max rating in context so downstream handlers can filter lists
		if maxRating != "" {
			c.Set("parentalMaxRating", maxRating)
		}
		c.Set("parentalIsKid", isKidProfile)
		c.Set("parentalIsRestricted", user.IsRestricted)

		// Check if there's a valid PIN session that overrides restrictions
		token, _ := c.Get("token")
		tokenStr, _ := token.(string)
		if tokenStr != "" && isParentalSessionValid(tokenStr, uid) {
			// PIN verified - allow everything but still pass the context info
			c.Set("parentalPINVerified", true)
			c.Next()
			return
		}

		// For single-item endpoints (e.g., /library/metadata/:key), check the
		// content rating of the requested item against the profile's max rating.
		if maxRating != "" {
			if ratingKey := c.Param("key"); ratingKey != "" {
				itemID, err := strconv.ParseUint(ratingKey, 10, 32)
				if err == nil {
					var item models.MediaItem
					if err := s.db.Select("id, content_rating").First(&item, itemID).Error; err == nil {
						if RatingExceedsMax(item.ContentRating, maxRating) {
							c.JSON(http.StatusForbidden, gin.H{
								"error":         "Content restricted by parental controls",
								"contentRating": item.ContentRating,
								"maxRating":     maxRating,
								"pinRequired":   true,
							})
							c.Abort()
							return
						}
					}
				}
			}
		}

		c.Next()
	}
}
