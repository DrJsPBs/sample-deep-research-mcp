#!/bin/bash

# Deploy Cupcake MCP Server to cupcake.onemainarmy.com

set -e

echo "🚀 Deploying Cupcake MCP Server..."

# Build and start the service
docker compose up -d --build

echo "✅ Cupcake MCP Server deployed!"
echo "🌐 Access at: https://cupcake.onemainarmy.com"
echo "🔍 Health check: https://cupcake.onemainarmy.com/health"
echo "📊 SSE endpoint: https://cupcake.onemainarmy.com/sse"

# Show logs
echo ""
echo "📋 Recent logs:"
docker compose logs --tail=20 