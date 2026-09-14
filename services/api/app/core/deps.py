from typing import Callable
import hashlib
import hmac

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.core.mfa import session_mfa_valid
from app.core.config import settings
from app.core.rate_limit import consume_limit
from app.db.session import get_db
from app.db.models import User, UserRole, UserStatus


def get_current_user(
    db: Session = Depends(get_db, scope="function"),
    authorization: str | None = Header(default=None),
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    token = authorization.split(" ", 1)[1]
    try:
        payload = decode_access_token(token)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc
    user = db.query(User).filter(User.id == int(payload["sub"])).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    if not session_mfa_valid(user, payload):
        raise HTTPException(status_code=401, detail="Session expired; MFA login required")
    version = payload.get("pv")
    if (settings.app_env == "production" and not version) or (version and not hmac.compare_digest(str(version), hashlib.sha256(user.password_hash.encode()).hexdigest())):
        raise HTTPException(status_code=401, detail="Session expired")
    if user.role == UserRole.BANNED:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account banned")
    if user.status == UserStatus.SUSPENDED:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account suspended")
    if settings.app_env == "production":
        consume_limit(f"user:requests:{user.id}", settings.api_user_requests_per_minute, 60)
    # Release authentication's connection before the endpoint needs a worker thread.
    # Only loaded scalar identity fields cross this boundary; routes query db anew.
    db.expunge(user)
    db.rollback()
    return user


def require_role(roles: list[UserRole]) -> Callable:
    def _require(user: User = Depends(get_current_user)):
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        if user.role == UserRole.BANNED:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account banned")
        return user

    return _require


def require_verified(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.USER_VERIFIED and user.role not in [UserRole.ADMIN, UserRole.MODERATOR]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Verification required")
    if user.role == UserRole.BANNED:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account banned")
    return user
