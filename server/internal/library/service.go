package library

import (
	"errors"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

var (
	ErrLibraryNotFound = errors.New("library not found")
	ErrPathNotFound    = errors.New("path not found")
	ErrInvalidPath     = errors.New("invalid path")
	ErrPathExists      = errors.New("path already exists in library")
)

// Service handles library operations
type Service struct {
	db      *gorm.DB
	dataDir string
}

// NewService creates a new library service
func NewService(db *gorm.DB, dataDir string) *Service {
	return &Service{
		db:      db,
		dataDir: dataDir,
	}
}

// CreateLibraryInput contains library creation data
type CreateLibraryInput struct {
	Title    string   `json:"title" binding:"required"`
	Type     string   `json:"type" binding:"required"` // movie, show, music, photo
	Language string   `json:"language,omitempty"`
	Paths    []string `json:"paths,omitempty"`
}

// UpdateLibraryInput contains library update data
type UpdateLibraryInput struct {
	Title    string `json:"title,omitempty"`
	Language string `json:"language,omitempty"`
	Hidden   *bool  `json:"hidden,omitempty"`
}

// CreateLibrary creates a new library
func (s *Service) CreateLibrary(input CreateLibraryInput) (*models.Library, error) {
	// Validate library type
	validTypes := map[string]bool{"movie": true, "show": true, "music": true, "photo": true}
	if !validTypes[input.Type] {
		return nil, errors.New("invalid library type")
	}

	// Set default language
	if input.Language == "" {
		input.Language = "en"
	}

	// Determine agent and scanner based on type
	agent := "tv.openflix.agents." + input.Type
	scanner := "OpenFlix " + strings.Title(input.Type)

	library := models.Library{
		UUID:     uuid.New().String(),
		Title:    input.Title,
		Type:     input.Type,
		Agent:    agent,
		Scanner:  scanner,
		Language: input.Language,
	}

	if err := s.db.Create(&library).Error; err != nil {
		return nil, err
	}

	// Add paths if provided
	for _, path := range input.Paths {
		if err := s.AddPath(library.ID, path); err != nil {
			// Log error but continue
			continue
		}
	}

	// Reload with paths
	s.db.Preload("Paths").First(&library, library.ID)

	return &library, nil
}

// GetLibrary retrieves a library by ID
func (s *Service) GetLibrary(id uint) (*models.Library, error) {
	var library models.Library
	if err := s.db.Preload("Paths").First(&library, id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrLibraryNotFound
		}
		return nil, err
	}
	return &library, nil
}

// GetAllLibraries retrieves all libraries
func (s *Service) GetAllLibraries() ([]models.Library, error) {
	var libraries []models.Library
	if err := s.db.Preload("Paths").Find(&libraries).Error; err != nil {
		return nil, err
	}
	return libraries, nil
}

// UpdateLibrary updates a library
func (s *Service) UpdateLibrary(id uint, input UpdateLibraryInput) (*models.Library, error) {
	library, err := s.GetLibrary(id)
	if err != nil {
		return nil, err
	}

	updates := make(map[string]interface{})
	if input.Title != "" {
		updates["title"] = input.Title
	}
	if input.Language != "" {
		updates["language"] = input.Language
	}
	if input.Hidden != nil {
		updates["hidden"] = *input.Hidden
	}

	if len(updates) > 0 {
		if err := s.db.Model(library).Updates(updates).Error; err != nil {
			return nil, err
		}
	}

	return library, nil
}

// DeleteLibrary deletes a library and all its content
func (s *Service) DeleteLibrary(id uint) error {
	library, err := s.GetLibrary(id)
	if err != nil {
		return err
	}

	// Delete all media items in this library
	s.db.Where("library_id = ?", id).Delete(&models.MediaItem{})

	// Delete library paths
	s.db.Where("library_id = ?", id).Delete(&models.LibraryPath{})

	// Delete the library
	return s.db.Delete(library).Error
}

// AddPath adds a path to a library
func (s *Service) AddPath(libraryID uint, path string) error {
	// Verify library exists
	if _, err := s.GetLibrary(libraryID); err != nil {
		return err
	}

	// Clean and validate path
	path = filepath.Clean(path)
	if !filepath.IsAbs(path) {
		return ErrInvalidPath
	}

	// Check if path exists on filesystem
	info, err := os.Stat(path)
	if err != nil {
		return ErrInvalidPath
	}
	if !info.IsDir() {
		return ErrInvalidPath
	}

	// Check if path already exists in this library
	var existing models.LibraryPath
	if err := s.db.Where("library_id = ? AND path = ?", libraryID, path).First(&existing).Error; err == nil {
		return ErrPathExists
	}

	libraryPath := models.LibraryPath{
		LibraryID: libraryID,
		Path:      path,
	}

	return s.db.Create(&libraryPath).Error
}

// RemovePath removes a path from a library
func (s *Service) RemovePath(libraryID uint, pathID uint) error {
	result := s.db.Where("id = ? AND library_id = ?", pathID, libraryID).Delete(&models.LibraryPath{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return ErrPathNotFound
	}
	return nil
}

// GetLibraryPaths retrieves all paths for a library
func (s *Service) GetLibraryPaths(libraryID uint) ([]models.LibraryPath, error) {
	var paths []models.LibraryPath
	if err := s.db.Where("library_id = ?", libraryID).Find(&paths).Error; err != nil {
		return nil, err
	}
	return paths, nil
}

// GetMediaItemCount returns the number of media items in a library
func (s *Service) GetMediaItemCount(libraryID uint) int64 {
	var count int64
	s.db.Model(&models.MediaItem{}).Where("library_id = ?", libraryID).Count(&count)
	return count
}
