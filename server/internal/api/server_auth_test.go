package api

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/auth"
	"github.com/openflix/openflix-server/internal/config"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestAuthRequiredLocalAccessUsesRealUser(t *testing.T) {
	gin.SetMode(gin.TestMode)

	db, err := gorm.Open(sqlite.Open(fmt.Sprintf("file:%s?mode=memory&cache=shared", t.Name())), &gorm.Config{})
	if err != nil {
		t.Fatalf("open db: %v", err)
	}
	if err := db.AutoMigrate(&models.User{}, &models.UserProfile{}); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	user := models.User{
		UUID:        "user-1",
		Username:    "owner",
		DisplayName: "Owner",
		IsAdmin:     true,
	}
	if err := db.Create(&user).Error; err != nil {
		t.Fatalf("create user: %v", err)
	}
	profile := models.UserProfile{
		UserID: user.ID,
		UUID:   "profile-1",
		Name:   "Main",
	}
	if err := db.Create(&profile).Error; err != nil {
		t.Fatalf("create profile: %v", err)
	}

	s := &Server{
		config: &config.Config{
			Auth: config.AuthConfig{AllowLocalAccess: true},
		},
		db: db,
	}

	router := gin.New()
	router.GET("/me", s.authRequired(), func(c *gin.Context) {
		if got := c.GetUint("userID"); got != user.ID {
			t.Fatalf("userID = %d, want %d", got, user.ID)
		}
		// Local access grants admin if the real user is admin
		if !c.GetBool("isAdmin") {
			t.Fatal("local admin user should have isAdmin=true")
		}
		if !c.GetBool("isLocalAccess") {
			t.Fatal("isLocalAccess not set")
		}
		claimsRaw, exists := c.Get("claims")
		if !exists {
			t.Fatal("claims missing")
		}
		claims := claimsRaw.(*auth.Claims)
		if claims.ProfileID != profile.ID {
			t.Fatalf("profileID = %d, want %d", claims.ProfileID, profile.ID)
		}
		c.Status(http.StatusNoContent)
	})

	req := httptest.NewRequest(http.MethodGet, "/me", nil)
	req.RemoteAddr = "192.168.1.50:12345"
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusNoContent)
	}
}

func TestAdminRequiredAllowsLocalAdminUser(t *testing.T) {
	gin.SetMode(gin.TestMode)

	db, err := gorm.Open(sqlite.Open(fmt.Sprintf("file:%s?mode=memory&cache=shared", t.Name())), &gorm.Config{})
	if err != nil {
		t.Fatalf("open db: %v", err)
	}
	if err := db.AutoMigrate(&models.User{}, &models.UserProfile{}); err != nil {
		t.Fatalf("migrate: %v", err)
	}
	user := models.User{UUID: "user-1", Username: "owner", IsAdmin: true}
	if err := db.Create(&user).Error; err != nil {
		t.Fatalf("create user: %v", err)
	}

	s := &Server{
		config: &config.Config{
			Auth: config.AuthConfig{AllowLocalAccess: true},
		},
		db: db,
	}

	router := gin.New()
	router.GET("/admin", s.authRequired(), s.adminRequired(), func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	req := httptest.NewRequest(http.MethodGet, "/admin", nil)
	req.RemoteAddr = "192.168.1.50:12345"
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	// Local admin user should be allowed through admin routes
	if rec.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusNoContent)
	}
}
