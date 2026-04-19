from sqlalchemy.orm import Session

from app.db.models import AuditLog


def log_audit(db: Session, actor_id: int, action: str, target_type: str, target_id: int | None, meta: dict | None = None):
    log = AuditLog(
        actor_id=actor_id,
        action=action,
        target_type=target_type,
        target_id=target_id,
        meta=meta,
    )
    db.add(log)
    db.commit()
