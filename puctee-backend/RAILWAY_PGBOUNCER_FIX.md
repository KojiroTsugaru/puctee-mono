# Railway pgbouncer Transaction Mode Fix

## Problem
Railway uses pgbouncer in **transaction mode**, which does not support:
- Prepared statements
- Server-side cursors  
- Advisory locks
- Session-level state

This caused intermittent 500 errors with SQLAlchemy/asyncpg.

## Solution Applied

### 1. Disabled Statement Caching (CRITICAL)
```python
connect_args = {
    "prepared_statement_cache_size": 0,  # Disable prepared statement cache
    "statement_cache_size": 0,           # Disable statement cache completely
    "server_settings": {
        "jit": "off"                     # Disable JIT compilation
    }
}
```

### 2. Optimized Connection Pool for pgbouncer
```python
engine = create_async_engine(
    url,
    pool_pre_ping=True,              # Detect stale connections
    pool_size=3,                     # Small pool (pgbouncer handles pooling)
    max_overflow=5,                  # Limited overflow
    pool_recycle=300,                # Recycle every 5 minutes
    pool_reset_on_return="rollback"  # Clean state between requests
)
```

### Key Changes:
- **pool_size: 5 → 3**: pgbouncer does the real pooling
- **pool_recycle: 1800 → 300**: More aggressive recycling (5 min vs 30 min)
- **Added pool_reset_on_return**: Ensures clean connection state
- **Added statement_cache_size: 0**: Completely disables statement caching

## Why This Works

1. **No Prepared Statements**: Both cache sizes set to 0 prevents asyncpg from trying to prepare statements
2. **Connection Health**: `pool_pre_ping=True` detects broken connections before use
3. **Clean State**: `pool_reset_on_return="rollback"` ensures no transaction state leaks
4. **Aggressive Recycling**: 5-minute recycle prevents stale connection issues
5. **Small Pool**: Let pgbouncer handle the real connection pooling

## Testing Checklist

- [ ] Deploy to Railway
- [ ] Monitor logs for prepared statement errors
- [ ] Test `/api/users/me` endpoint multiple times
- [ ] Check for 500 errors in high-traffic scenarios
- [ ] Verify connection pool metrics in Railway dashboard

## Monitoring

Watch for these log messages:
- ✅ `Converted DATABASE_URL to use asyncpg driver`
- ❌ `prepared statements not supported` (should NOT appear)
- ❌ `pool timeout` (should be rare)

## Rollback Plan

If issues persist, revert to these settings:
```python
pool_size=2
max_overflow=3  
pool_recycle=600
```

## References
- [SQLAlchemy asyncpg docs](https://docs.sqlalchemy.org/en/20/dialects/postgresql.html#module-sqlalchemy.dialects.postgresql.asyncpg)
- [pgbouncer transaction mode limitations](https://www.pgbouncer.org/features.html)
- Railway pgbouncer configuration
