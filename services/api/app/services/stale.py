from datetime import timedelta

from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models import Listing, ListingState, StaleState
from app.services.listing_cache import invalidate_listings_cache
from app.utils.time import utc_now


def run_stale_job(db: Session) -> int:
    now = utc_now()
    stale_cutoff = now - timedelta(days=settings.stale_days)
    archive_cutoff = now - timedelta(days=settings.stale_days + settings.confirm_window_days)

    needs_confirmation = (
        db.query(Listing)
        .filter(
            Listing.state == ListingState.PUBLISHED,
            Listing.last_confirmed_at < stale_cutoff,
        )
        .all()
    )
    for listing in needs_confirmation:
        listing.stale_state = StaleState.NEEDS_CONFIRMATION
        db.add(listing)

    to_archive = (
        db.query(Listing)
        .filter(
            Listing.state == ListingState.PUBLISHED,
            Listing.stale_state == StaleState.NEEDS_CONFIRMATION,
            Listing.last_confirmed_at < archive_cutoff,
        )
        .all()
    )
    for listing in to_archive:
        listing.state = ListingState.ARCHIVED
        listing.stale_state = None
        db.add(listing)

    db.commit()
    changed = len(needs_confirmation) + len(to_archive)
    if changed:
        invalidate_listings_cache()
    return changed
