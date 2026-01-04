package main

import (
	"os"

	"github.com/openflix/openflix-server/internal/api"
	"github.com/openflix/openflix-server/internal/config"
	"github.com/openflix/openflix-server/internal/db"
	"github.com/openflix/openflix-server/internal/discovery"
	"github.com/openflix/openflix-server/internal/logger"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		logger.Log.Fatalf("Failed to load configuration: %v", err)
	}

	// Configure logging based on config
	if err := logger.Configure(logger.LogConfig{
		Level:      cfg.Logging.Level,
		JSON:       cfg.Logging.JSON,
		File:       cfg.Logging.File,
		MaxSizeMB:  cfg.Logging.MaxSizeMB,
		MaxBackups: cfg.Logging.MaxBackups,
		MaxAgeDays: cfg.Logging.MaxAgeDays,
	}); err != nil {
		logger.Log.Warnf("Failed to configure log file: %v", err)
	}

	// Initialize database
	database, err := db.Initialize(cfg.Database)
	if err != nil {
		logger.Log.Fatalf("Failed to initialize database: %v", err)
	}

	// Run migrations
	if err := db.Migrate(database); err != nil {
		logger.Log.Fatalf("Failed to run migrations: %v", err)
	}

	// Start discovery service for auto-discovery on local network
	if cfg.Server.DiscoveryEnabled {
		discoveryService := discovery.NewDiscoveryService(
			cfg.Server.Name,
			"1.0.0",
			cfg.Server.MachineID,
			cfg.Server.Host,
			cfg.Server.Port,
		)
		if err := discoveryService.Start(); err != nil {
			logger.Log.Warnf("Failed to start discovery service: %v", err)
		} else {
			defer discoveryService.Stop()
		}
	}

	// Create and start API server
	server := api.NewServer(cfg, database)

	logger.Log.WithFields(map[string]interface{}{
		"host":      cfg.Server.Host,
		"port":      cfg.Server.Port,
		"name":      cfg.Server.Name,
		"machineId": cfg.Server.MachineID[:8] + "...",
		"discovery": cfg.Server.DiscoveryEnabled,
	}).Info("OpenFlix Server starting")

	if err := server.Run(); err != nil {
		logger.Log.Fatalf("Server failed: %v", err)
		os.Exit(1)
	}
}
