import os
import pytest

os.environ.setdefault("XDG_CACHE_HOME", os.path.join(os.getcwd(), ".run", "cache"))
os.environ.setdefault("MPLCONFIGDIR", os.path.join(os.getcwd(), ".run", "mpl"))

os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")
os.environ.setdefault("REDIS_URL", "memory://")
os.environ.setdefault("JWT_SECRET", "test-secret")
os.environ.setdefault("JWT_REFRESH_SECRET", "test-refresh-secret")
os.environ.setdefault("DISABLE_STALE_JOB", "1")
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.redis import redis_client
from app.db.base import Base
from app.db.session import get_db
from app.main import app


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    Base.metadata.create_all(bind=engine)

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    yield TestingSessionLocal
    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def reset_in_memory_redis():
    if hasattr(redis_client, "flushall"):
        redis_client.flushall()
    yield
    if hasattr(redis_client, "flushall"):
        redis_client.flushall()
