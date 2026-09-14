from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models import SystemSetting


def get_marketplace_settings(db: Session):
    """Persisted admin values take precedence over environment defaults."""
    return db.query(SystemSetting).first() or settings
