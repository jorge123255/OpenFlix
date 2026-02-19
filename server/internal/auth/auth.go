package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserExists         = errors.New("user already exists")
	ErrUserNotFound       = errors.New("user not found")
	ErrInvalidToken       = errors.New("invalid token")
	ErrTokenExpired       = errors.New("token expired")
)

// Claims represents JWT claims
type Claims struct {
	UserID    uint   `json:"user_id"`
	UUID      string `json:"uuid"`
	Username  string `json:"username"`
	IsAdmin   bool   `json:"is_admin"`
	ProfileID uint   `json:"profile_id,omitempty"`
	jwt.RegisteredClaims
}

// Service handles authentication operations
type Service struct {
	db          *gorm.DB
	jwtSecret   []byte
	tokenExpiry time.Duration
}

// NewService creates a new auth service
func NewService(db *gorm.DB, jwtSecret string, tokenExpiryHours int) *Service {
	return &Service{
		db:          db,
		jwtSecret:   []byte(jwtSecret),
		tokenExpiry: time.Duration(tokenExpiryHours) * time.Hour,
	}
}

// RegisterInput contains registration data
type RegisterInput struct {
	Username    string `json:"username" binding:"required,min=3,max=50"`
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required,min=6"`
	DisplayName string `json:"displayName"`
}

// LoginInput contains login data
type LoginInput struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse contains auth response data
type AuthResponse struct {
	Token string       `json:"authToken"`
	User  UserResponse `json:"user"`
}

// UserResponse contains user data for responses
type UserResponse struct {
	ID          uint   `json:"id"`
	UUID        string `json:"uuid"`
	Username    string `json:"username"`
	Email       string `json:"email"`
	DisplayName string `json:"title"`
	Thumb       string `json:"thumb,omitempty"`
	IsAdmin     bool   `json:"admin"`
}

// Register creates a new user account
func (s *Service) Register(input RegisterInput) (*AuthResponse, error) {
	// Check if username exists
	var existingUser models.User
	if err := s.db.Where("username = ?", input.Username).First(&existingUser).Error; err == nil {
		return nil, ErrUserExists
	}

	// Check if email exists
	if err := s.db.Where("email = ?", input.Email).First(&existingUser).Error; err == nil {
		return nil, ErrUserExists
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	// Determine if this is the first user (make them admin)
	var userCount int64
	s.db.Model(&models.User{}).Count(&userCount)
	isFirstUser := userCount == 0

	displayName := input.DisplayName
	if displayName == "" {
		displayName = input.Username
	}

	// Create user
	user := models.User{
		UUID:         uuid.New().String(),
		Username:     input.Username,
		Email:        input.Email,
		PasswordHash: string(hashedPassword),
		DisplayName:  displayName,
		IsAdmin:      isFirstUser,
		HasPassword:  true,
	}

	if err := s.db.Create(&user).Error; err != nil {
		return nil, err
	}

	// Create default profile for user
	profile := models.UserProfile{
		UserID: user.ID,
		UUID:   uuid.New().String(),
		Name:   displayName,
	}
	s.db.Create(&profile)

	// Generate token
	token, err := s.generateToken(&user, 0)
	if err != nil {
		return nil, err
	}

	return &AuthResponse{
		Token: token,
		User:  s.userToResponse(&user),
	}, nil
}

// Login authenticates a user
func (s *Service) Login(input LoginInput) (*AuthResponse, error) {
	var user models.User

	// Find user by username or email
	if err := s.db.Where("username = ? OR email = ?", input.Username, input.Username).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrInvalidCredentials
		}
		return nil, err
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(input.Password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	// Generate token
	token, err := s.generateToken(&user, 0)
	if err != nil {
		return nil, err
	}

	return &AuthResponse{
		Token: token,
		User:  s.userToResponse(&user),
	}, nil
}

// ValidateToken validates a JWT token and returns the claims
func (s *Service) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return s.jwtSecret, nil
	})

	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrTokenExpired
		}
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	return claims, nil
}

