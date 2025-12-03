# Build stage
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=1 GOOS=linux go build -o openflix-server ./cmd/server

# Runtime stage
FROM alpine:latest

RUN apk add --no-cache \
    ffmpeg \
    ca-certificates \
    tzdata \
    sqlite

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/openflix-server .

# Create data directory
RUN mkdir -p /data

# Expose port
EXPOSE 32400

# Environment variables
ENV OPENFLIX_HOST=0.0.0.0
ENV OPENFLIX_PORT=32400
ENV OPENFLIX_DB_DRIVER=sqlite
ENV OPENFLIX_DB_DSN=/data/openflix.db

# Run the server
CMD ["./openflix-server"]
