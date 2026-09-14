from datetime import timedelta

from sqlalchemy.orm import Session

from app.db.models import Listing, ListingState, StaleState
from app.services.listing_cache import invalidate_listings_cache
from app.services.marketplace_settings import get_marketplace_settings
from app.utils.time import utc_now


def run_stale_job(db: Session) -> int:
    settings = get_marketplace_settings(db)
    now = utc_now()
    stale_cutoff = now - timedelta(days=settings.stale_days)
    archive_cutoff = now - timedelta(days=settings.stale_days + settings.confirm_window_days)

    # Conditional set-based updates avoid loading every stale listing and are idempotent.
    archived = db.query(Listing).filter(Listing.state == ListingState.PUBLISHED, Listing.last_confirmed_at < archive_cutoff).update({"state": ListingState.ARCHIVED, "stale_state": None}, synchronize_session=False)
    marked = db.query(Listing).filter(Listing.state == ListingState.PUBLISHED, Listing.stale_state.is_(None), Listing.last_confirmed_at < stale_cutoff).update({"stale_state": StaleState.NEEDS_CONFIRMATION}, synchronize_session=False)
    db.commit()
    changed = archived + marked
    if changed:
        invalidate_listings_cache()
    return changed
