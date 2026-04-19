from sqlalchemy import create_engine, event
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import NullPool

from app.core.config import settings

db_url = settings.database_url
db_backend = make_url(db_url).get_backend_name()
is_sqlite = db_backend == "sqlite"
is_sqlite_memory = db_backend == "sqlite" and ":memory:" in db_url

engine_kwargs = {
    "pool_pre_ping": True,
}
if is_sqlite:
    # SQLite concurrency works better with per-request connections than QueuePool.
    engine_kwargs["poolclass"] = NullPool
elif not is_sqlite_memory:
    engine_kwargs.update(
        {
            "pool_size": settings.sqlalchemy_pool_size,
            "max_overflow": settings.sqlalchemy_max_overflow,
            "pool_timeout": settings.sqlalchemy_pool_timeout,
            "pool_recycle": settings.sqlalchemy_pool_recycle,
        }
    )

connect_args = {}
if is_sqlite:
    # SQLite needs this for concurrent requests under threaded workers.
    connect_args = {
        "check_same_thread": False,
        "timeout": settings.sqlite_busy_timeout_seconds,
    }

engine = create_engine(db_url, connect_args=connect_args, **engine_kwargs)

if is_sqlite:
    @event.listens_for(engine, "connect")
    def _configure_sqlite(dbapi_connection, connection_record):  # noqa: ARG001
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL;")
        cursor.execute(f"PRAGMA busy_timeout={settings.sqlite_busy_timeout_seconds * 1000};")
        cursor.close()

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
