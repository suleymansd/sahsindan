from app.core.security import hash_password
from app.db.session import SessionLocal
from app.db.models import Profile, User, UserRole
from app.utils.time import utc_now


def main():
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == "admin@trustmarket.local").first()
        if existing:
            print("Admin already exists")
            return
        user = User(
            email="admin@trustmarket.local",
            phone="5550000001",
            password_hash=hash_password("Admin123!"),
            role=UserRole.ADMIN,
            trust_score=50,
            last_login_at=utc_now(),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        profile = Profile(user_id=user.id, name="Admin", city="ISTANBUL")
        db.add(profile)
        db.commit()
        print("Admin created")
    finally:
        db.close()


if __name__ == "__main__":
    main()
