package library

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestScanLibraryDoesNotPurgeMissingRootOnFirstMiss(t *testing.T) {
	db := newScannerTestDB(t)
	root := filepath.Join(t.TempDir(), "missing-root")

	libraryPath := seedLibraryWithFile(t, db, root, filepath.Join(root, "Movie.mkv"))
	if err := os.RemoveAll(root); err != nil {
		t.Fatalf("remove root: %v", err)
	}

	scanner := NewScanner(db)
	library := &models.Library{ID: libraryPath.LibraryID}
	if _, err := scanner.ScanLibrary(library); err != nil {
		t.Fatalf("scan library: %v", err)
	}

	assertMediaFileCount(t, db, 1)

	var refreshed models.LibraryPath
	if err := db.First(&refreshed, libraryPath.ID).Error; err != nil {
		t.Fatalf("reload library path: %v", err)
	}
	if refreshed.Healthy {
		t.Fatalf("expected path to be unhealthy after missing scan")
	}
	if refreshed.ConsecutiveMissingScans != 1 {
		t.Fatalf("expected missing scan count 1, got %d", refreshed.ConsecutiveMissingScans)
	}
}

func TestScanLibraryPurgesMissingRootAfterThreshold(t *testing.T) {
	db := newScannerTestDB(t)
	root := filepath.Join(t.TempDir(), "missing-root")

	libraryPath := seedLibraryWithFile(t, db, root, filepath.Join(root, "Movie.mkv"))
	if err := os.RemoveAll(root); err != nil {
		t.Fatalf("remove root: %v", err)
	}

	scanner := NewScanner(db)
	library := &models.Library{ID: libraryPath.LibraryID}
	for i := 0; i < missingLibraryPathThreshold; i++ {
		if _, err := scanner.ScanLibrary(library); err != nil {
			t.Fatalf("scan library attempt %d: %v", i+1, err)
		}
	}

	assertMediaFileCount(t, db, 0)
}

func TestScanLibraryPurgesFilesWhenPathRemovedFromConfig(t *testing.T) {
	db := newScannerTestDB(t)
	root := t.TempDir()
	libraryPath := seedLibraryWithFile(t, db, root, filepath.Join(root, "Movie.mkv"))

	if err := db.Delete(&models.LibraryPath{}, libraryPath.ID).Error; err != nil {
		t.Fatalf("delete library path: %v", err)
	}

	scanner := NewScanner(db)
	library := &models.Library{ID: libraryPath.LibraryID}
	if _, err := scanner.ScanLibrary(library); err != nil {
		t.Fatalf("scan library: %v", err)
	}

	assertMediaFileCount(t, db, 0)
}

func newScannerTestDB(t *testing.T) *gorm.DB {
	t.Helper()

	dsn := filepath.Join(t.TempDir(), fmt.Sprintf("%s.db", uuid.NewString()))
	db, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{})
	if err != nil {
		t.Fatalf("open db: %v", err)
	}

	if err := db.AutoMigrate(
		&models.Library{},
		&models.LibraryPath{},
		&models.MediaItem{},
		&models.MediaFile{},
		&models.MediaStream{},
	); err != nil {
		t.Fatalf("migrate db: %v", err)
	}

	return db
}

func seedLibraryWithFile(t *testing.T, db *gorm.DB, root string, filePath string) models.LibraryPath {
	t.Helper()

	if err := os.MkdirAll(root, 0755); err != nil {
		t.Fatalf("mkdir root: %v", err)
	}

	library := models.Library{
		UUID:  uuid.NewString(),
		Title: "Movies",
		Type:  "movie",
	}
	if err := db.Create(&library).Error; err != nil {
		t.Fatalf("create library: %v", err)
	}

	libraryPath := models.LibraryPath{
		LibraryID: library.ID,
		Path:      root,
		Healthy:   true,
	}
	if err := db.Create(&libraryPath).Error; err != nil {
		t.Fatalf("create library path: %v", err)
	}

	item := models.MediaItem{
		UUID:      uuid.NewString(),
		LibraryID: library.ID,
		Type:      "movie",
		Title:     "Movie",
	}
	if err := db.Create(&item).Error; err != nil {
		t.Fatalf("create media item: %v", err)
	}

	file := models.MediaFile{
		MediaItemID: item.ID,
		FilePath:    filePath,
		FileSize:    123,
	}
	if err := db.Create(&file).Error; err != nil {
		t.Fatalf("create media file: %v", err)
	}

	return libraryPath
}

func assertMediaFileCount(t *testing.T, db *gorm.DB, expected int64) {
	t.Helper()

	var count int64
	if err := db.Model(&models.MediaFile{}).Count(&count).Error; err != nil {
		t.Fatalf("count media files: %v", err)
	}
	if count != expected {
		t.Fatalf("expected %d media files, got %d", expected, count)
	}
}
