# Cupcake MCP Server Deployment

This is the OpenAI sample Deep Research MCP server deployed at `cupcake.onemainarmy.com`.

## Quick Deploy

```bash
./deploy.sh
```

## Manual Deployment

1. **Build and start:**
   ```bash
   docker-compose up -d --build
   ```

2. **Check status:**
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

3. **Stop service:**
   ```bash
   docker-compose down
   ```

## Access Points

- **Main URL**: https://cupcake.onemainarmy.com
- **Health Check**: https://cupcake.onemainarmy.com/health
- **SSE Endpoint**: https://cupcake.onemainarmy.com/sse
- **MCP Messages**: https://cupcake.onemainarmy.com/messages/

## MCP Tools

This server provides two tools:

1. **`search(query)`** - Search cupcake orders by keyword
2. **`fetch(id)`** - Fetch a specific cupcake order by ID

## Data

The server uses the `records.json` file containing 303 cupcake orders with metadata including:
- Customer names
- Cupcake flavors
- Quantities
- Pickup/delivery information

## Traefik Configuration

The service is configured with Traefik labels for:
- Automatic SSL certificates via Let's Encrypt
- Host-based routing (`cupcake.onemainarmy.com`)
- Health checks
- Load balancing

## Network Requirements

Requires the `traefik_network` Docker network to be available for Traefik integration. 