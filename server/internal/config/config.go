package config

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"strconv"

	"gopkg.in/yaml.v3"
)

// generateMachineID creates a random unique identifier for this server instance
func generateMachineID() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// Config holds all application configuration
type Config struct {
	Server    ServerConfig    `yaml:"server"`
	Database  DatabaseConfig  `yaml:"database"`
	Auth      AuthConfig      `yaml:"auth"`
	Library   LibraryConfig   `yaml:"library"`
	LiveTV    LiveTVConfig    `yaml:"livetv"`
	DVR       DVRConfig       `yaml:"dvr"`
	VOD       VODConfig       `yaml:"vod"`
	Transcode TranscodeConfig `yaml:"transcode"`
	Logging   LoggingConfig   `yaml:"logging"`
}

// LoggingConfig holds logging settings
type LoggingConfig struct {
	Level         string `yaml:"level"`           // debug, info, warn, error
	JSON          bool   `yaml:"json"`            // output as JSON instead of text
	File          string `yaml:"file"`            // log file path (empty = stdout only)
	MaxSizeMB     int    `yaml:"max_size_mb"`     // max size per log file in MB
	MaxBackups    int    `yaml:"max_backups"`     // number of old log files to keep
	MaxAgeDays    int    `yaml:"max_age_days"`    // max age of log files in days
}

// ServerConfig holds HTTP server settings
type ServerConfig struct {
	Host             string `yaml:"host"`
	Port             int    `yaml:"port"`
	Name             string `yaml:"name"`               // Friendly server name
	MachineID        string `yaml:"machine_id"`         // Unique server identifier
	DiscoveryEnabled bool   `yaml:"discovery_enabled"`  // Enable UDP discovery
}

// DatabaseConfig holds database connection settings
type DatabaseConfig struct {
	Driver string `yaml:"driver"` // sqlite or postgres
	DSN    string `yaml:"dsn"`    // Data source name
}

// AuthConfig holds authentication settings
type AuthConfig struct {
	JWTSecret        string `yaml:"jwt_secret"`
	TokenExpiry      int    `yaml:"token_expiry"` // hours
	AllowSignup      bool   `yaml:"allow_signup"`
	AllowLocalAccess bool   `yaml:"allow_local_access"` // Allow access from localhost without auth
}

// LibraryConfig holds media library settings
type LibraryConfig struct {
	ScanInterval int      `yaml:"scan_interval"` // minutes
	MetadataLang string   `yaml:"metadata_lang"`
	TMDBApiKey   string   `yaml:"tmdb_api_key"`
	TVDBApiKey   string   `yaml:"tvdb_api_key"`
}

// LiveTVConfig holds IPTV/Live TV settings
type LiveTVConfig struct {
	Enabled     bool   `yaml:"enabled"`
	EPGInterval int    `yaml:"epg_interval"` // hours between EPG refreshes
}

// DVRConfig holds DVR recording settings
type DVRConfig struct {
	Enabled          bool    `yaml:"enabled"`
	RecordingDir     string  `yaml:"recording_dir"`
	PrePadding       int     `yaml:"pre_padding"`        // minutes before show
	PostPadding      int     `yaml:"post_padding"`       // minutes after show
	CommercialDetect bool    `yaml:"commercial_detect"`  // enable Comskip commercial detection
	ComskipPath      string  `yaml:"comskip_path"`       // path to comskip binary
	ComskipINIPath   string  `yaml:"comskip_ini_path"`   // path to comskip INI config
	DiskQuotaGB      float64 `yaml:"disk_quota_gb"`      // 0 = unlimited
	LowSpaceGB       float64 `yaml:"low_space_gb"`       // threshold for low space warning (default 5GB)
	DefaultQuality   string  `yaml:"default_quality"`    // original, high, medium, low
	HWAccel          string  `yaml:"hw_accel"`           // vaapi, nvenc, qsv, or empty
	DetectionWorkers int     `yaml:"detection_workers"`  // parallel commercial detection jobs (1-8, default 2)
	GenerateThumbs   bool    `yaml:"generate_thumbnails"` // generate thumbnails at chapter points during detection
	ShareEdits       bool    `yaml:"share_edits"`        // share commercial detection results with community
}

