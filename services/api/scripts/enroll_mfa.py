"""Enroll an administrator locally; never send the secret to a remote QR service."""
import getpass
from pathlib import Path
import sys
from urllib.parse import quote, urlencode

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.core.mfa import encrypt_secret, matching_counter, new_secret, verify_login_mfa
from app.core.security import verify_password
from app.db.models import RefreshToken, User, UserRole
from app.db.session import SessionLocal
from app.utils.time import utc_now


def main():
    email = input("Administrator/moderator email: ").strip().lower()
    password = getpass.getpass("Account password: ")
    with SessionLocal() as db:
        user = db.query(User).filter_by(email=email).first()
        if not user or user.role not in (UserRole.ADMIN, UserRole.MODERATOR) or not verify_password(password, user.password_hash):
            raise SystemExit("Account or password invalid")
        previous_secret, previous_password = user.mfa_secret, user.password_hash
        if previous_secret:
            verify_login_mfa(db, user, getpass.getpass("Current authenticator code: "))
            db.commit()
        secret = new_secret()
        encrypted = encrypt_secret(secret)
        print("Add this key manually in your authenticator. Keep this terminal private:")
        print(secret)
        print("otpauth://totp/" + quote("TrustMarket:" + email, safe="") + "?" + urlencode({
            "secret": secret, "issuer": "TrustMarket", "algorithm": "SHA1", "digits": 6, "period": 30,
        }))
        counter = matching_counter(secret, getpass.getpass("Code from the NEW authenticator: "))
        if counter is None:
            raise SystemExit("Code invalid; enrollment not changed")
        changed = db.query(User).filter(
            User.id == user.id, User.password_hash == previous_password, User.mfa_secret == previous_secret,
        ).update({"mfa_secret": encrypted, "mfa_last_counter": counter}, synchronize_session=False)
        if changed != 1:
            raise SystemExit("Account changed during enrollment; retry")
        db.query(RefreshToken).filter_by(user_id=user.id).update({"revoked_at": utc_now()}, synchronize_session=False)
        db.commit()
        print("MFA enabled; previous sessions revoked. Wait for the next code before signing in.")


if __name__ == "__main__":
    main()
