"""Disposable API for browser tests; never reads/writes the development database."""
import os
import base64
from pathlib import Path
import sys
from tempfile import TemporaryDirectory


def main():
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    with TemporaryDirectory(prefix="trustmarket-e2e-") as directory:
        os.environ.update(
            DATABASE_URL=f"sqlite+pysqlite:///{directory}/e2e.sqlite3",
            REDIS_URL="memory://", APP_ENV="development",
            MFA_ENCRYPTION_KEY=base64.urlsafe_b64encode(b"e" * 32).decode(),
            JWT_SECRET="e2e-access-secret-32-characters-minimum", JWT_REFRESH_SECRET="e2e-refresh-secret-32-characters-minimum",
            DISABLE_STALE_JOB="1", DISABLE_STORAGE="0",
            CORS_ORIGINS="http://127.0.0.1:3080", PUBLIC_API_URL="http://127.0.0.1:8091",
        )
        from app.core.security import hash_password
        from app.core.mfa import encrypt_secret
        from app.db.base import Base
        from app.db.models import CarDetail, Listing, ListingState, Message, Profile, Thread, User, UserRole
        from app.db.session import engine, SessionLocal
        from app.utils import storage
        storage._storage_available = False
        storage._local_storage_dir = Path(directory) / "uploads"
        from app.main import app, mount_public_storage
        mount_public_storage(app, storage._local_storage_dir)
        import uvicorn

        @app.middleware("http")
        async def isolate_browser_test_client(request, call_next):
            # This middleware exists only in the disposable E2E runner. Each browser
            # scenario models a separate client, while rate limits within it stay intact.
            test_id = request.headers.get("x-e2e-test-id")
            if test_id:
                request.scope["client"] = (f"e2e-{test_id}", 0)
            return await call_next(request)

        Base.metadata.create_all(engine)
        password = hash_password("E2ePass123!")
        with SessionLocal() as db:
            for index, role in enumerate([UserRole.USER_VERIFIED, UserRole.USER_VERIFIED, UserRole.ADMIN, UserRole.ADMIN]):
                user = User(email=f"e2e{index}@example.com", phone=f"555900000{index}",
                            password_hash=password, role=role, trust_score=50)
                if index == 3:
                    user.mfa_secret = encrypt_secret(base64.b32encode(b"12345678901234567890").decode())
                user.profile = Profile(name=f"E2E User {index}", city="ISTANBUL")
                db.add(user)
            db.flush()
            listing = Listing(owner_id=2, state=ListingState.PUBLISHED, title="Audit E2E Car",
                              description="Browser test car", price=100000, city="ISTANBUL", district="Kadikoy")
            listing.car_details = CarDetail(brand="Audi", model="A4", year=2020, mileage=100,
                                           transmission="Automatic", fuel="Gasoline", color="White")
            db.add(listing)
            db.flush()
            thread = Thread(listing_id=listing.id, buyer_id=1, seller_id=2)
            db.add(thread)
            db.flush()
            db.add_all([Message(thread_id=thread.id, sender_id=2, body=f"Historical message {index}") for index in range(135)])
            db.commit()
        uvicorn.run(app, host="127.0.0.1", port=8091, log_level="warning")


if __name__ == "__main__":
    main()
