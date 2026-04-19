import os

from sqlalchemy import select, func

from app.core.config import settings
from app.db.models import (
    Appointment,
    AppointmentEvent,
    AppointmentStatus,
    CarDetail,
    Listing,
    ListingPhoto,
    ListingState,
    Message,
    Profile,
    RefreshToken,
    SystemSetting,
    Thread,
    User,
    UserRole,
    UserStatus,
    VerificationRequest,
    VerificationStatus,
)
from app.db.session import SessionLocal
from app.utils.time import utc_now


def _ensure_system_settings(db):
    existing = db.execute(select(func.count(SystemSetting.id))).scalar_one()
    if existing:
        return
    db.add(
        SystemSetting(
            stale_days=30,
            confirm_window_days=7,
            fees={"listing_fee": 0},
            membership_fee=0,
            listing_fee=0,
            photo_max_count=20,
            photo_max_mb=8,
            feature_flags=None,
            city_lock="ISTANBUL",
        )
    )


def _ensure_user(db, *, email: str, phone: str, password_hash: str, role: UserRole, name: str, verified_profession: bool):
    user = db.execute(select(User).where(User.email == email)).scalar_one_or_none()
    if user:
        return user
    user = User(
        email=email,
        phone=phone,
        password_hash=password_hash,
        role=role,
        status=UserStatus.ACTIVE,
        trust_score=70 if role == UserRole.ADMIN else (60 if role == UserRole.MODERATOR else (50 if role == UserRole.USER_VERIFIED else 0)),
        response_time_minutes_avg=30,
        last_login_at=utc_now(),
        created_at=utc_now(),
    )
    db.add(user)
    db.flush()

    profile = Profile(
        user_id=user.id,
        name=name,
        city="ISTANBUL",
        profession_category=None,
        profession_verified=verified_profession,
    )
    db.add(profile)
    return user


def _seed_listings(db, *, seller: User):
    existing = db.execute(select(func.count(Listing.id))).scalar_one()
    if existing:
        return

    brands = [
        ("Alfa Romeo", "Giulia"),
        ("Audi", "A4"),
        ("BMW", "3 Series"),
        ("Chevrolet", "Cruze"),
        ("Fiat", "Egea"),
        ("Ford", "Focus"),
        ("Honda", "Civic"),
        ("Hyundai", "i20"),
        ("Mercedes", "C200"),
        ("Nissan", "Sentra"),
        ("Opel", "Corsa"),
        ("Peugeot", "308"),
        ("Renault", "Megane"),
        ("Seat", "Leon"),
        ("Skoda", "Octavia"),
        ("Toyota", "Corolla"),
        ("Volkswagen", "Golf"),
        ("Volvo", "S60"),
    ]
    districts = ["Kadikoy", "Besiktas", "Sisli", "Beyoglu", "Uskudar", "Maltepe", "Bakirkoy", "Atasehir"]

    now = utc_now()
    for i in range(1, 31):
        brand, model = brands[(i - 1) % len(brands)]
        year = 2015 + (i % 9)
        state = ListingState.PUBLISHED
        if i % 10 == 0:
            state = ListingState.SOLD
        elif i % 15 == 0:
            state = ListingState.ARCHIVED

        listing = Listing(
            state=state,
            stale_state=None,
            title=f"{brand} {model} {year}",
            description="Özenle kullanılmış, düzenli bakımlı. Ekspertizli.",
            price=300000 + (i * 15000) + ((i % 5) * 50000),
            city="ISTANBUL",
            district=districts[(i - 1) % len(districts)],
            owner_id=seller.id,
            last_confirmed_at=now,
            created_at=now,
            updated_at=now,
        )
        db.add(listing)
        db.flush()

        db.add(
            CarDetail(
                listing_id=listing.id,
                brand=brand,
                model=model,
                year=year,
                mileage=20000 + (i * 2000),
                transmission="Automatic" if i % 2 == 0 else "Manual",
                fuel=["Gasoline", "Diesel", "Hybrid", "Electric"][i % 4],
                color=["Black", "White", "Silver", "Blue", "Red", "Grey", "Green"][i % 7],
                vin_optional=f"VIN{str(listing.id).zfill(10)}",
            )
        )

        # Seed photos exist under services/api/storage/seed/listings/<n>/photo.png
        db.add(
            ListingPhoto(
                listing_id=listing.id,
                s3_key=f"seed/listings/{i}/photo.png",
                sort_order=0,
                created_at=now,
            )
        )


