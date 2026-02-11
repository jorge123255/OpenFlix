#!/bin/bash
set -e

# Start tailscaled in the background (userspace networking mode for containers)
echo "Starting Tailscale daemon..."
tailscaled --state=/data/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock --tun=userspace-networking &

# Wait for tailscaled to be ready
sleep 2

# Check if Tailscale is already authenticated
if tailscale status &>/dev/null; then
    echo "Tailscale is connected"
else
    echo "Tailscale is not connected - use the admin UI or API to authenticate"
fi

# Start the OpenFlix server
echo "Starting OpenFlix server..."
exec ./openflix-server
