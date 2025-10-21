from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
import os

# Ensure we use asyncpg driver for async operations
url = settings.DATABASE_URL
if url.startswith("postgresql://"):
    url = url.replace("postgresql://", "postgresql+asyncpg://", 1)

# Railway environment detection
is_production = os.getenv("ENVIRONMENT") == "production"

if "localhost" in url:
    # Disable SSL for local development
    connect_args = {}
else:
    # Supabase connection pooling (pgbouncer) requires statement_cache_size=0
    # to disable prepared statements
    connect_args = {
        "ssl": "require",
        "server_settings": {"jit": "off"},
        "statement_cache_size": 0
    }

# Optimize for Railway (persistent connections)
if is_production:
    engine = create_async_engine(
        url,
        echo=False,
        future=True,
        connect_args=connect_args,
        pool_pre_ping=True,  # Enable pre-ping for connection health
        pool_size=5,  # Moderate pool for Railway
        max_overflow=10,  # Allow overflow for traffic spikes
        pool_timeout=30,
        pool_recycle=3600,  # Recycle connections every hour
        # Disable prepared statements for pgbouncer compatibility
        execution_options={"prepared_statement_cache_size": 0}
    )
else:
    # Local development with similar settings
    engine = create_async_engine(
        url,
        echo=False,
        future=True,
        connect_args=connect_args,
        pool_size=5,
        max_overflow=10,
        pool_timeout=30,
        pool_recycle=3600,
        execution_options={"prepared_statement_cache_size": 0}
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