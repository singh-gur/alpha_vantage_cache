# Alpha Vantage Cache - Justfile
# Run `just` or `just --list` to see all available recipes

# ============================================================================
# SERVICES
# ============================================================================

# Start all services
up:
    @echo "Starting Alpha Vantage cache services..."
    docker-compose up -d
    @echo ""
    @echo "Services started:"
    @echo "  - API Cache Proxy: http://localhost:8080"
    @echo "  - Valkey:          localhost:6379"

# Stop all services
down:
    @echo "Stopping services..."
    docker-compose down
    @echo "Services stopped"

# Restart all services
restart: down up

# View logs from all services
logs:
    docker-compose logs -f

# View logs for proxy service
logs-proxy:
    docker-compose logs -f api-cache

# View logs for valkey service
logs-valkey:
    docker-compose logs -f valkey

# Full rebuild (pull latest images and recreate containers)
rebuild:
    @echo "Pulling latest images and rebuilding..."
    docker-compose pull
    docker-compose up -d --force-recreate
    @echo "Rebuild complete"

# ============================================================================
# HEALTH & STATUS
# ============================================================================

# Check if services are healthy
health:
    @echo "Checking service health..."
    @curl -s http://localhost:8080/health | jq '.' || echo "Service not responding on port 8080"

# Check Valkey connectivity
valkey-ping:
    @echo "Checking Valkey connection..."
    docker exec alpha-vantage-cache-valkey valkey-cli ping

# ============================================================================
# CACHE OPERATIONS
# ============================================================================

# View cache keys in Valkey
cache-keys:
    @echo "Cache keys in Valkey:"
    docker exec alpha-vantage-cache-valkey valkey-cli KEYS 'cache:*' | head -50

# Count cache entries
cache-count:
    @echo "Cache entry count:"
    docker exec alpha-vantage-cache-valkey valkey-cli KEYS 'cache:*' | wc -l

# Clear all cache
cache-clear:
    @echo "Clearing all cache..."
    docker exec alpha-vantage-cache-valkey valkey-cli FLUSHDB
    @echo "Cache cleared"

# Monitor Valkey commands in real-time
cache-monitor:
    @echo "Monitoring Valkey commands (Ctrl+C to stop)..."
    docker exec -it alpha-vantage-cache-valkey valkey-cli MONITOR

# ============================================================================
# TESTING
# ============================================================================

# Test cache with a sample Alpha Vantage request
# Usage: just test-cache FUNCTION SYMBOL [API_KEY]
test-cache function="TIME_SERIES_DAILY" symbol="IBM" api_key="demo":
    @echo "Testing cache with {{function}} for {{symbol}}..."
    @echo "First request (cache MISS):"
    curl -s "http://localhost:8080/query?function={{function}}&symbol={{symbol}}&apikey={{api_key}}" | jq '.metadata' 2>/dev/null || echo "Response received"
    @echo ""
    @echo "Second request (cache HIT):"
    curl -s "http://localhost:8080/query?function={{function}}&symbol={{symbol}}&apikey={{api_key}}" | jq '.metadata' 2>/dev/null || echo "Response received"
    @echo ""
    @echo "Check X-Cache header for HIT/MISS:"
    curl -sI "http://localhost:8080/query?function={{function}}&symbol={{symbol}}&apikey={{api_key}}" | grep -i "x-cache"

# Test intraday endpoint (1 min TTL)
test-intraday symbol="IBM":
    just test-cache "TIME_SERIES_INTRADAY" "{{symbol}}"

# Test daily endpoint (1 hour TTL)
test-daily symbol="IBM":
    just test-cache "TIME_SERIES_DAILY" "{{symbol}}"

# Test global quote endpoint (1 min TTL)
test-quote symbol="IBM":
    just test-cache "GLOBAL_QUOTE" "{{symbol}}"

# Test currency exchange endpoint (1 min TTL)
test-currency from="USD" to="EUR":
    @echo "Testing currency exchange rate for {{from}}/{{to}}..."
    @echo "First request (cache MISS):"
    curl -s "http://localhost:8080/query?function=CURRENCY_EXCHANGE_RATE&from_currency={{from}}&to_currency={{to}}&apikey=demo" | jq '.RealtimeCurrencyExchangeRate' 2>/dev/null || echo "Response received"

# ============================================================================
# DEVELOPMENT
# ============================================================================

# Install dependencies (if any)
deps:
    @echo "No local dependencies required for this project."

# Format config.yaml (placeholder - YAML doesn't auto-format well)
fmt:
    @echo "Config file is YAML - manual formatting required if needed."

# Show config file location
config:
    @echo "Config file: $(pwd)/config.yaml"

# Show docker-compose file location
compose-file:
    @echo "Docker Compose file: $(pwd)/docker-compose.yml"

# ============================================================================
# INFORMATION
# ============================================================================

# Show help
default:
    @just --list

# Show project info
info:
    @echo "Alpha Vantage API Cache"
    @echo "========================"
    @echo ""
    @echo "Architecture:"
    @echo "  Client -> API Cache Proxy (8080) -> Alpha Vantage API"
    @echo "                      |"
    @echo "                 Valkey Cache"
    @echo ""
    @echo "Alpha Vantage API: https://www.alphavantage.co/documentation/"
    @echo "API Cache Proxy:   https://github.com/singh-gur/api_cache"
    @echo ""
    @echo "Common endpoints:"
    @echo "  - /query?function=TIME_SERIES_DAILY&symbol=IBM"
    @echo "  - /query?function=GLOBAL_QUOTE&symbol=IBM"
    @echo "  - /query?function=CURRENCY_EXCHANGE_RATE&from_currency=USD&to_currency=EUR"
    @echo ""
    @echo "TTL settings:"
    @echo "  - Intraday/Quotes:    60s"
    @echo "  - Daily data:         1h"
    @echo "  - Weekly data:        6h"
    @echo "  - Monthly data:       12h"
    @echo "  - Fundamentals:       24h"
    @echo "  - Technical indic.:   5m"
    @echo ""
    @echo "Run 'just --list' for all available recipes."

# Check API key usage stats (approximate based on cache)
stats:
    @echo "Cache statistics:"
    @echo "================="
    @echo "Total cache keys: $$(docker exec alpha-vantage-cache-valkey valkey-cli KEYS 'cache:*' | wc -l)"
    @echo ""
    @echo "Memory usage:"
    docker exec alpha-vantage-cache-valkey valkey-cli INFO memory | head -10
