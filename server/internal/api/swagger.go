package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// registerSwaggerRoutes registers the OpenAPI spec and Swagger UI endpoints.
// These are public (no auth required).
func (s *Server) registerSwaggerRoutes(r *gin.Engine) {
	r.GET("/api/docs/openapi.json", s.serveOpenAPISpec)
	r.GET("/api/docs", s.serveSwaggerUI)
}

// serveOpenAPISpec returns the OpenAPI 3.0 JSON specification.
func (s *Server) serveOpenAPISpec(c *gin.Context) {
	c.Data(http.StatusOK, "application/json", []byte(openAPISpec))
}

// serveSwaggerUI serves a minimal HTML page that loads Swagger UI from CDN.
func (s *Server) serveSwaggerUI(c *gin.Context) {
	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(swaggerUIHTML))
}

const swaggerUIHTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>OpenFlix API Documentation</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
  <style>html{box-sizing:border-box;overflow-y:scroll}*,*:before,*:after{box-sizing:inherit}body{margin:0;background:#fafafa}</style>
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: '/api/docs/openapi.json',
      dom_id: '#swagger-ui',
      deepLinking: true,
      presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
      layout: "BaseLayout"
    });
  </script>
</body>
</html>`
