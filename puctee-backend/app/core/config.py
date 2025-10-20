from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database (Neon/Supabase PostgreSQL)
    DATABASE_URL: str
    
    # Security
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    ALGORITHM: str = "HS256"

    # AWS Settings (for S3 - can migrate to R2 later)
    AWS_ACCESS_KEY_ID: str
    AWS_SECRET_ACCESS_KEY: str
    AWS_REGION: str = "ap-northeast-1"
    AWS_S3_BUCKET: str
    
    # Redis (use Upstash Redis for Cloudflare Workers)
    REDIS_URL: str

    # APNs settings
    APNS_SECRET_ARN: str 
    APNS_AUTH_KEY_ID: str
    APNS_TEAM_ID: str
    APNS_BUNDLE_ID: str
    APNS_USE_SANDBOX: bool

    # Environment
    ENVIRONMENT: str = "development"

    class Config:
        env_file = ".env"

settings = Settings() 