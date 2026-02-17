#!/usr/bin/env bash
set -euo pipefail

# OpenFlix Server Setup Script
# Usage: curl -sSL https://your-domain/setup.sh | bash
#   or:  bash setup.sh [--standalone] [--docker] [--port PORT] [--data-dir DIR]

OPENFLIX_VERSION="${OPENFLIX_VERSION:-latest}"
OPENFLIX_IMAGE="sunnyside1/openflix-server:${OPENFLIX_VERSION}"
OPENFLIX_PORT="${OPENFLIX_PORT:-32400}"
OPENFLIX_DATA_DIR="${OPENFLIX_DATA_DIR:-/opt/openflix/data}"
INSTALL_MODE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log()   { echo -e "${GREEN}[OpenFlix]${NC} $*"; }
warn()  { echo -e "${YELLOW}[OpenFlix]${NC} $*"; }
error() { echo -e "${RED}[OpenFlix]${NC} $*" >&2; }
info()  { echo -e "${BLUE}[OpenFlix]${NC} $*"; }

# ============ Detection ============

detect_os() {
    local os
    os="$(uname -s)"
    case "$os" in
        Linux)  echo "linux" ;;
        Darwin) echo "darwin" ;;
        *)      error "Unsupported OS: $os"; exit 1 ;;
    esac
}

detect_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)   echo "amd64" ;;
        aarch64|arm64)  echo "arm64" ;;
        *)              error "Unsupported architecture: $arch"; exit 1 ;;
    esac
}

detect_init_system() {
    if command -v systemctl &>/dev/null && pidof systemd &>/dev/null; then
        echo "systemd"
    elif command -v rc-service &>/dev/null; then
        echo "openrc"
    else
        echo "none"
    fi
}

has_docker() {
    command -v docker &>/dev/null
}

has_docker_compose() {
    docker compose version &>/dev/null 2>&1 || docker-compose --version &>/dev/null 2>&1
}

# ============ Parse Arguments ============

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --standalone) INSTALL_MODE="standalone"; shift ;;
            --docker)     INSTALL_MODE="docker"; shift ;;
            --port)       OPENFLIX_PORT="$2"; shift 2 ;;
            --data-dir)   OPENFLIX_DATA_DIR="$2"; shift 2 ;;
            --version)    OPENFLIX_VERSION="$2"; OPENFLIX_IMAGE="sunnyside1/openflix-server:${OPENFLIX_VERSION}"; shift 2 ;;
            --help|-h)    usage; exit 0 ;;
            *)            error "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
}

usage() {
    cat <<EOF
OpenFlix Server Setup

Usage: setup.sh [OPTIONS]

Options:
  --docker        Install using Docker (recommended)
  --standalone    Install as standalone binary with systemd service
  --port PORT     Server port (default: 32400)
  --data-dir DIR  Data directory (default: /opt/openflix/data)
  --version VER   Version tag (default: latest)
  --help          Show this help

Environment Variables:
  OPENFLIX_VERSION   Docker image version tag
  OPENFLIX_PORT      Server port
  OPENFLIX_DATA_DIR  Data directory path
EOF
}

# ============ Docker Install ============

install_docker() {
    log "Installing OpenFlix via Docker..."

    if ! has_docker; then
        warn "Docker not found. Installing Docker..."
        if [[ "$(detect_os)" == "linux" ]]; then
            curl -fsSL https://get.docker.com | sh
            systemctl enable --now docker 2>/dev/null || true
        else
            error "Please install Docker Desktop for macOS: https://docs.docker.com/desktop/mac/install/"
            exit 1
        fi
    fi

    log "Pulling OpenFlix image..."
    docker pull "$OPENFLIX_IMAGE"

    # Create data directory
    mkdir -p "$OPENFLIX_DATA_DIR"
    mkdir -p "$OPENFLIX_DATA_DIR/recordings"
    mkdir -p "$OPENFLIX_DATA_DIR/transcode"

    # Stop existing container if running
    if docker ps -a --format '{{.Names}}' | grep -q '^openflix$'; then
        warn "Stopping existing OpenFlix container..."
        docker stop openflix 2>/dev/null || true
        docker rm openflix 2>/dev/null || true
    fi

    # Generate JWT secret if not set
    JWT_SECRET="${JWT_SECRET:-$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p)}"

    log "Starting OpenFlix container..."
    docker run -d \
        --name openflix \
        --restart unless-stopped \
        -p "${OPENFLIX_PORT}:32400" \
        -v "${OPENFLIX_DATA_DIR}:/data" \
        -v "${OPENFLIX_DATA_DIR}/recordings:/app/recordings" \
        -v "${OPENFLIX_DATA_DIR}/transcode:/app/transcode" \
        -e "JWT_SECRET=${JWT_SECRET}" \
        -e "TZ=$(cat /etc/timezone 2>/dev/null || echo UTC)" \
        "$OPENFLIX_IMAGE"

    # Wait for server to be ready
    log "Waiting for server to start..."
    for i in $(seq 1 30); do
        if curl -sf "http://localhost:${OPENFLIX_PORT}/api/status" &>/dev/null; then
            break
        fi
        sleep 1
    done

    if curl -sf "http://localhost:${OPENFLIX_PORT}/api/status" &>/dev/null; then
        log "OpenFlix is running!"
    else
        warn "Server may still be starting. Check: docker logs openflix"
    fi
}

