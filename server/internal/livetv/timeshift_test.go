package livetv

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestGetProgramTimeShiftURLUsesBufferOffset(t *testing.T) {
	db := newLiveTVTestDB(t)
	bufferStart := time.Date(2026, 3, 9, 9, 0, 0, 0, time.UTC)

	tsb := NewTimeShiftBuffer(db, TimeShiftConfig{
		BufferDir:     t.TempDir(),
		SegmentLength: 6,
	})
	t.Cleanup(tsb.Stop)

	tsb.activeBuffers[42] = &ChannelBuffer{
		ChannelID: 42,
		StartTime: bufferStart,
		BufferDir: t.TempDir(),
	}

	got, err := tsb.GetProgramTimeShiftURL(42, bufferStart.Add(2*time.Minute))
	if err != nil {
		t.Fatalf("GetProgramTimeShiftURL returned error: %v", err)
	}

	want := "/livetv/timeshift/42/stream.m3u8?start=20"
	if got != want {
		t.Fatalf("unexpected timeshift url: got %q want %q", got, want)
	}
}

func TestGetProgramTimeShiftURLClipsToBufferStart(t *testing.T) {
	db := newLiveTVTestDB(t)
	bufferStart := time.Date(2026, 3, 9, 9, 0, 0, 0, time.UTC)

	tsb := NewTimeShiftBuffer(db, TimeShiftConfig{
		BufferDir:     t.TempDir(),
		SegmentLength: 6,
	})
	t.Cleanup(tsb.Stop)

	tsb.activeBuffers[7] = &ChannelBuffer{
		ChannelID: 7,
		StartTime: bufferStart,
		BufferDir: t.TempDir(),
	}

	got, err := tsb.GetProgramTimeShiftURL(7, bufferStart.Add(-5*time.Minute))
	if err != nil {
		t.Fatalf("GetProgramTimeShiftURL returned error: %v", err)
	}

	want := "/livetv/timeshift/7/stream.m3u8?start=0"
	if got != want {
		t.Fatalf("unexpected clipped timeshift url: got %q want %q", got, want)
	}
}

func TestGetProgramTimeShiftURLUsesRetainedBufferStart(t *testing.T) {
	db := newLiveTVTestDB(t)
	bufferStart := time.Date(2026, 3, 9, 9, 0, 0, 0, time.UTC)
	bufferDir := t.TempDir()

	for _, idx := range []int{100, 101, 102} {
		path := filepath.Join(bufferDir, fmt.Sprintf("segment_%05d.ts", idx))
		if err := os.WriteFile(path, []byte("ts"), 0644); err != nil {
			t.Fatalf("write segment %d: %v", idx, err)
		}
	}

	tsb := NewTimeShiftBuffer(db, TimeShiftConfig{
		BufferDir:     t.TempDir(),
		SegmentLength: 6,
	})
	t.Cleanup(tsb.Stop)

	tsb.activeBuffers[9] = &ChannelBuffer{
		ChannelID: 9,
		StartTime: bufferStart,
		BufferDir: bufferDir,
	}

	got, err := tsb.GetProgramTimeShiftURL(9, bufferStart.Add(11*time.Minute))
	if err != nil {
		t.Fatalf("GetProgramTimeShiftURL returned error: %v", err)
	}

	want := "/livetv/timeshift/9/stream.m3u8?start=110"
	if got != want {
		t.Fatalf("unexpected retained-buffer url: got %q want %q", got, want)
	}
}

func TestGenerateTimeshiftPlaylistUsesAbsoluteSegmentIndicesAndToken(t *testing.T) {
	db := newLiveTVTestDB(t)
	bufferDir := t.TempDir()

	for _, idx := range []int{100, 101, 102} {
		path := filepath.Join(bufferDir, fmt.Sprintf("segment_%05d.ts", idx))
		if err := os.WriteFile(path, []byte("ts"), 0644); err != nil {
			t.Fatalf("write segment %d: %v", idx, err)
		}
	}

	tsb := NewTimeShiftBuffer(db, TimeShiftConfig{
		BufferDir:     t.TempDir(),
		SegmentLength: 6,
	})
	t.Cleanup(tsb.Stop)

	tsb.activeBuffers[5] = &ChannelBuffer{
		ChannelID: 5,
		StartTime: time.Now(),
		BufferDir: bufferDir,
	}

	got, err := tsb.GenerateTimeshiftPlaylist(5, 101, "test-token")
	if err != nil {
		t.Fatalf("GenerateTimeshiftPlaylist returned error: %v", err)
	}

	if !strings.Contains(got, "#EXT-X-MEDIA-SEQUENCE:101") {
		t.Fatalf("expected playlist to start at absolute segment 101, got %q", got)
	}
	if strings.Contains(got, "segment_00100.ts") {
		t.Fatalf("playlist should not include pruned segment 100 when start is 101: %q", got)
	}
	if !strings.Contains(got, "segment_00101.ts?X-Plex-Token=test-token") {
		t.Fatalf("playlist missing tokenized segment URL: %q", got)
	}
}

func TestArchiveGetSegmentPathRejectsTraversal(t *testing.T) {
	db := newLiveTVTestDB(t)
	archiveDir := filepath.Join(t.TempDir(), "archive")
	secretDir := filepath.Dir(archiveDir)

	am := NewArchiveManager(db, ArchiveConfig{
		ArchiveDir: archiveDir,
	})

	program := models.ArchiveProgram{
		ChannelID:  1,
		Title:      "Program",
		StartTime:  time.Now().Add(-time.Hour),
		EndTime:    time.Now(),
		Status:     "available",
		ArchiveDir: archiveDir,
		ExpiresAt:  time.Now().Add(time.Hour),
	}
	if err := db.Create(&program).Error; err != nil {
		t.Fatalf("create archive program: %v", err)
	}

	secretPath := filepath.Join(secretDir, "secret.ts")
	if err := os.WriteFile(secretPath, []byte("secret"), 0644); err != nil {
		t.Fatalf("write secret file: %v", err)
	}

	_, err := am.GetSegmentPath(program.ID, "../secret.ts")
	if err == nil || !strings.Contains(err.Error(), "invalid segment name") {
		t.Fatalf("expected invalid segment name error, got %v", err)
	}
}

func newLiveTVTestDB(t *testing.T) *gorm.DB {
	t.Helper()

	dsn := filepath.Join(t.TempDir(), fmt.Sprintf("%d.db", time.Now().UnixNano()))
	db, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{})
	if err != nil {
		t.Fatalf("open db: %v", err)
	}

	if err := db.AutoMigrate(&models.Program{}, &models.ArchiveProgram{}); err != nil {
		t.Fatalf("migrate db: %v", err)
	}

	return db
}
