from datetime import timedelta

from app.core.config import settings
from app.db.models import Listing, ListingState, StaleState, User, UserRole
from app.services.stale import run_stale_job
from app.utils.time import utc_now


def test_stale_job(db_session):
    db = db_session()

    user = User(
        email="stale@trustmarket.local",
        phone="5554000000",
        password_hash="x",
        role=UserRole.USER_VERIFIED,
        trust_score=50,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    listing = Listing(
        state=ListingState.PUBLISHED,
        title="Old Listing",
        description="Old",
        price=100,
        city="ISTANBUL",
        district="Kadikoy",
        owner_id=user.id,
        last_confirmed_at=utc_now() - timedelta(days=settings.stale_days + 1),
    )
    db.add(listing)
    db.commit()

    run_stale_job(db)
    db.refresh(listing)
    assert listing.stale_state == StaleState.NEEDS_CONFIRMATION

    listing.last_confirmed_at = utc_now() - timedelta(days=settings.stale_days + settings.confirm_window_days + 1)
    db.add(listing)
    db.commit()

    run_stale_job(db)
    db.refresh(listing)
    assert listing.state == ListingState.ARCHIVED
    db.close()
