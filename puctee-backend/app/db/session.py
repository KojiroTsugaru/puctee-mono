from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
import os

# Ensure we use asyncpg driver for async operations
url = settings.DATABASE_URL
if url.startswith("postgresql://"):
    url = url.replace("postgresql://", "postgresql+asyncpg://", 1)

# Cloudflare Workers environment detection
is_cloudflare = os.getenv("ENVIRONMENT") in ["production", "development"]

if "localhost" in url:
    # Disable SSL for local development
    connect_args = {"ssl": False}
else:
    # Neon/Supabase use standard SSL certificates (no custom CA bundle needed)
    connect_args = {"ssl": "require"}

# Optimize for Cloudflare Workers (short-lived connections)
if is_cloudflare:
    engine = create_async_engine(
        url,
        echo=False,
        future=True,
        connect_args=connect_args,
        pool_pre_ping=False,  # Skip pre-ping for lower latency
        pool_size=1,  # Minimal pool for Workers
        max_overflow=0,  # No overflow for Workers
        pool_timeout=10,
        pool_recycle=300  # Shorter recycle time
    )
else:
    # Traditional server configuration
    engine = create_async_engine(
        url,
        echo=False,
        future=True,
        connect_args=connect_args,
        pool_pre_ping=True,
        pool_size=5,
        max_overflow=10,
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