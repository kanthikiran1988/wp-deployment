#!/bin/bash

# Exit on error
set -e

echo "🔄 Starting deployment process..."

# Stash any local changes
echo "📦 Stashing local changes..."
git stash

# Pull latest changes
echo "⬇️ Pulling latest changes from repository..."
git pull

# Pop stashed changes if any
if git stash list | grep -q "stash@{0}"; then
    echo "📦 Restoring local changes..."
    git stash pop
fi

# Check if docker-compose is running
if docker-compose ps | grep -q "Up"; then
    echo "🛑 Stopping running containers..."
    docker-compose down
fi

# Start the services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
timeout=300  # 5 minutes timeout
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose ps | grep -q "unhealthy\|exit"; then
        echo "❌ Some services failed to start properly"
        docker-compose logs
        exit 1
    fi
    
    if ! docker-compose ps | grep -q "starting"; then
        echo "✅ All services are running!"
        break
    fi
    
    sleep 5
    elapsed=$((elapsed + 5))
    echo "⏳ Still waiting for services... ($elapsed seconds elapsed)"
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ Timeout waiting for services to be healthy"
    docker-compose logs
    exit 1
fi

echo "✅ Deployment completed successfully!" 