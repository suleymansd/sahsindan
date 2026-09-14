import os
from pathlib import Path
import subprocess
import sys

import pytest
from sqlalchemy import create_engine, inspect

from app.db.base import Base


@pytest.mark.parametrize("filename", ["migration.sqlite3", "migration 100%.sqlite3"])
def test_sqlite_upgrade_matches_model_columns(tmp_path, filename):
    url = f"sqlite+pysqlite:///{tmp_path}/{filename}"
    env = {**os.environ, "DATABASE_URL": url}
    subprocess.run([sys.executable, "-m", "alembic", "upgrade", "head"],
                   cwd=Path(__file__).resolve().parents[1], env=env, check=True, capture_output=True)
    engine = create_engine(url)
    try:
        schema = inspect(engine)
        for name, table in Base.metadata.tables.items():
            assert {column.name for column in table.columns} == {column["name"] for column in schema.get_columns(name)}
        assert any(item["name"] == "ck_listing_price_positive" for item in schema.get_check_constraints("listings"))
    finally:
        engine.dispose()
