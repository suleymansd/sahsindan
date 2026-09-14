"""Create the first production administrator interactively; refuses existing addresses."""
from getpass import getpass
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.core.security import hash_password
from app.db.session import SessionLocal
from app.db.models import User, Profile, UserRole
from app.schemas.auth import RegisterRequest


def main():
    email = input("Admin email: ").strip()
    phone = input("Admin phone: ").strip()
    name = input("Admin name: ").strip()
    password = getpass("Password (minimum 12 characters): ")
    if len(password) < 12 or password != getpass("Repeat password: "):
        raise SystemExit("Passwords must match and contain at least 12 characters")
    payload = RegisterRequest(email=email, phone=phone, password=password, name=name, city="ISTANBUL")
    with SessionLocal() as db:
        if db.query(User).filter((User.email == payload.email) | (User.phone == payload.phone)).first():
            raise SystemExit("An account already exists; no role was changed")
        user = User(email=payload.email, phone=payload.phone, password_hash=hash_password(password), role=UserRole.ADMIN)
        user.profile = Profile(name=payload.name, city=payload.city)
        db.add(user)
        db.commit()
    print("Administrator created. Sign in through /giris/admin.")


if __name__ == "__main__":
    main()