// GetUserByID retrieves a user by ID
func (s *Service) GetUserByID(id uint) (*models.User, error) {
	var user models.User
	if err := s.db.First(&user, id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	return &user, nil
}

// GetUserByUUID retrieves a user by UUID
func (s *Service) GetUserByUUID(uuid string) (*models.User, error) {
	var user models.User
	if err := s.db.Where("uuid = ?", uuid).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	return &user, nil
}

// GetAllUsers retrieves all users (for home users endpoint)
func (s *Service) GetAllUsers() ([]models.User, error) {
	var users []models.User
	if err := s.db.Find(&users).Error; err != nil {
		return nil, err
	}
	return users, nil
}

// DeleteUser deletes a user and their profiles
func (s *Service) DeleteUser(userID uint) error {
	// Delete profiles first
	if err := s.db.Where("user_id = ?", userID).Delete(&models.UserProfile{}).Error; err != nil {
		return err
	}
	return s.db.Delete(&models.User{}, userID).Error
}

// GetUserProfiles retrieves all profiles for a user
func (s *Service) GetUserProfiles(userID uint) ([]models.UserProfile, error) {
	var profiles []models.UserProfile
	if err := s.db.Where("user_id = ?", userID).Find(&profiles).Error; err != nil {
		return nil, err
	}
	return profiles, nil
}

// GetProfile retrieves a single profile by ID
func (s *Service) GetProfile(profileID uint, userID uint) (*models.UserProfile, error) {
	var profile models.UserProfile
	if err := s.db.Where("id = ? AND user_id = ?", profileID, userID).First(&profile).Error; err != nil {
		return nil, ErrUserNotFound
	}
	return &profile, nil
}

// CreateProfileInput contains profile creation data
type CreateProfileInput struct {
	Name  string `json:"name" binding:"required,min=1,max=50"`
	Thumb string `json:"thumb,omitempty"`
	IsKid bool   `json:"isKid,omitempty"`
}

// CreateProfile creates a new user profile
func (s *Service) CreateProfile(userID uint, input CreateProfileInput) (*models.UserProfile, error) {
	profile := models.UserProfile{
		UserID: userID,
		UUID:   uuid.New().String(),
		Name:   input.Name,
		Thumb:  input.Thumb,
		IsKid:  input.IsKid,
	}

	if err := s.db.Create(&profile).Error; err != nil {
		return nil, err
	}

	return &profile, nil
}

// UpdateProfileInput contains profile update data
type UpdateProfileInput struct {
	Name  string `json:"name,omitempty"`
	Thumb string `json:"thumb,omitempty"`
	IsKid *bool  `json:"isKid,omitempty"`
}

// UpdateProfile updates a user profile
func (s *Service) UpdateProfile(profileID uint, userID uint, input UpdateProfileInput) (*models.UserProfile, error) {
	profile, err := s.GetProfile(profileID, userID)
	if err != nil {
		return nil, err
	}

	updates := make(map[string]interface{})
	if input.Name != "" {
		updates["name"] = input.Name
	}
	if input.Thumb != "" {
		updates["thumb"] = input.Thumb
	}
	if input.IsKid != nil {
		updates["is_kid"] = *input.IsKid
	}

	if len(updates) > 0 {
		if err := s.db.Model(profile).Updates(updates).Error; err != nil {
			return nil, err
		}
	}

	return profile, nil
}

// DeleteProfile deletes a user profile
func (s *Service) DeleteProfile(profileID uint, userID uint) error {
	result := s.db.Where("id = ? AND user_id = ?", profileID, userID).Delete(&models.UserProfile{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return ErrUserNotFound
	}
	return nil
}

// UpdateUserInput contains user update data
type UpdateUserInput struct {
	DisplayName string `json:"displayName,omitempty"`
	Email       string `json:"email,omitempty"`
	Thumb       string `json:"thumb,omitempty"`
}

// UpdateUser updates a user's profile information
func (s *Service) UpdateUser(userID uint, input UpdateUserInput) (*models.User, error) {
	user, err := s.GetUserByID(userID)
	if err != nil {
		return nil, err
	}

	updates := make(map[string]interface{})
	if input.DisplayName != "" {
		updates["display_name"] = input.DisplayName
	}
	if input.Email != "" {
		updates["email"] = input.Email
	}
	if input.Thumb != "" {
		updates["thumb"] = input.Thumb
	}

	if len(updates) > 0 {
		if err := s.db.Model(user).Updates(updates).Error; err != nil {
			return nil, err
		}
	}

	return user, nil
}

// SwitchProfile generates a new token for a different profile
func (s *Service) SwitchProfile(user *models.User, profileID uint) (string, error) {
	// Verify profile belongs to user
	var profile models.UserProfile
	if err := s.db.Where("id = ? AND user_id = ?", profileID, user.ID).First(&profile).Error; err != nil {
		return "", ErrUserNotFound
	}

	return s.generateToken(user, profileID)
}

// UpdatePassword updates a user's password
func (s *Service) UpdatePassword(userID uint, oldPassword, newPassword string) error {
	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		return ErrUserNotFound
	}

	// Verify old password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(oldPassword)); err != nil {
		return ErrInvalidCredentials
	}

	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	return s.db.Model(&user).Update("password_hash", string(hashedPassword)).Error
}

// generateToken creates a new JWT token
func (s *Service) generateToken(user *models.User, profileID uint) (string, error) {
	claims := &Claims{
		UserID:    user.ID,
		UUID:      user.UUID,
		Username:  user.Username,
		IsAdmin:   user.IsAdmin,
		ProfileID: profileID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.tokenExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "openflix",
			Subject:   user.UUID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

// userToResponse converts a user model to response
func (s *Service) userToResponse(user *models.User) UserResponse {
	return UserResponse{
		ID:          user.ID,
		UUID:        user.UUID,
		Username:    user.Username,
		Email:       user.Email,
		DisplayName: user.DisplayName,
		Thumb:       user.Thumb,
		IsAdmin:     user.IsAdmin,
	}
}

// ========== PIN-based Authentication (for Plex compatibility) ==========

// PINSession stores temporary PIN sessions
type PINSession struct {
	ID        int       `json:"id"`
	Code      string    `json:"code"`
	Token     string    `json:"authToken,omitempty"`
	ExpiresAt time.Time `json:"expiresAt"`
	Claimed   bool      `json:"claimed"`
}

var pinSessions = make(map[int]*PINSession)
var pinCounter = 0

// CreatePIN creates a new PIN for authentication
func (s *Service) CreatePIN() *PINSession {
	pinCounter++
	code := generatePINCode()

	session := &PINSession{
		ID:        pinCounter,
		Code:      code,
		ExpiresAt: time.Now().Add(5 * time.Minute),
		Claimed:   false,
	}

	pinSessions[pinCounter] = session
	return session
}

// GetPIN retrieves a PIN session
func (s *Service) GetPIN(id int) *PINSession {
	return pinSessions[id]
}

// ClaimPIN marks a PIN as claimed and assigns a token
func (s *Service) ClaimPIN(id int, token string) {
	if session, exists := pinSessions[id]; exists {
		session.Token = token
		session.Claimed = true
	}
}

// generatePINCode creates a random 8-character PIN
func generatePINCode() string {
	chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	code := make([]byte, 8)
	for i := range code {
		code[i] = chars[time.Now().UnixNano()%int64(len(chars))]
		time.Sleep(1 * time.Nanosecond)
	}
	return string(code)
}
