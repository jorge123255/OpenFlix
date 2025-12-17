package api

import (
	"embed"
	"fmt"
	"io/fs"
	"mime"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
)

//go:embed all:web/dist
var webFS embed.FS

// setupWebUI configures the web admin UI routes
func (s *Server) setupWebUI(r *gin.Engine) {
	// Debug: list embedded files
	fs.WalkDir(webFS, ".", func(path string, d fs.DirEntry, err error) error {
		if err == nil {
			fmt.Printf("Embedded: %s\n", path)
		}
		return nil
	})

	// Get the web/dist subdirectory
	distFS, err := fs.Sub(webFS, "web/dist")
	if err != nil {
		fmt.Printf("Failed to get web/dist subdirectory: %v\n", err)
		return
	}

	fmt.Println("Web UI routes configured")

	// Helper to serve a file from the embedded FS
	serveFile := func(c *gin.Context, filePath string) {
		data, err := fs.ReadFile(distFS, filePath)
		if err != nil {
			c.String(404, "File not found: %s", filePath)
			return
		}
		contentType := mime.TypeByExtension(filepath.Ext(filePath))
		if contentType == "" {
			contentType = "application/octet-stream"
		}
		c.Data(200, contentType, data)
	}

	// Serve all /ui/* routes with a single handler
	r.GET("/ui/*path", func(c *gin.Context) {
		path := c.Param("path")

		// Handle assets directory
		if strings.HasPrefix(path, "/assets/") {
			serveFile(c, strings.TrimPrefix(path, "/"))
			return
		}

		// Handle other static files (like vite.svg)
		if strings.Contains(path, ".") {
			serveFile(c, strings.TrimPrefix(path, "/"))
			return
		}

		// Otherwise serve index.html for SPA routing
		serveFile(c, "index.html")
	})
}
