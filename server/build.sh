#!/bin/bash
#
# OpenFlix Server Build Script
# ============================
# Builds the OpenFlix media server for your platform
#
# Requirements:
#   - Go 1.24.0 or later (https://go.dev/dl/)
#   - GCC/Clang (for SQLite - CGO is required)
#   - Git (to clone the repo)
#
# Usage:
#   ./build.sh              # Build for current platform
#   ./build.sh all          # Build for Linux, macOS, and Windows (requires cross-compilers)
#   ./build.sh linux        # Build for Linux only
#   ./build.sh darwin       # Build for macOS only
#   ./build.sh windows      # Build for Windows only
#
# Note: Cross-compilation requires appropriate C cross-compilers for CGO.
#       For simple testing, just build for your current platform.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project info
PROJECT_NAME="openflix"
VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS="-s -w -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME}"

# Output directory
OUTPUT_DIR="./bin"

# Detect current platform
CURRENT_OS=$(go env GOOS)
CURRENT_ARCH=$(go env GOARCH)

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════╗"
echo "║       OpenFlix Server Build Script        ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Check Go installation
check_go() {
    if ! command -v go &> /dev/null; then
        echo -e "${RED}ERROR: Go is not installed!${NC}"
        echo ""
        echo "Please install Go 1.24.0 or later:"
        echo "  - Download from: https://go.dev/dl/"
        echo "  - Or use your package manager:"
        echo "    macOS:   brew install go"
        echo "    Ubuntu:  sudo apt install golang-go"
        echo "    Windows: choco install golang"
        exit 1
    fi

    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    echo -e "${GREEN}✓${NC} Go version: ${GO_VERSION}"
    
    # Check minimum version (1.24.0)
    MIN_VERSION="1.24.0"
    if ! printf '%s\n%s\n' "$MIN_VERSION" "$GO_VERSION" | sort -V -C 2>/dev/null; then
        echo -e "${YELLOW}WARNING: Go ${MIN_VERSION}+ recommended (you have ${GO_VERSION})${NC}"
    fi
}

# Check for C compiler (needed for SQLite)
check_cc() {
    if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
        echo -e "${YELLOW}WARNING: No C compiler found (gcc/clang)${NC}"
        echo "SQLite requires CGO. Install a C compiler:"
        echo "  macOS:   xcode-select --install"
        echo "  Ubuntu:  sudo apt install build-essential"
        echo "  Windows: Install MinGW or use WSL"
    else
        CC=$(command -v gcc || command -v clang)
        echo -e "${GREEN}✓${NC} C compiler: $(basename $CC)"
    fi
}

# Download dependencies
download_deps() {
    echo -e "\n${BLUE}Downloading dependencies...${NC}"
    go mod download
    echo -e "${GREEN}✓${NC} Dependencies downloaded"
}

# Build for a specific platform
build_for() {
    local GOOS=$1
    local GOARCH=$2
    local OUTPUT_NAME=$3
    
    echo -e "\n${BLUE}Building for ${GOOS}/${GOARCH}...${NC}"
    
    # Add .exe for Windows
    if [ "$GOOS" = "windows" ]; then
        OUTPUT_NAME="${OUTPUT_NAME}.exe"
    fi
    
    # Check if cross-compiling
    if [ "$GOOS" != "$CURRENT_OS" ] || [ "$GOARCH" != "$CURRENT_ARCH" ]; then
        echo -e "${YELLOW}Note: Cross-compiling requires CGO cross-compiler${NC}"
    fi
    
    # Build with CGO enabled (required for SQLite)
    CGO_ENABLED=1 GOOS=$GOOS GOARCH=$GOARCH go build \
        -ldflags="${LDFLAGS}" \
        -o "${OUTPUT_DIR}/${OUTPUT_NAME}" \
        ./cmd/server
    
    # Get file size
    SIZE=$(ls -lh "${OUTPUT_DIR}/${OUTPUT_NAME}" | awk '{print $5}')
    echo -e "${GREEN}✓${NC} Built: ${OUTPUT_DIR}/${OUTPUT_NAME} (${SIZE})"
}

