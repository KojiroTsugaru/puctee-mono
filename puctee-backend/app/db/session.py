from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
import os
import logging

logger = logging.getLogger(__name__)

# Ensure we use asyncpg driver for async operations
url = settings.DATABASE_URL
if url.startswith("postgresql://"):
    url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
    logger.info(f"Converted DATABASE_URL to use asyncpg driver")
elif url.startswith("postgresql+asyncpg://"):
    logger.info(f"DATABASE_URL already uses asyncpg driver")
else:
    logger.warning(f"DATABASE_URL has unexpected format: {url[:20]}...")

# Railway environment detection
is_production = os.getenv("ENVIRONMENT") == "production"

if "localhost" in url:
    # Disable SSL for local development
    connect_args = {
        "prepared_statement_cache_size": 0,
        "statement_cache_size": 0
    }
else:
    # Railway/Supabase connection pooling (pgbouncer) in Transaction Mode
    # CRITICAL: pgbouncer in transaction mode does NOT support:
    # - Prepared statements (must disable both caches)
    # - Server-side cursors
    # - Advisory locks
    connect_args = {
        "ssl": "require",
        "prepared_statement_cache_size": 0,
        "statement_cache_size": 0,  # Disable statement cache completely
        "server_settings": {
            "jit": "off"  # Disable JIT to reduce statement preparation
        }
    }

# Optimize for Railway with pgbouncer Transaction Mode
# Transaction Mode: Each transaction gets a new connection from the pool
# Best practices:
# - Keep pool_size small (pgbouncer handles the real pooling)
# - Use pool_pre_ping to detect stale connections
# - Recycle connections frequently to avoid state issues
# - Use pool_reset_on_return to ensure clean state
if is_production:
    engine = create_async_engine(
        url,
        echo=False,
        future=True,
        connect_args=connect_args,
        pool_pre_ping=True,  # CRITICAL: Detect stale connections before use
        pool_size=3,  # Small pool - pgbouncer does the real pooling
        max_overflow=5,  # Limited overflow for burst traffic
        pool_timeout=30,
        pool_recycle=300,  # Recycle every 5 minutes (aggressive for transaction mode)
        pool_reset_on_return="rollback"  # Ensure clean state between requests
    )
else:
    # Local development with similar settings
    engine = create_async_engine(
        url,
        echo=False,
        future=True,
        connect_args=connect_args,
        pool_size=2,
        max_overflow=3,
        pool_timeout=30,
        pool_recycle=3600,
        pool_reset_on_return="rollback"
    )

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close() 