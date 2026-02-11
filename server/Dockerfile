# Web UI build stage
FROM node:20-slim AS web-builder

WORKDIR /app/web
COPY web/package*.json ./
RUN npm ci
COPY web/ ./
RUN npm run build

# Go build stage - use Debian for glibc compatibility with Ubuntu runtime
FROM golang:1.24-bookworm AS builder

# Install build dependencies for CGO (SQLite)
RUN apt-get update && apt-get install -y git gcc libc6-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy go mod files first for caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Copy built web assets from web-builder
COPY --from=web-builder /app/web/dist ./web/dist

# Build the binary with CGO for SQLite
# Use CACHEBUST to force rebuild when needed
ARG CACHEBUST=1
RUN echo "Build timestamp: $CACHEBUST" && CGO_ENABLED=1 GOOS=linux go build -o openflix-server ./cmd/server

# Runtime stage - Use Ubuntu for better NVIDIA compatibility
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies (including X11 libraries needed for Chrome)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tzdata \
    sqlite3 \
    wget \
    curl \
    xz-utils \
    pciutils \
    gnupg \
    libva2 \
    libva-drm2 \
    vainfo \
    mesa-va-drivers \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libvulkan1 \
    libx11-6 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome (works properly in Docker unlike Ubuntu's snap-based chromium)
RUN wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y /tmp/chrome.deb \
    && rm /tmp/chrome.deb \
    && rm -rf /var/lib/apt/lists/*

# Download jellyfin-ffmpeg with full hardware encoding support (NVENC, QSV, VAAPI)
RUN mkdir -p /opt/ffmpeg && \
    wget -q https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v7.1.3-1/jellyfin-ffmpeg_7.1.3-1_portable_linux64-gpl.tar.xz -O /tmp/ffmpeg.tar.xz && \
    tar -xf /tmp/ffmpeg.tar.xz -C /opt/ffmpeg && \
    rm /tmp/ffmpeg.tar.xz && \
    chmod +x /opt/ffmpeg/ffmpeg /opt/ffmpeg/ffprobe && \
    ln -sf /opt/ffmpeg/ffmpeg /usr/local/bin/ffmpeg && \
    ln -sf /opt/ffmpeg/ffprobe /usr/local/bin/ffprobe

# Install Comskip for commercial detection
RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libargtable2-dev \
    libavformat-dev \
    libavcodec-dev \
    libavutil-dev \
    libswscale-dev \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/erikkaashoek/Comskip.git /tmp/comskip \
    && cd /tmp/comskip \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && rm -rf /tmp/comskip

# Install Tailscale for remote access
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null \
    && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list \
    && apt-get update \
    && apt-get install -y tailscale \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/openflix-server .

# Create directories
RUN mkdir -p /data /app/downloads /app/recordings /app/transcode /app/config

# Copy Comskip configuration
COPY comskip.ini /app/config/comskip.ini

# Copy downloads folder if it exists (for APK files)
COPY --from=builder /app/downloads/ /app/downloads/

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create Tailscale directories
RUN mkdir -p /data/tailscale /var/run/tailscale

# Expose port
EXPOSE 32400

# Environment variables
ENV OPENFLIX_HOST=0.0.0.0
ENV OPENFLIX_PORT=32400
ENV OPENFLIX_DB_DRIVER=sqlite
ENV OPENFLIX_DB_DSN=/data/openflix.db
ENV OPENFLIX_RECORDING_DIR=/data/recordings
ENV OPENFLIX_TRANSCODE_DIR=/data/transcode

# Chrome path for chromedp (Gracenote EPG)
ENV CHROME_PATH=/usr/bin/google-chrome-stable

# Comskip for commercial detection
ENV OPENFLIX_COMSKIP_PATH=/usr/local/bin/comskip
ENV OPENFLIX_COMSKIP_INI=/app/config/comskip.ini

# NVIDIA environment variables (set by nvidia-container-runtime when using --gpus)
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,video,utility

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:32400/health | grep -q ok || exit 1

# Run the server via entrypoint (starts tailscaled first)
CMD ["/app/entrypoint.sh"]
