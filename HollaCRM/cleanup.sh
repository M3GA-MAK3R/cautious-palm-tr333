#!/bin/bash

# Cleanup script for HollaCRM
# Stops and removes all containers, networks, and optionally volumes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🧹 Cleaning up HollaCRM..."

# Function to confirm action
confirm() {
    read -p "$1 [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        exit 1
    fi
}

# Stop all services
echo "🛑 Stopping services..."
docker compose down || true

# Remove containers
echo "🗑️ Removing containers..."
docker compose down --remove-orphans || true

# Remove unused networks
echo "🌐 Removing unused networks..."
docker network prune -f || true

# Remove unused images
echo "🖼️ Removing unused images..."
docker image prune -f || true

# Ask about volumes
confirm "📦 Remove all volumes? This will delete all data!"
if [[ $? -eq 0 ]]; then
    echo "📋 Removing volumes..."
    docker compose down -v || true
    docker volume prune -f || true
    echo "✅ All volumes removed"
else
    echo "📋 Volumes preserved"
fi

# Ask about full system cleanup
confirm "🧽 Perform full Docker cleanup (remove all unused containers, images, volumes, networks)?"
if [[ $? -eq 0 ]]; then
    echo "🧽 Performing full cleanup..."
    docker system prune -af --volumes || true
    echo "✅ Full Docker cleanup completed"
else
    echo "📋 Partial cleanup completed"
fi

# Show final status
echo ""
echo "📊 Docker Status:"
docker system df

echo ""
echo "🔍 Remaining containers:"
docker ps -a

echo ""
echo "📦 Remaining volumes:"
docker volume ls

echo ""
echo "✅ Cleanup completed!"
echo "💡 To start fresh: ./deploy.sh"