from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import require_verified
from app.core.response import success
from app.db.models import Favorite, Listing, ListingState, User
from app.db.session import get_db
from app.services.listing_helpers import serialize_listing
from app.utils.storage import presigned_url

router = APIRouter()


@router.get("")
def list_favorites(user: User = Depends(require_verified), db: Session = Depends(get_db, scope="function"), limit: int = Query(50, ge=1, le=100), offset: int = Query(0, ge=0, le=50000)):
    favorites = (
        db.query(Listing)
        .join(Favorite, Favorite.listing_id == Listing.id)
        .filter(Favorite.user_id == user.id)
        .filter(or_(Listing.state == ListingState.PUBLISHED, Listing.owner_id == user.id))
        .order_by(Favorite.id.desc()).offset(offset).limit(limit + 1)
        .all()
    )
    return success([serialize_listing(listing, presigned_url) for listing in favorites[:limit]], meta={"has_more": len(favorites) > limit})


@router.get("/ids")
def favorite_ids(user: User = Depends(require_verified), db: Session = Depends(get_db, scope="function")):
    rows = db.query(Favorite.listing_id).filter(Favorite.user_id == user.id).order_by(Favorite.id.desc()).limit(settings.max_favorites_per_user).all()
    return success([row[0] for row in rows])
