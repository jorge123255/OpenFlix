package main

import (
	"log"
	"os"

	"github.com/openflix/openflix-server/internal/api"
	"github.com/openflix/openflix-server/internal/config"
	"github.com/openflix/openflix-server/internal/db"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize database
	database, err := db.Initialize(cfg.Database)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	// Run migrations
	if err := db.Migrate(database); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Create and start API server
	server := api.NewServer(cfg, database)

	log.Printf("OpenFlix Server starting on %s:%d", cfg.Server.Host, cfg.Server.Port)
	if err := server.Run(); err != nil {
		log.Fatalf("Server failed: %v", err)
		os.Exit(1)
	}
}