def _seed_messaging_and_appointments(db, *, buyer: User, seller: User):
    listing = db.execute(select(Listing).order_by(Listing.id.asc())).scalars().first()
    if not listing:
        return

    thread = db.execute(
        select(Thread).where(Thread.listing_id == listing.id, Thread.buyer_id == buyer.id)
    ).scalar_one_or_none()
    if not thread:
        thread = Thread(
            listing_id=listing.id,
            buyer_id=buyer.id,
            seller_id=seller.id,
            created_at=utc_now(),
            updated_at=utc_now(),
            last_message_at=utc_now(),
        )
        db.add(thread)
        db.flush()

    msg_count = db.execute(select(func.count(Message.id))).scalar_one()
    if msg_count < 2:
        db.add(
            Message(
                thread_id=thread.id,
                sender_id=buyer.id,
                body="Merhaba, arac hala satilik mi?",
                created_at=utc_now(),
                read_at=None,
            )
        )
        db.add(
            Message(
                thread_id=thread.id,
                sender_id=seller.id,
                body="Evet, bugun gorebilirsiniz.",
                created_at=utc_now(),
                read_at=None,
            )
        )

    appt = db.execute(select(Appointment).limit(1)).scalar_one_or_none()
    if not appt:
        appt = Appointment(
            listing_id=listing.id,
            buyer_id=buyer.id,
            seller_id=seller.id,
            status=AppointmentStatus.ACCEPTED,
            scheduled_at=utc_now(),
            location="Kadikoy Sahil",
            notes="Test drive planlandi.",
            created_at=utc_now(),
            updated_at=utc_now(),
        )
        db.add(appt)
        db.flush()
        db.add(
            AppointmentEvent(
                appointment_id=appt.id,
                actor_id=seller.id,
                event_type="ACCEPTED",
                note=None,
                created_at=utc_now(),
            )
        )


def _seed_verification(db, *, pending: User):
    existing = db.execute(select(VerificationRequest).where(VerificationRequest.user_id == pending.id)).scalar_one_or_none()
    if existing:
        return
    db.add(
        VerificationRequest(
            user_id=pending.id,
            status=VerificationStatus.PENDING,
            reviewer_id=None,
            reason=None,
            reason_code=None,
            created_at=utc_now(),
            updated_at=utc_now(),
        )
    )


def _seed_verified_verification(db, *, verified: User):
    existing = db.execute(select(VerificationRequest).where(VerificationRequest.user_id == verified.id)).scalar_one_or_none()
    if existing:
        return
    db.add(
        VerificationRequest(
            user_id=verified.id,
            status=VerificationStatus.APPROVED,
            reviewer_id=None,
            reason=None,
            reason_code=None,
            created_at=utc_now(),
            updated_at=utc_now(),
        )
    )


def main():
    # Ensure settings are loaded and DB URL is present.
    if not settings.database_url:
        raise SystemExit("DATABASE_URL is missing")

    # Reset refresh tokens to avoid stale tokens in dev.
    db = SessionLocal()
    try:
        _ensure_system_settings(db)

        admin = _ensure_user(
            db,
            email="admin@trustmarket.local",
            phone="5550000001",
            password_hash="$2y$12$t0iRZYhpfo5O/miJ3SgGS.nc3HEkFU5l/N3ElB8bdGO1mpRKdvxz6",
            role=UserRole.ADMIN,
            name="Admin",
            verified_profession=True,
        )
        _ensure_user(
            db,
            email="mod@trustmarket.local",
            phone="5550000002",
            password_hash="$2y$12$Wr2uK6cfO1uMb7/cDgNmX.j.2Y.FzMYMyCNUGFQiRJh71fOoyLY7G",
            role=UserRole.MODERATOR,
            name="Moderator",
            verified_profession=True,
        )
        buyer = _ensure_user(
            db,
            email="user1@trustmarket.local",
            phone="5550000003",
            password_hash="$2y$12$RGhVHFJ7zT4HHSPltXJDHO/BBg0RtflN5s0jX7vz9E/L64bFxziA6",
            role=UserRole.USER_VERIFIED,
            name="Aylin",
            verified_profession=True,
        )
        seller = _ensure_user(
            db,
            email="seller1@trustmarket.local",
            phone="5550000004",
            password_hash="$2y$12$RGhVHFJ7zT4HHSPltXJDHO/BBg0RtflN5s0jX7vz9E/L64bFxziA6",
            role=UserRole.USER_VERIFIED,
            name="Mert",
            verified_profession=True,
        )
        pending = _ensure_user(
            db,
            email="pending@trustmarket.local",
            phone="5550000005",
            password_hash="$2y$12$RGhVHFJ7zT4HHSPltXJDHO/BBg0RtflN5s0jX7vz9E/L64bFxziA6",
            role=UserRole.USER_PENDING,
            name="Kemal",
            verified_profession=False,
        )
        verified_demo = _ensure_user(
            db,
            email="verified@test.com",
            phone="5550000099",
            password_hash="$2b$12$E2c956QmaMOHw9LGUkbAgOZMWpW1sHGmYwkqrV.nIf22llQ2XFrEC",
            role=UserRole.USER_VERIFIED,
            name="Verified Demo",
            verified_profession=True,
        )

        # SQLite-only seed: create sample data if empty.
        _seed_listings(db, seller=seller)
        _seed_messaging_and_appointments(db, buyer=buyer, seller=seller)
        _seed_verification(db, pending=pending)
        _seed_verified_verification(db, verified=verified_demo)

        # Clear refresh tokens for deterministic dev auth.
        db.query(RefreshToken).delete()

        db.commit()
        print("Seeded sqlite successfully.")
        print("Demo accounts:")
        print("- admin@trustmarket.local / Admin123!")
        print("- mod@trustmarket.local / Mod123!")
        print("- user1@trustmarket.local / User123!")
        print("- seller1@trustmarket.local / User123!")
        print("- pending@trustmarket.local / User123!")
    finally:
        db.close()


if __name__ == "__main__":
    main()
