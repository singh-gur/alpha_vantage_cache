# Alpha Vantage API Cache

Docker Compose solution that provides a caching layer in front of the Alpha Vantage API using [api_cache](https://github.com/singh-gur/api_cache) and Valkey.

## Architecture

```
Client -> API Cache Proxy (8080) -> Alpha Vantage API
              |
         Valkey Cache
```

## Quick Start

```bash
# Start services
just up

# Test caching
just test-daily symbol=IBM

# View logs
just logs
```

## Usage

Make requests to the cache proxy instead of Alpha Vantage directly:

```bash
# Daily time series
curl "http://localhost:8080/query?function=TIME_SERIES_DAILY&symbol=IBM&apikey=YOUR_KEY"

# Global quote
curl "http://localhost:8080/query?function=GLOBAL_QUOTE&symbol=IBM&apikey=YOUR_KEY"

# Currency exchange
curl "http://localhost:8080/query?function=CURRENCY_EXCHANGE_RATE&from_currency=USD&to_currency=EUR&apikey=YOUR_KEY"
```

The `X-Cache` header indicates cache status (`HIT` or `MISS`).

## TTL Settings

| Data Type | TTL | Rationale |
|-----------|-----|-----------|
| Intraday/Quotes | 1 min | Real-time data, frequent updates |
| Daily | 1 hour | Updates after market close |
| Weekly | 6 hours | Updates weekly |
| Monthly | 12 hours | Updates monthly |
| Fundamentals | 24 hours | Quarterly/annual data |
| Technical Indicators | 5 min | Derived from price data |

## Commands

```bash
just up              # Start services
just down            # Stop services
just logs            # View logs
just health          # Check health
just test-cache      # Test caching
just cache-clear     # Clear cache
just cache-keys      # View cache entries
just rebuild         # Pull latest images
just info            # Project info
```

## Configuration

Edit `config.yaml` to adjust TTLs, rate limits, or cache key parameters.

## Requirements

- Docker
- Docker Compose
- Just (optional, run commands manually with docker-compose)
