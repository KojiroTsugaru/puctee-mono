from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database (Neon/Supabase PostgreSQL)
    DATABASE_URL: str
    
    # Security
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    ALGORITHM: str = "HS256"

    # AWS region is currently used only by the legacy EventBridge scheduler.
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    AWS_REGION: str = "ap-northeast-1"
    
    # Redis (use Upstash Redis or Railway Redis)
    # Optional if using Supabase Realtime
    REDIS_URL: str = ""

    # Supabase (Realtime and Storage)
    SUPABASE_URL: str = ""
    SUPABASE_ANON_KEY: str = ""
    SUPABASE_PUBLISHABLE_KEY: str = ""
    SUPABASE_SECRET_KEY: str = ""
    # Keep this server-only. Never expose the service-role key to the iOS app.
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_JWKS_URL: str = ""
    # This bucket must be public because image URLs are stored and served directly.
    SUPABASE_STORAGE_BUCKET: str = "images"

    # APNs settings
    # APNS_AUTH_KEY: full contents of the .p8 auth key (PEM). Provided via env var.
    # If the value contains literal "\n" sequences (common when pasting into single-line env editors),
    # they are converted back to real newlines at use time.
    # Keep this optional so missing push-notification configuration does not
    # prevent the rest of the API from starting.
    APNS_AUTH_KEY: str = ""
    APNS_AUTH_KEY_ID: str
    APNS_TEAM_ID: str
    APNS_BUNDLE_ID: str
    APNS_USE_SANDBOX: bool

    # Railway App URL for EventBridge Scheduler
    # Railway automatically provides RAILWAY_PUBLIC_DOMAIN (e.g., "your-app.up.railway.app")
    RAILWAY_PUBLIC_DOMAIN: str = ""
    SCHEDULER_API_KEY: str = ""  # Optional: API key for scheduler endpoint authentication
    
    @property
    def railway_app_url(self) -> str:
        """Construct full Railway app URL from domain"""
        if self.RAILWAY_PUBLIC_DOMAIN:
            return f"https://{self.RAILWAY_PUBLIC_DOMAIN}"
        return ""

    # Environment
    ENVIRONMENT: str = "development"

    class Config:
        env_file = ".env"
        # Deployment environments can contain platform-provided variables that
        # are unrelated to this service. They should not prevent startup.
        extra = "ignore"

settings = Settings()
