from datetime import datetime, timedelta, timezone
import hashlib
import uuid

import jwt
from passlib.context import CryptContext

from app.core.config import settings
from app.core.mfa import mfa_version

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(user_id: int, role: str, password_hash: str | None = None, mfa_secret: str | None = None) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "role": role,
        "purpose": "access",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=settings.access_token_ttl_minutes)).timestamp()),
    }
    if mfa_secret:
        payload["mv"] = mfa_version(mfa_secret)
    if password_hash is not None:
        payload["pv"] = hashlib.sha256(password_hash.encode()).hexdigest()
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def create_refresh_token(user_id: int, mfa_secret: str | None = None) -> tuple[str, str, datetime]:
    now = datetime.now(timezone.utc)
    jti = hashlib.sha256(f"{user_id}:{uuid.uuid4()}".encode()).hexdigest()
    payload = {
        "sub": str(user_id),
        "jti": jti,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(days=settings.refresh_token_ttl_days)).timestamp()),
    }
    if mfa_secret:
        payload["mv"] = mfa_version(mfa_secret)
    token = jwt.encode(payload, settings.jwt_refresh_secret, algorithm="HS256")
    return token, jti, now + timedelta(days=settings.refresh_token_ttl_days)


def decode_access_token(token: str) -> dict:
    payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"],
                         options={"require": ["sub", "exp", "role"]})
    # Keep existing access tokens valid, but never accept reset/download tokens.
    if payload.get("purpose", "access") != "access":
        raise jwt.InvalidTokenError("Invalid token purpose")
    if not isinstance(payload["sub"], str) or not payload["sub"].isdigit():
        raise jwt.InvalidTokenError("Invalid subject")
    return payload


def decode_refresh_token(token: str) -> dict:
    payload = jwt.decode(token, settings.jwt_refresh_secret, algorithms=["HS256"],
                         options={"require": ["sub", "exp", "jti"]})
    if not isinstance(payload["sub"], str) or not payload["sub"].isdigit():
        raise jwt.InvalidTokenError("Invalid subject")
    return payload