# ============ Standalone Install ============

install_standalone() {
    local os arch binary_name download_url
    os="$(detect_os)"
    arch="$(detect_arch)"
    binary_name="openflix-server-${os}-${arch}"

    log "Installing OpenFlix standalone binary..."
    log "Platform: ${os}/${arch}"

    # Check for required tools
    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        error "curl or wget required"
        exit 1
    fi

    # Create directories
    mkdir -p /opt/openflix/bin
    mkdir -p "$OPENFLIX_DATA_DIR"
    mkdir -p "$OPENFLIX_DATA_DIR/recordings"
    mkdir -p "$OPENFLIX_DATA_DIR/transcode"

    # Download binary
    download_url="https://github.com/openflix/openflix-server/releases/download/${OPENFLIX_VERSION}/${binary_name}"
    log "Downloading from: ${download_url}"

    if command -v curl &>/dev/null; then
        curl -fsSL -o /opt/openflix/bin/openflix-server "$download_url"
    else
        wget -q -O /opt/openflix/bin/openflix-server "$download_url"
    fi
    chmod +x /opt/openflix/bin/openflix-server

    # Generate JWT secret
    JWT_SECRET="${JWT_SECRET:-$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p)}"

    # Create environment file
    cat > /opt/openflix/openflix.env <<ENVEOF
OPENFLIX_PORT=${OPENFLIX_PORT}
OPENFLIX_DATA_DIR=${OPENFLIX_DATA_DIR}
JWT_SECRET=${JWT_SECRET}
TZ=$(cat /etc/timezone 2>/dev/null || echo UTC)
ENVEOF
    chmod 600 /opt/openflix/openflix.env

    # Create systemd service
    local init_system
    init_system="$(detect_init_system)"

    if [[ "$init_system" == "systemd" ]]; then
        log "Creating systemd service..."
        cat > /etc/systemd/system/openflix.service <<SVCEOF
[Unit]
Description=OpenFlix Media Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
EnvironmentFile=/opt/openflix/openflix.env
ExecStart=/opt/openflix/bin/openflix-server
WorkingDirectory=/opt/openflix
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

        systemctl daemon-reload
        systemctl enable openflix
        systemctl start openflix

        log "Systemd service created and started"
    else
        warn "No systemd detected. Start manually:"
        info "  /opt/openflix/bin/openflix-server"
    fi

    # Wait for server to be ready
    log "Waiting for server to start..."
    for i in $(seq 1 15); do
        if curl -sf "http://localhost:${OPENFLIX_PORT}/api/status" &>/dev/null; then
            break
        fi
        sleep 1
    done

    if curl -sf "http://localhost:${OPENFLIX_PORT}/api/status" &>/dev/null; then
        log "OpenFlix is running!"
    else
        warn "Server may still be starting. Check: journalctl -u openflix -f"
    fi
}

# ============ Main ============

main() {
    parse_args "$@"

    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       OpenFlix Server Setup          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""

    local os arch
    os="$(detect_os)"
    arch="$(detect_arch)"
    info "Detected: ${os}/${arch}"
    info "Port: ${OPENFLIX_PORT}"
    info "Data: ${OPENFLIX_DATA_DIR}"

    # Auto-detect install mode if not specified
    if [[ -z "$INSTALL_MODE" ]]; then
        if has_docker; then
            INSTALL_MODE="docker"
            info "Docker detected - using Docker install"
        else
            INSTALL_MODE="standalone"
            info "Docker not found - using standalone install"
        fi
    fi

    echo ""

    case "$INSTALL_MODE" in
        docker)
            install_docker
            ;;
        standalone)
            install_standalone
            ;;
        *)
            error "Unknown install mode: $INSTALL_MODE"
            exit 1
            ;;
    esac

    echo ""
    log "Setup complete!"
    echo ""
    info "Web UI:     http://localhost:${OPENFLIX_PORT}"
    info "API:        http://localhost:${OPENFLIX_PORT}/api/status"
    info "Data dir:   ${OPENFLIX_DATA_DIR}"
    echo ""

    # Try to open browser
    if [[ "$(detect_os)" == "darwin" ]]; then
        open "http://localhost:${OPENFLIX_PORT}" 2>/dev/null || true
    elif command -v xdg-open &>/dev/null; then
        xdg-open "http://localhost:${OPENFLIX_PORT}" 2>/dev/null || true
    fi
}

main "$@"
