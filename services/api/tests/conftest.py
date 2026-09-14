import os
import pytest

os.environ.setdefault("XDG_CACHE_HOME", os.path.join(os.getcwd(), ".run", "cache"))
os.environ.setdefault("MPLCONFIGDIR", os.path.join(os.getcwd(), ".run", "mpl"))

# Tests must never connect to (or flush) a developer's configured services.
os.environ.update(
    DATABASE_URL="sqlite+pysqlite:///:memory:",
    REDIS_URL="memory://",
    MFA_ENCRYPTION_KEY="MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDA=",
    JWT_SECRET="test-access-secret-32-characters-minimum",
    JWT_REFRESH_SECRET="test-refresh-secret-32-characters-minimum",
    DISABLE_STALE_JOB="1",
    DISABLE_STORAGE="0",
    APP_ENV="development",
)
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.schema import CreateSchema, DropSchema
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.redis import redis_client
from app.db.base import Base
from app.db.session import get_db
from app.main import app


def pytest_addoption(parser):
    parser.addoption("--postgres-url", help="Explicit PostgreSQL test URL; each test uses a disposable schema")


def pytest_configure(config):
    config.addinivalue_line("markers", "postgres: requires real PostgreSQL concurrency")


def pytest_collection_modifyitems(config, items):
    if not config.getoption("--postgres-url"):
        for item in items:
            if "postgres" in item.keywords:
                item.add_marker(pytest.mark.skip(reason="Use scripts/test_postgres.py for real concurrency"))


@pytest.fixture()
def db_session(request):
    postgres_url = request.config.getoption("--postgres-url")
    schema = None
    if postgres_url:
        from uuid import uuid4
        schema = f"test_{uuid4().hex}"
        admin_engine = create_engine(postgres_url)
        with admin_engine.begin() as connection:
            connection.execute(CreateSchema(schema))
        engine = create_engine(postgres_url, connect_args={"options": f"-csearch_path={schema} -cstatement_timeout=15000"})
    else:
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
    try:
        yield TestingSessionLocal
    finally:
        app.dependency_overrides.clear()
        engine.dispose()
        if schema:
            with admin_engine.begin() as connection:
                connection.execute(DropSchema(schema, cascade=True))
            admin_engine.dispose()


@pytest.fixture(autouse=True)
def reset_in_memory_redis():
    if hasattr(redis_client, "flushall"):
        redis_client.flushall()
    yield
    if hasattr(redis_client, "flushall"):
        redis_client.flushall()


@pytest.fixture()
def client(db_session):
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="session")
def password_hash():
    from app.core.security import hash_password
    return hash_password("Pass1234!")


@pytest.fixture()
def make_user(db_session, password_hash):
    from app.core.security import create_access_token
    from app.db.models import Profile, User, UserRole

    def create(role=UserRole.USER_VERIFIED, **kwargs):
        with db_session() as db:
            index = db.query(User).count() + 1
            user = User(email=f"audit{index}@example.com", phone=f"555{index:07}",
                        password_hash=password_hash, role=role, **kwargs)
            user.profile = Profile(name=f"Audit {index}", city="ISTANBUL")
            db.add(user)
            db.commit()
            return user.id, {"Authorization": f"Bearer {create_access_token(user.id, role.value, user.password_hash, user.mfa_secret)}"}
    return create


@pytest.fixture()
def make_listing(db_session):
    from app.db.models import CarDetail, Listing, ListingState

    def create(owner_id, state=ListingState.PUBLISHED, **kwargs):
        with db_session() as db:
            listing = Listing(owner_id=owner_id, state=state, title="Audit car",
                              description="Test car", price=100, city="ISTANBUL", district="Kadikoy", **kwargs)
            listing.car_details = CarDetail(brand="Audi", model="A4", year=2020,
                                           mileage=100, transmission="Automatic", fuel="Gasoline", color="White")
            db.add(listing)
            db.commit()
            return listing.id
    return create
