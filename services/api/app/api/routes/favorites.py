from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import require_verified
from app.core.response import success
from app.db.models import Favorite, Listing, User
from app.db.session import get_db
from app.services.listing_helpers import serialize_listing
from app.utils.storage import presigned_url

router = APIRouter()


@router.get("")
def list_favorites(user: User = Depends(require_verified), db: Session = Depends(get_db)):
    favorites = (
        db.query(Listing)
        .join(Favorite, Favorite.listing_id == Listing.id)
        .filter(Favorite.user_id == user.id)
        .all()
    )
    return success([serialize_listing(listing, presigned_url) for listing in favorites])