// VODConfig holds VOD (Video On Demand) download settings
type VODConfig struct {
	Enabled bool   `yaml:"enabled"`
	APIURL  string `yaml:"api_url"` // External VOD API URL (e.g., http://192.168.1.82:7070)
}

// TranscodeConfig holds transcoding settings
type TranscodeConfig struct {
	Enabled           bool   `yaml:"enabled"`
	FFmpegPath        string `yaml:"ffmpeg_path"`
	HardwareAccel     string `yaml:"hardware_accel"` // none, nvenc, qsv, vaapi, videotoolbox
	TempDir           string `yaml:"temp_dir"`
	MaxSessions       int    `yaml:"max_sessions"`
}

// DefaultConfig returns configuration with sensible defaults
func DefaultConfig() *Config {
	homeDir, _ := os.UserHomeDir()
	dataDir := filepath.Join(homeDir, ".openflix")

	return &Config{
		Server: ServerConfig{
			Host:             "0.0.0.0",
			Port:             32400,
			Name:             "OpenFlix Server",
			MachineID:        generateMachineID(),
			DiscoveryEnabled: true,
		},
		Database: DatabaseConfig{
			Driver: "sqlite",
			DSN:    filepath.Join(dataDir, "openflix.db"),
		},
		Auth: AuthConfig{
			JWTSecret:        "change-me-in-production",
			TokenExpiry:      24 * 30, // 30 days
			AllowSignup:      true,
			AllowLocalAccess: true, // Allow local network access without login
		},
		Library: LibraryConfig{
			ScanInterval: 60,
			MetadataLang: "en",
		},
		LiveTV: LiveTVConfig{
			Enabled:     true,
			EPGInterval: 4, // Refresh every 4 hours (Gracenote provides 6 hours of data)
		},
		DVR: DVRConfig{
			Enabled:          true,
			RecordingDir:     filepath.Join(dataDir, "recordings"),
			PrePadding:       2,
			PostPadding:      5,
			CommercialDetect: true,  // enabled by default, but only runs if comskip is found
			ComskipPath:      "",    // auto-detect
			ComskipINIPath:   "",    // use defaults
			DetectionWorkers: 2,     // 2 parallel detection jobs by default
			GenerateThumbs:   false, // thumbnail generation off by default
			ShareEdits:       false, // community sharing off by default
		},
		VOD: VODConfig{
			Enabled: true,
			APIURL:  "", // Must be configured in settings
		},
		Transcode: TranscodeConfig{
			Enabled:       true,
			FFmpegPath:    "ffmpeg",
			HardwareAccel: "auto",
			TempDir:       filepath.Join(dataDir, "transcode"),
			MaxSessions:   3,
		},
		Logging: LoggingConfig{
			Level:      "debug",
			JSON:       false,
			File:       filepath.Join(dataDir, "logs", "openflix.log"),
			MaxSizeMB:  50,
			MaxBackups: 3,
			MaxAgeDays: 7,
		},
	}
}

// Load loads configuration from file and environment
func Load() (*Config, error) {
	cfg := DefaultConfig()

	// Try to load from config file
	configPaths := []string{
		"config.yaml",
		"/etc/openflix/config.yaml",
		filepath.Join(os.Getenv("HOME"), ".openflix", "config.yaml"),
	}

	for _, path := range configPaths {
		if data, err := os.ReadFile(path); err == nil {
			if err := yaml.Unmarshal(data, cfg); err != nil {
				return nil, fmt.Errorf("failed to parse config file %s: %w", path, err)
			}
			break
		}
	}

	// Override with environment variables
	loadEnvOverrides(cfg)

	// Ensure data directories exist
	if err := ensureDirectories(cfg); err != nil {
		return nil, err
	}

	return cfg, nil
}

