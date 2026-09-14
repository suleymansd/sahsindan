from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, model_validator

BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    database_url: str = "postgresql+psycopg://trustmarket:trustmarket@localhost:5432/trustmarket"
    redis_url: str = "redis://localhost:6379/0"
    sqlalchemy_pool_size: int = 5
    sqlalchemy_max_overflow: int = 10
    sqlalchemy_pool_timeout: int = 30
    sqlalchemy_pool_recycle: int = 1800
    sqlite_busy_timeout_seconds: int = 30
    listings_cache_enabled: bool = True
    listings_cache_ttl_seconds: int = 15

    mfa_encryption_key: str = ""
    verification_retention_days: int = Field(default=30, ge=1, le=365)
    jwt_secret: str = "change-me"
    jwt_refresh_secret: str = "change-me-refresh"
    access_token_ttl_minutes: int = 30
    refresh_token_ttl_days: int = 14

    minio_endpoint: str = "http://localhost:9000"
    minio_access_key: str = "minioadmin"
    minio_secret_key: str = "minioadmin"
    minio_bucket: str = "trustmarket"
    minio_secure: bool = False
    disable_storage: bool = False
    disable_stale_job: bool = False
    fallback_image_url: str = "http://localhost:3000/placeholder.png"
    public_api_url: str = "http://localhost:8080"
    cors_origins: str = (
        "http://localhost:3000,http://127.0.0.1:3000,"
        "http://localhost:3001,http://127.0.0.1:3001,"
        "http://localhost:3002,http://127.0.0.1:3002,"
        "http://localhost:3003,http://127.0.0.1:3003,"
        "http://localhost:3005,http://127.0.0.1:3005"
    )

    app_env: str = "development"
    stale_days: int = 30
    confirm_window_days: int = 7
    city_lock: str = "ISTANBUL"
    photo_max_count: int = 20
    photo_max_mb: int = 8
    # No paid AI, SMS, KYC or autoscaling integration is enabled by this app.
    api_daily_request_limit: int = Field(default=100000, ge=1)
    api_daily_response_bytes: int = Field(default=1024 * 1024 * 1024, ge=1024)
    api_ip_requests_per_minute: int = Field(default=1200, ge=1)
    api_user_requests_per_minute: int = Field(default=180, ge=1)
    storage_budget_bytes: int = Field(default=5 * 1024 * 1024 * 1024, ge=1024)
    max_request_bytes: int = Field(default=10 * 1024 * 1024, ge=1024)
    upload_user_daily_bytes: int = Field(default=50 * 1024 * 1024, ge=1024)
    upload_global_daily_bytes: int = Field(default=500 * 1024 * 1024, ge=1024)
    max_active_listings_per_user: int = Field(default=20, ge=1, le=1000)
    max_favorites_per_user: int = Field(default=500, ge=1, le=5000)
    max_verification_assets: int = Field(default=6, ge=1, le=20)
    websocket_connections_per_user: int = Field(default=3, ge=1, le=20)
    websocket_auth_check_seconds: int = Field(default=30, ge=1, le=300)
    verification_mode: str = "manual"
    smtp_daily_message_limit: int = Field(default=100, ge=1)
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_sender: str = ""
    smtp_starttls: bool = True
    public_web_url: str = "http://localhost:3000"

    @model_validator(mode="after")
    def validate_production_security(self):
        if self.mfa_encryption_key:
            from cryptography.fernet import Fernet
            Fernet(self.mfa_encryption_key.encode())
        if self.app_env == "production":
            if self.smtp_host and (not self.smtp_sender or not self.smtp_starttls):
                raise ValueError("Production SMTP requires a sender and STARTTLS")
            if not self.mfa_encryption_key:
                raise ValueError("Production requires MFA_ENCRYPTION_KEY")
            if min(len(self.jwt_secret), len(self.jwt_refresh_secret)) < 32 or self.jwt_secret == self.jwt_refresh_secret:
                raise ValueError("Production requires distinct JWT secrets of at least 32 characters")
            if "*" in [origin.strip() for origin in self.cors_origins.split(",")]:
                raise ValueError("Production CORS requires explicit trusted origins")
            if self.redis_url.startswith("memory://") or self.database_url.startswith("sqlite"):
                raise ValueError("Production requires shared Redis and PostgreSQL")
            if not self.public_api_url.startswith("https://") or not self.public_web_url.startswith("https://"):
                raise ValueError("Production public URLs require HTTPS")
        if self.verification_mode not in {"manual", "disabled"}:
            raise ValueError("Unsupported verification mode")
        return self


settings = Settings()
