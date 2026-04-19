from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

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


settings = Settings()