# Build for current platform only
build_current() {
    local OUTPUT_NAME="${PROJECT_NAME}"
    
    if [ "$CURRENT_OS" = "windows" ]; then
        OUTPUT_NAME="${PROJECT_NAME}.exe"
    fi
    
    build_for "$CURRENT_OS" "$CURRENT_ARCH" "$OUTPUT_NAME"
}

# Build for all platforms (requires cross-compilers)
build_all() {
    echo -e "${YELLOW}Building for all platforms...${NC}"
    echo -e "${YELLOW}Note: Cross-compilation requires C cross-compilers${NC}"
    
    # Build current platform first (always works)
    build_current
    
    # Try Linux if not on Linux
    if [ "$CURRENT_OS" != "linux" ]; then
        echo -e "\n${YELLOW}Skipping Linux cross-compile (requires linux cross-compiler)${NC}"
    fi
    
    # Try macOS if not on macOS  
    if [ "$CURRENT_OS" != "darwin" ]; then
        echo -e "\n${YELLOW}Skipping macOS cross-compile (requires darwin cross-compiler)${NC}"
    fi
    
    # Try Windows if not on Windows
    if [ "$CURRENT_OS" != "windows" ]; then
        echo -e "\n${YELLOW}Skipping Windows cross-compile (requires mingw-w64)${NC}"
    fi
}

# Main
main() {
    # Check Go
    check_go
    
    # Check C compiler
    check_cc
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Download deps
    download_deps
    
    # Parse arguments
    TARGET=${1:-"current"}
    
    case "$TARGET" in
        current|"")
            build_current
            ;;
        all)
            build_all
            ;;
        linux)
            if [ "$CURRENT_OS" = "linux" ]; then
                build_for "linux" "amd64" "${PROJECT_NAME}-linux-amd64"
            else
                echo -e "${RED}Cross-compiling to Linux requires CGO cross-compiler${NC}"
                echo "Build on a Linux machine instead, or use Docker."
                exit 1
            fi
            ;;
        darwin|macos)
            if [ "$CURRENT_OS" = "darwin" ]; then
                build_for "darwin" "amd64" "${PROJECT_NAME}-darwin-amd64"
                build_for "darwin" "arm64" "${PROJECT_NAME}-darwin-arm64"
            else
                echo -e "${RED}Cross-compiling to macOS requires darwin cross-compiler${NC}"
                echo "Build on a Mac instead."
                exit 1
            fi
            ;;
        windows)
            if [ "$CURRENT_OS" = "windows" ]; then
                build_for "windows" "amd64" "${PROJECT_NAME}-windows-amd64"
            else
                echo -e "${RED}Cross-compiling to Windows requires mingw-w64${NC}"
                echo "Install: brew install mingw-w64 (macOS) or apt install mingw-w64 (Linux)"
                exit 1
            fi
            ;;
        docker)
            echo -e "${BLUE}Building with Docker (all platforms)...${NC}"
            docker build -t openflix-builder .
            echo -e "${GREEN}✓${NC} Docker image built: openflix-builder"
            echo "Run: docker run -v \$(pwd)/bin:/out openflix-builder"
            ;;
        *)
            echo -e "${RED}Unknown target: $TARGET${NC}"
            echo ""
            echo "Usage: $0 [target]"
            echo ""
            echo "Targets:"
            echo "  current   Build for your current platform (default)"
            echo "  all       Build for all platforms (requires cross-compilers)"
            echo "  linux     Build for Linux"
            echo "  darwin    Build for macOS"
            echo "  windows   Build for Windows"
            echo "  docker    Build Docker image for multi-platform builds"
            exit 1
            ;;
    esac
    
    echo -e "\n${GREEN}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Build complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════${NC}"
    echo ""
    echo "Binaries are in: ${OUTPUT_DIR}/"
    ls -lh "${OUTPUT_DIR}/" 2>/dev/null || echo "(no binaries yet)"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Copy config.yaml.example to config.yaml"
    echo "  2. Edit config.yaml with your settings"
    echo "  3. Run: ${OUTPUT_DIR}/${PROJECT_NAME}"
    echo ""
}

# Run main
main "$@"
