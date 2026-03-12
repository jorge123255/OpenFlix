package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestPersistJWTSecretReplacesPlaceholderAndPersists(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)

	cfg := DefaultConfig()
	cfg.Auth.JWTSecret = defaultJWTSecret

	persistJWTSecret(cfg)

	if cfg.Auth.JWTSecret == "" || cfg.Auth.JWTSecret == defaultJWTSecret {
		t.Fatalf("jwt secret was not replaced: %q", cfg.Auth.JWTSecret)
	}

	secretPath := filepath.Join(home, ".openflix", "jwt-secret")
	data, err := os.ReadFile(secretPath)
	if err != nil {
		t.Fatalf("read persisted secret: %v", err)
	}
	if string(data) != cfg.Auth.JWTSecret {
		t.Fatalf("persisted secret mismatch: got %q want %q", string(data), cfg.Auth.JWTSecret)
	}

	cfg2 := DefaultConfig()
	cfg2.Auth.JWTSecret = defaultJWTSecret
	persistJWTSecret(cfg2)

	if cfg2.Auth.JWTSecret != cfg.Auth.JWTSecret {
		t.Fatalf("persisted secret not reused: got %q want %q", cfg2.Auth.JWTSecret, cfg.Auth.JWTSecret)
	}
}
