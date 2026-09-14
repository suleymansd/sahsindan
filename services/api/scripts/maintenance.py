"""Run one maintenance process, independently of HTTP worker count."""
import logging
from pathlib import Path
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.db.session import SessionLocal
from app.db.models import RefreshToken, ListingPhoto, VerificationAsset, StorageUsage
from app.services.stale import run_stale_job
from app.services.retention import purge_reviewed_assets
from app.services.unique_relations import get_or_create_relation
from app.utils.storage import _local_storage_dir
from app.utils.time import utc_now


def reconcile_storage(db):
    usage, _ = get_or_create_relation(db, StorageUsage, {"id": 1}, {"used_bytes": 0})
    usage = db.query(StorageUsage).filter_by(id=1).with_for_update().one()
    referenced = {key for (key,) in db.query(ListingPhoto.s3_key).all()} | {key for (key,) in db.query(VerificationAsset.s3_key).all()}
    total = 0
    for namespace in ("listings", "verification"):
        root = _local_storage_dir / namespace
        for path in root.rglob("*"):
            if not path.is_file() or path.is_symlink():
                continue
            stat = path.stat()
            if str(path.relative_to(_local_storage_dir)) not in referenced and time.time() - stat.st_mtime > 86400:
                path.unlink()
            else:
                total += stat.st_size
    usage.used_bytes = total
    db.commit()


def main():
    iteration = 0
    while True:
        with SessionLocal() as db:
            try:
                run_stale_job(db)
                db.query(RefreshToken).filter(RefreshToken.expires_at < utc_now()).delete(synchronize_session=False)
                db.commit()
                if iteration % 60 == 0:
                    purge_reviewed_assets(db)
                    reconcile_storage(db)
                _local_storage_dir.mkdir(parents=True, exist_ok=True)
                (_local_storage_dir / ".maintenance-heartbeat").touch()
            except Exception:
                db.rollback()
                logging.exception("Maintenance failed; retrying next interval")
        iteration += 1
        time.sleep(60)


if __name__ == "__main__":
    if "--reconcile-once" in sys.argv:
        with SessionLocal() as db:
            reconcile_storage(db)
    else:
        main()
