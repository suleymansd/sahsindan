"""Delete reviewed identity files after the configured retention period."""
from datetime import timedelta
import logging

from app.core.config import settings
from app.db.models import VerificationAsset, VerificationRequest, VerificationStatus
from app.services.storage_budget import release_storage
from app.utils.storage import delete_bytes
from app.utils.time import utc_now


def purge_reviewed_assets(db, batch_size=100):
    cutoff = utc_now() - timedelta(days=settings.verification_retention_days)
    # Lock requests like the reviewer/upload routes; retain pending evidence.
    requests = db.query(VerificationRequest).filter(
        VerificationRequest.status != VerificationStatus.PENDING,
        VerificationRequest.updated_at < cutoff,
        VerificationRequest.assets.any(),
    ).order_by(VerificationRequest.id).limit(batch_size).with_for_update().all()
    deleted = 0
    for request in requests:
        for asset in db.query(VerificationAsset).filter_by(request_id=request.id).all():
            try:
                delete_bytes(asset.s3_key)
            except Exception:
                logging.getLogger(__name__).warning("Retention storage deletion failed; will retry")
                continue
            release_storage(db, asset.size_bytes)
            db.delete(asset)
            deleted += 1
    db.commit()
    return deleted
