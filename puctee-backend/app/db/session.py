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
    connect_args = {"prepared_statement_cache_size": 0}
else:
    # Supabase connection pooling (pgbouncer) in Transaction Mode
    # - Disable prepared statements (required for pgbouncer)
    # - Remove server_settings as they're not supported in Transaction Mode
    connect_args = {
        "ssl": "require",
        "prepared_statement_cache_size": 0
    }

# Optimize for Railway with Supabase Transaction Mode
# Transaction Mode allows more connections but requires careful pool management
if is_production:
    engine = create_async_engine(
        url,
        echo=False,
        future=True,
        connect_args=connect_args,
        pool_pre_ping=True,  # Enable pre-ping for connection health
        pool_size=5,  # Transaction Mode can handle more connections
        max_overflow=10,  # Allow burst traffic
        pool_timeout=30,
        pool_recycle=1800  # Recycle connections every 30 minutes (Transaction Mode best practice)
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
        pool_recycle=3600
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