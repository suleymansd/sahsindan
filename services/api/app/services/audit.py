from sqlalchemy.orm import Session

from app.db.models import AuditLog


def log_audit(db: Session, actor_id: int, action: str, target_type: str, target_id: int | None, meta: dict | None = None):
    """Write within the caller's transaction so the action and its audit stay atomic."""
    log = AuditLog(
        actor_id=actor_id,
        action=action,
        target_type=target_type,
        target_id=target_id,
        meta=meta,
    )
    db.add(log)
    db.flush()
