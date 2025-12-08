#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================"
echo "  Mirror Infrastructure Setup"
echo "========================================${NC}"
echo ""

if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Error: Do not run this script as root${NC}"
    echo "Run as your normal user account."
    exit 1
fi

echo -e "${BLUE}[1/6] Installing dependencies${NC}"

if ! command -v podman &> /dev/null; then
    echo "Installing Podman..."
    if [ -f /etc/fedora-release ]; then
        sudo dnf install -y podman
    elif [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y podman
    else
        echo -e "${RED}Unsupported distro. Install Podman manually.${NC}"
        exit 1
    fi
else
    echo "Podman installed"
fi

if ! command -v podman-compose &> /dev/null; then
    echo "Installing podman-compose..."
    pip install --user podman-compose
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "podman-compose installed"
fi
de
echo ""
echo -e "${BLUE}[2/6] Enabling user lingering${NC}"
loginctl enable-linger $USER
echo "User lingering enabled"

echo ""
echo -e "${BLUE}[3/6] Creating network${NC}"
if podman network exists mirror-network 2>/dev/null; then
    echo "Network 'mirror-network' exists"
else
    podman network create mirror-network
    echo "Network created"
fi

echo ""
echo -e "${BLUE}[4/6] Creating volumes${NC}"

if podman volume exists osu-cookies 2>/dev/null; then
    echo "Volume 'osu-cookies' exists"
else
    podman volume create osu-cookies
    echo "Volume 'osu-cookies' created"
fi

if podman volume exists portainer_data 2>/dev/null; then
    echo "Volume 'portainer_data' exists"
else
    podman volume create portainer_data
    echo "Volume 'portainer_data' created"
fi

echo ""
echo -e "${BLUE}[5/6] Enabling auto-start service${NC}"
systemctl --user enable --now podman-restart.service
echo "Service enabled"


echo ""
echo -e "${BLUE}[6/6] Building and starting services${NC}"
podman-compose up -d --build

echo ""
echo -e "${BLUE}Starting podman-exporter (requires special userns mode)${NC}"
podman run -d --name podman-exporter --restart=always --network=host \
    -v /run/user/$(id -u)/podman/podman.sock:/run/podman/podman.sock:ro \
    -e CONTAINER_HOST=unix:///run/podman/podman.sock \
    --userns=keep-id quay.io/navidys/prometheus-podman-exporter:latest

echo ""
echo -e "${GREEN}========================================"
echo "  Setup Complete"
echo "========================================${NC}"
echo ""
echo "Services will auto-start on boot and auto-restart on failure."
echo ""