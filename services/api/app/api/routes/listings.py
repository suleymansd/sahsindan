from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload, selectinload

from app.core.config import settings
from app.core.deps import get_current_user, require_verified
from app.core.rate_limit import rate_limit
from app.core.response import success
from app.db.models import (
    CarDetail,
    Favorite,
    Listing,
    ListingPhoto,
    ListingState,
    StaleState,
    User,
)
from app.db.session import get_db
from app.schemas.listing import ListingCreate, ListingOut, ListingPhotoReorder, ListingUpdate
from app.services.listing_cache import (
    get_cached_public_listings,
    invalidate_listings_cache,
    set_cached_public_listings,
)
from app.services.listing_helpers import serialize_listing
from app.utils.time import utc_now
from app.utils.storage import scan_file_placeholder, upload_bytes, presigned_url

router = APIRouter()

ALLOWED_TYPES = {"image/jpeg", "image/png"}
MAX_UPLOAD_SIZE = 8 * 1024 * 1024


def _serialize_listing(listing: Listing) -> dict:
    return ListingOut(**serialize_listing(listing, presigned_url)).model_dump(mode="json")


@router.get("")
def list_listings(
    q: Optional[str] = None,
    city: Optional[str] = None,
    district: Optional[str] = None,
    brand: Optional[str] = None,
    model: Optional[str] = None,
    transmission: Optional[str] = None,
    fuel: Optional[str] = None,
    color: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    year_min: Optional[int] = None,
    year_max: Optional[int] = None,
    mileage_min: Optional[int] = None,
    mileage_max: Optional[int] = None,
    sort: Optional[str] = "newest",
    include_inactive: bool = False,
    mine: bool = False,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Browse is allowed for any authenticated user (including USER_PENDING).
    # Verified is required only for "mine" and "include_inactive" views.
    if mine or include_inactive:
        require_verified(user)

    use_public_cache = settings.listings_cache_enabled and not mine and not include_inactive
    cache_filters = {
        "q": q,
        "city": city,
        "district": district,
        "brand": brand,
        "model": model,
        "transmission": transmission,
        "fuel": fuel,
        "color": color,
        "min_price": min_price,
        "max_price": max_price,
        "year_min": year_min,
        "year_max": year_max,
        "mileage_min": mileage_min,
        "mileage_max": mileage_max,
        "sort": sort,
    }
    if use_public_cache:
        cached = get_cached_public_listings(cache_filters)
        if cached is not None:
            return success(cached)

    query = (
        db.query(Listing)
        .options(
            joinedload(Listing.owner).joinedload(User.profile),
            joinedload(Listing.car_details),
            selectinload(Listing.photos),
        )
        .join(CarDetail)
        .filter(Listing.owner_id.isnot(None))
    )

    if mine:
        query = query.filter(Listing.owner_id == user.id)
    elif not include_inactive:
        query = query.filter(Listing.state == ListingState.PUBLISHED)

    if q:
        normalized = q.strip()
        if normalized.isdigit():
            query = query.filter(Listing.id == int(normalized))
        else:
            like = f"%{normalized}%"
            query = query.filter(
                or_(
                    Listing.title.ilike(like),
                    Listing.description.ilike(like),
                    Listing.city.ilike(like),
                    Listing.district.ilike(like),
                    CarDetail.brand.ilike(like),
                    CarDetail.model.ilike(like),
                )
            )

    if city:
        query = query.filter(Listing.city == city)
    if district:
        query = query.filter(Listing.district == district)
    if brand:
        query = query.filter(CarDetail.brand == brand)
    if model:
        query = query.filter(CarDetail.model == model)
    if transmission:
        query = query.filter(CarDetail.transmission == transmission)
    if fuel:
        query = query.filter(CarDetail.fuel == fuel)
    if color:
        query = query.filter(CarDetail.color == color)
    if min_price is not None:
        query = query.filter(Listing.price >= min_price)
    if max_price is not None:
        query = query.filter(Listing.price <= max_price)
    if year_min is not None:
        query = query.filter(CarDetail.year >= year_min)
    if year_max is not None:
        query = query.filter(CarDetail.year <= year_max)
    if mileage_min is not None:
        query = query.filter(CarDetail.mileage >= mileage_min)
    if mileage_max is not None:
        query = query.filter(CarDetail.mileage <= mileage_max)

    if sort == "price_asc":
        query = query.order_by(Listing.price.asc())
    elif sort == "price_desc":
        query = query.order_by(Listing.price.desc())
    elif sort == "mileage_asc":
        query = query.order_by(CarDetail.mileage.asc())
    elif sort == "mileage_desc":
        query = query.order_by(CarDetail.mileage.desc())
    elif sort == "year_asc":
        query = query.order_by(CarDetail.year.asc())
    elif sort == "year_desc":
        query = query.order_by(CarDetail.year.desc())
    else:
        query = query.order_by(Listing.created_at.desc())

    listings = query.all()
    payload = [_serialize_listing(l) for l in listings]
    if use_public_cache:
        set_cached_public_listings(cache_filters, payload)
    return success(payload)


@router.get("/{listing_id}")
def get_listing(listing_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    listing = (
        db.query(Listing)
        .options(
            joinedload(Listing.owner).joinedload(User.profile),
            joinedload(Listing.car_details),
            selectinload(Listing.photos),
        )
        .filter(Listing.id == listing_id)
        .first()
    )
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.state != ListingState.PUBLISHED and listing.owner_id != user.id:
        # Avoid leaking draft/inactive listings.
        raise HTTPException(status_code=404, detail="Listing not found")
    return success(_serialize_listing(listing))


@router.post("")
def create_listing(payload: ListingCreate, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    if payload.city != settings.city_lock:
        raise HTTPException(status_code=400, detail=f"Only {settings.city_lock} is supported right now")
    listing = Listing(
        title=payload.title,
        description=payload.description,
        price=payload.price,
        city=payload.city,
        district=payload.district,
        owner_id=user.id,
    )
    db.add(listing)
    db.commit()
    db.refresh(listing)

    car = CarDetail(listing_id=listing.id, **payload.car_details.model_dump())
    db.add(car)
    db.commit()

    db.refresh(listing)
    invalidate_listings_cache()
    return success(_serialize_listing(listing), status_code=201)


@router.put("/{listing_id}")
def update_listing(
    listing_id: int,
    payload: ListingUpdate,
    user: User = Depends(require_verified),
    db: Session = Depends(get_db),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing or listing.owner_id != user.id:
        raise HTTPException(status_code=404, detail="Listing not found")

    data = payload.model_dump(exclude_unset=True)
    for key, value in data.items():
        setattr(listing, key, value)
    db.add(listing)
    db.commit()
    db.refresh(listing)
    invalidate_listings_cache()
    return success(_serialize_listing(listing))


@router.post("/{listing_id}/publish")
def publish_listing(listing_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing or listing.owner_id != user.id:
        raise HTTPException(status_code=404, detail="Listing not found")
    listing.state = ListingState.PUBLISHED
    listing.last_confirmed_at = utc_now()
    listing.stale_state = None
    db.add(listing)
    db.commit()
    invalidate_listings_cache()
    return success({"status": "published"})


@router.post("/{listing_id}/mark-sold")
def mark_sold(listing_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing or listing.owner_id != user.id:
        raise HTTPException(status_code=404, detail="Listing not found")
    listing.state = ListingState.SOLD
    listing.stale_state = None
    db.add(listing)
    db.commit()
    invalidate_listings_cache()
    return success({"status": "sold"})


@router.post("/{listing_id}/confirm-active")
def confirm_active(listing_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing or listing.owner_id != user.id:
        raise HTTPException(status_code=404, detail="Listing not found")
    listing.last_confirmed_at = utc_now()
    listing.stale_state = None
    if listing.state == ListingState.ARCHIVED:
        listing.state = ListingState.PUBLISHED
    db.add(listing)
    db.commit()
    invalidate_listings_cache()
    return success({"status": "confirmed"})


@router.post("/{listing_id}/photos", dependencies=[Depends(rate_limit(limit=10, window_seconds=60))])
async def upload_photo(
    listing_id: int,
    file: UploadFile,
    user: User = Depends(require_verified),
    db: Session = Depends(get_db),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing or listing.owner_id != user.id:
        raise HTTPException(status_code=404, detail="Listing not found")

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Invalid file type")

    content = await file.read()
    if len(content) > MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=400, detail="File too large")

    scan_file_placeholder(content)

    key = f"listings/{listing_id}/{file.filename}"
    stored_key = upload_bytes(key, content, file.content_type)
    if not stored_key:
        raise HTTPException(status_code=503, detail="Storage unavailable")

    max_order = (
        db.query(func.max(ListingPhoto.sort_order))
        .filter(ListingPhoto.listing_id == listing_id)
        .scalar()
    )
    next_order = (max_order or 0) + 1
    photo = ListingPhoto(listing_id=listing_id, s3_key=stored_key, sort_order=next_order)
    db.add(photo)
    db.commit()
    db.refresh(photo)
    invalidate_listings_cache()
    return success({"photo_id": photo.id, "url": presigned_url(photo.s3_key)})


@router.post("/{listing_id}/photos/reorder")
def reorder_photos(
    listing_id: int,
    payload: ListingPhotoReorder,
    user: User = Depends(require_verified),
    db: Session = Depends(get_db),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing or listing.owner_id != user.id:
        raise HTTPException(status_code=404, detail="Listing not found")

    photos = (
        db.query(ListingPhoto)
        .filter(ListingPhoto.listing_id == listing_id, ListingPhoto.id.in_(payload.photo_ids))
        .all()
    )
    if len(photos) != len(payload.photo_ids):
        raise HTTPException(status_code=400, detail="Invalid photo list")

    photo_map = {photo.id: photo for photo in photos}
    for index, photo_id in enumerate(payload.photo_ids):
        photo_map[photo_id].sort_order = index
        db.add(photo_map[photo_id])

    db.commit()
    invalidate_listings_cache()
    return success({"reordered": True})


@router.delete("/{listing_id}/photos/{photo_id}")
def delete_photo(
    listing_id: int,
    photo_id: int,
    user: User = Depends(require_verified),
    db: Session = Depends(get_db),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing or listing.owner_id != user.id:
        raise HTTPException(status_code=404, detail="Listing not found")

    photo = (
        db.query(ListingPhoto)
        .filter(ListingPhoto.id == photo_id, ListingPhoto.listing_id == listing_id)
        .first()
    )
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")

    db.delete(photo)
    db.commit()
    invalidate_listings_cache()
    return success({"deleted": True})


@router.post("/{listing_id}/favorite")
def favorite_listing(listing_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    existing = (
        db.query(Favorite)
        .filter(Favorite.user_id == user.id, Favorite.listing_id == listing_id)
        .first()
    )
    if existing:
        return success({"favorited": True})

    fav = Favorite(user_id=user.id, listing_id=listing_id)
    db.add(fav)
    db.commit()
    return success({"favorited": True})


@router.delete("/{listing_id}/favorite")
def unfavorite_listing(listing_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    existing = (
        db.query(Favorite)
        .filter(Favorite.user_id == user.id, Favorite.listing_id == listing_id)
        .first()
    )
    if existing:
        db.delete(existing)
        db.commit()
    return success({"favorited": False})
