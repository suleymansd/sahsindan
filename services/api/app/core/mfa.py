"""Offline TOTP (RFC 6238); encrypted secrets and single-use time steps."""
import base64
import hashlib
import hmac
import secrets
import struct
import time

from cryptography.fernet import Fernet, InvalidToken
from fastapi import HTTPException
from sqlalchemy import update

from app.core.config import settings
from app.db.models import User, UserRole


def new_secret():
    return base64.b32encode(secrets.token_bytes(20)).decode()


def encrypt_secret(secret):
    if not settings.mfa_encryption_key:
        raise ValueError("Configure MFA_ENCRYPTION_KEY before enrolling accounts")
    return Fernet(settings.mfa_encryption_key.encode()).encrypt(secret.encode()).decode()


def totp(secret, counter, digits=6):
    digest = hmac.new(base64.b32decode(secret), struct.pack(">Q", counter), hashlib.sha1).digest()
    offset = digest[-1] & 15
    value = struct.unpack(">I", digest[offset:offset + 4])[0] & 0x7fffffff
    return str(value % (10 ** digits)).zfill(digits)


def matching_counter(secret, code, now=None):
    if not isinstance(code, str) or len(code) != 6 or not code.isascii() or not code.isdigit():
        return None
    counter = int(time.time() if now is None else now) // 30
    for candidate in (counter, counter - 1, counter + 1):
        if candidate >= 0 and hmac.compare_digest(totp(secret, candidate), code):
            return candidate
    return None


def mfa_version(encrypted_secret):
    return hashlib.sha256(encrypted_secret.encode()).hexdigest() if encrypted_secret else None


def session_mfa_valid(user, payload):
    if user.mfa_secret:
        return hmac.compare_digest(str(payload.get("mv", "")), mfa_version(user.mfa_secret))
    return not (settings.app_env == "production" and user.role in (UserRole.ADMIN, UserRole.MODERATOR))


def verify_login_mfa(db, user, code):
    if not user.mfa_secret:
        if not session_mfa_valid(user, {}):
            raise HTTPException(status_code=403, detail="MFA enrollment required")
        return
    try:
        secret = Fernet(settings.mfa_encryption_key.encode()).decrypt(user.mfa_secret.encode()).decode()
    except (ValueError, InvalidToken):
        raise HTTPException(status_code=503, detail="MFA temporarily unavailable") from None
    counter = matching_counter(secret, code)
    if counter is None:
        raise HTTPException(status_code=401, detail="Invalid or missing verification code")
    changed = db.execute(update(User).where(
        User.id == user.id, User.mfa_secret == user.mfa_secret, User.mfa_last_counter < counter,
    ).values(mfa_last_counter=counter).execution_options(synchronize_session=False))
    if changed.rowcount != 1:
        raise HTTPException(status_code=401, detail="Verification code already used")
