from fastapi import HTTPException
from sqlalchemy import update
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models import StorageUsage
from app.services.unique_relations import get_or_create_relation


def reserve_storage(db: Session, size: int):
    get_or_create_relation(db, StorageUsage, {"id": 1}, {"used_bytes": 0})
    reserved = db.execute(update(StorageUsage).where(StorageUsage.id == 1, StorageUsage.used_bytes + size <= settings.storage_budget_bytes).values(used_bytes=StorageUsage.used_bytes + size))
    if reserved.rowcount != 1:
        raise HTTPException(status_code=507, detail="Storage budget exhausted")


def release_storage(db: Session, size: int):
    if size > 0:
        db.execute(update(StorageUsage).where(StorageUsage.id == 1, StorageUsage.used_bytes >= size).values(used_bytes=StorageUsage.used_bytes - size))