// loadEnvOverrides overrides config values from environment variables
func loadEnvOverrides(cfg *Config) {
	if host := os.Getenv("OPENFLIX_HOST"); host != "" {
		cfg.Server.Host = host
	}
	if port := os.Getenv("OPENFLIX_PORT"); port != "" {
		if p, err := strconv.Atoi(port); err == nil {
			cfg.Server.Port = p
		}
	}
	if driver := os.Getenv("OPENFLIX_DB_DRIVER"); driver != "" {
		cfg.Database.Driver = driver
	}
	if dsn := os.Getenv("OPENFLIX_DB_DSN"); dsn != "" {
		cfg.Database.DSN = dsn
	}
	if secret := os.Getenv("OPENFLIX_JWT_SECRET"); secret != "" {
		cfg.Auth.JWTSecret = secret
	}
	if tmdb := os.Getenv("OPENFLIX_TMDB_API_KEY"); tmdb != "" {
		cfg.Library.TMDBApiKey = tmdb
	}
	if tvdb := os.Getenv("OPENFLIX_TVDB_API_KEY"); tvdb != "" {
		cfg.Library.TVDBApiKey = tvdb
	}
	if ffmpeg := os.Getenv("OPENFLIX_FFMPEG_PATH"); ffmpeg != "" {
		cfg.Transcode.FFmpegPath = ffmpeg
	}
	if hwaccel := os.Getenv("OPENFLIX_HARDWARE_ACCEL"); hwaccel != "" {
		cfg.Transcode.HardwareAccel = hwaccel
	}
	if logLevel := os.Getenv("OPENFLIX_LOG_LEVEL"); logLevel != "" {
		cfg.Logging.Level = logLevel
	}
	if logJSON := os.Getenv("OPENFLIX_LOG_JSON"); logJSON == "true" || logJSON == "1" {
		cfg.Logging.JSON = true
	}
	// Transcode settings
	if transcodeDir := os.Getenv("OPENFLIX_TRANSCODE_DIR"); transcodeDir != "" {
		cfg.Transcode.TempDir = transcodeDir
	}
	if maxSessions := os.Getenv("OPENFLIX_MAX_TRANSCODE_SESSIONS"); maxSessions != "" {
		if s, err := strconv.Atoi(maxSessions); err == nil {
			cfg.Transcode.MaxSessions = s
		}
	}
	// DVR settings
	if recordingDir := os.Getenv("OPENFLIX_RECORDING_DIR"); recordingDir != "" {
		cfg.DVR.RecordingDir = recordingDir
	}
	if comskipPath := os.Getenv("OPENFLIX_COMSKIP_PATH"); comskipPath != "" {
		cfg.DVR.ComskipPath = comskipPath
	}
	if comskipINI := os.Getenv("OPENFLIX_COMSKIP_INI"); comskipINI != "" {
		cfg.DVR.ComskipINIPath = comskipINI
	}
	// VOD settings
	if vodAPIURL := os.Getenv("OPENFLIX_VOD_API_URL"); vodAPIURL != "" {
		cfg.VOD.APIURL = vodAPIURL
	}
}

// GetDataDir returns the main data directory
func (cfg *Config) GetDataDir() string {
	return filepath.Dir(cfg.Database.DSN)
}

// ensureDirectories creates necessary directories
func ensureDirectories(cfg *Config) error {
	dirs := []string{
		filepath.Dir(cfg.Database.DSN),
		cfg.DVR.RecordingDir,
		cfg.Transcode.TempDir,
	}

	for _, dir := range dirs {
		if dir != "" {
			if err := os.MkdirAll(dir, 0755); err != nil {
				return fmt.Errorf("failed to create directory %s: %w", dir, err)
			}
		}
	}

	return nil
}
