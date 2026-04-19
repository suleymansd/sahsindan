from datetime import timedelta

from app.db.models import User
from app.utils.time import ensure_aware, utc_now


def response_time_bucket(minutes: int | None) -> str | None:
    if minutes is None:
        return None
    if minutes <= 60:
        return "Genelde 1 saat içinde yanıtlar"
    if minutes <= 180:
        return "Genelde 3 saat içinde yanıtlar"
    if minutes <= 720:
        return "Genelde 12 saat içinde yanıtlar"
    return "Genelde 24 saat içinde yanıtlar"


def last_active_bucket(user: User) -> str:
    if not user.last_login_at:
        return "Bu ay aktifti"
    now = utc_now()
    last_login_at = ensure_aware(user.last_login_at)
    if last_login_at >= now - timedelta(days=1):
        return "Bugün aktifti"
    if last_login_at >= now - timedelta(days=7):
        return "Bu hafta aktifti"
    return "Bu ay aktifti"


def serialize_listing(listing, presigned_url_fn) -> dict:
    owner = listing.owner
    owner_name = owner.profile.name if owner.profile else "Doğrulanmış Kullanıcı"
    return {
        "id": listing.id,
        "state": listing.state.value,
        "stale_state": listing.stale_state.value if listing.stale_state else None,
        "title": listing.title,
        "description": listing.description,
        "price": float(listing.price),
        "city": listing.city,
        "district": listing.district,
        "last_confirmed_at": listing.last_confirmed_at.isoformat() if listing.last_confirmed_at else None,
        "owner": {
            "id": owner.id,
            "name": owner_name,
            "trust_score": owner.trust_score,
            "response_time_bucket": response_time_bucket(owner.response_time_minutes_avg),
            "last_active_bucket": last_active_bucket(owner),
        },
        "car_details": {
            "brand": listing.car_details.brand,
            "model": listing.car_details.model,
            "year": listing.car_details.year,
            "mileage": listing.car_details.mileage,
            "transmission": listing.car_details.transmission,
            "fuel": listing.car_details.fuel,
            "color": listing.car_details.color,
            "vin_optional": listing.car_details.vin_optional,
            "changed_parts": listing.car_details.changed_parts or [],
        },
        "photos": [
            {
                "id": photo.id,
                "url": presigned_url_fn(photo.s3_key),
                "sort_order": photo.sort_order,
            }
            for photo in listing.photos
        ],
    }
