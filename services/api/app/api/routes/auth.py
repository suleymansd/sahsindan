from datetime import timedelta
import hashlib
import hmac

import jwt
from fastapi import APIRouter, Cookie, Depends, HTTPException, Response, Query, Request, Body
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.mfa import verify_login_mfa, session_mfa_valid
from app.core.rate_limit import consume_limit, rate_limit
from app.core.response import success
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    hash_password,
    verify_password,
)
from app.db.models import Profile, RefreshToken, User, UserRole, UserStatus
from app.db.session import get_db
from app.core.deps import get_current_user
from app.utils.time import utc_now
from app.services.mail import send_password_reset
from app.schemas.auth import (
    AuthResponse,
    ForgotPasswordRequest,
    LoginRequest,
    RefreshResponse,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    UserSummary,
)

router = APIRouter()


def _include_refresh_token(request: Request) -> bool:
    client = request.headers.get("x-client", "").lower()
    include_param = request.query_params.get("include_refresh", "").lower() in {"1", "true", "yes"}
    return client == "mobile" or include_param


def _set_refresh_cookie(response: Response, refresh_token: str):
    response.set_cookie(
        key="refresh_token",
        value=refresh_token,
        httponly=True,
        secure=settings.app_env == "production",
        samesite="lax",
        max_age=settings.refresh_token_ttl_days * 24 * 3600,
    )


@router.post("/register", dependencies=[Depends(rate_limit(limit=5, window_seconds=3600))])
def register(payload: RegisterRequest, request: Request, response: Response, db: Session = Depends(get_db, scope="function")):
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    existing_phone = db.query(User).filter(User.phone == payload.phone).first()
    if existing_phone:
        raise HTTPException(status_code=400, detail="Phone already registered")

    user = User(
        email=payload.email,
        phone=payload.phone,
        password_hash=hash_password(payload.password),
        role=UserRole.USER_PENDING,
    )
    db.add(user)
    db.flush()

    profile = Profile(
        user_id=user.id,
        name=payload.name,
        city=payload.city,
        profession_category=payload.profession_category,
    )
    db.add(profile)

    access_token = create_access_token(user.id, user.role.value, user.password_hash, user.mfa_secret)
    refresh_token, jti, expires_at = create_refresh_token(user.id, user.mfa_secret)

    db.add(RefreshToken(user_id=user.id, jti=jti, expires_at=expires_at))
    db.commit()

    resp = success(
        AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token if _include_refresh_token(request) else None,
            user=UserSummary(
                id=user.id,
                email=user.email,
                phone=user.phone,
                role=user.role.value,
                status=user.status.value,
                trust_score=user.trust_score,
            ),
        ).model_dump()
    )
    _set_refresh_cookie(resp, refresh_token)
    return resp


@router.post("/login", dependencies=[Depends(rate_limit(limit=5, window_seconds=60))])
def login(payload: LoginRequest, request: Request, response: Response, db: Session = Depends(get_db, scope="function")):
    user = db.query(User).filter(User.email == payload.email).with_for_update().first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if user.role == UserRole.BANNED:
        raise HTTPException(status_code=403, detail="Account banned")
    if user.status == UserStatus.SUSPENDED:
        raise HTTPException(status_code=403, detail="Account suspended")

    if user.mfa_secret:
        consume_limit(f"auth:mfa:{user.id}", 5, 60)
    verify_login_mfa(db, user, payload.otp_code)
    user.last_login_at = utc_now()
    db.add(user)
    db.commit()

    access_token = create_access_token(user.id, user.role.value, user.password_hash, user.mfa_secret)
    refresh_token, jti, expires_at = create_refresh_token(user.id, user.mfa_secret)
    db.add(RefreshToken(user_id=user.id, jti=jti, expires_at=expires_at))
    db.commit()

    resp = success(
        AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token if _include_refresh_token(request) else None,
            user=UserSummary(
                id=user.id,
                email=user.email,
                phone=user.phone,
                role=user.role.value,
                status=user.status.value,
                trust_score=user.trust_score,
            ),
        ).model_dump()
    )
    _set_refresh_cookie(resp, refresh_token)
    return resp


@router.post("/refresh")
def refresh_token(
    request: Request,
    response: Response,
    db: Session = Depends(get_db, scope="function"),
    refresh_token: str | None = Cookie(default=None),
    refresh_token_param: str | None = Query(default=None, alias="refresh_token"),
    body: RefreshRequest | None = Body(default=None),
):
    token = (body.refresh_token if body else None) or refresh_token
    if not token and settings.app_env == "development":
        token = refresh_token_param
    if not token:
        raise HTTPException(status_code=401, detail="Missing refresh token")
    try:
        payload = decode_refresh_token(token)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=401, detail="Invalid refresh token") from exc

    user = db.query(User).filter(User.id == int(payload["sub"])).with_for_update().first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    if user.role == UserRole.BANNED or user.status == UserStatus.SUSPENDED:
        raise HTTPException(status_code=403, detail="Account disabled")

    if not session_mfa_valid(user, payload):
        raise HTTPException(status_code=401, detail="Session expired; MFA login required")

    # Consume in one conditional UPDATE so concurrent requests cannot both rotate.
    consumed = db.query(RefreshToken).filter(
        RefreshToken.jti == payload["jti"], RefreshToken.user_id == user.id,
        RefreshToken.revoked_at.is_(None), RefreshToken.expires_at > utc_now(),
    ).update({"revoked_at": utc_now()}, synchronize_session=False)
    if consumed != 1:
        db.rollback()
        raise HTTPException(status_code=401, detail="Refresh token revoked")

    new_token, new_jti, expires_at = create_refresh_token(user.id, user.mfa_secret)
    db.add(RefreshToken(user_id=user.id, jti=new_jti, expires_at=expires_at))
    db.commit()

    access_token = create_access_token(user.id, user.role.value, user.password_hash, user.mfa_secret)
    resp = success(
        RefreshResponse(
            access_token=access_token,
            refresh_token=new_token if _include_refresh_token(request) else None,
        ).model_dump()
    )
    _set_refresh_cookie(resp, new_token)
    return resp


@router.post("/logout")
def logout(
    response: Response,
    db: Session = Depends(get_db, scope="function"),
    refresh_token: str | None = Cookie(default=None),
    refresh_token_param: str | None = Query(default=None, alias="refresh_token"),
    body: RefreshRequest | None = Body(default=None),
):
    token = (body.refresh_token if body else None) or refresh_token
    if not token and settings.app_env == "development":
        token = refresh_token_param
    resp = success({"message": "logged out"})
    resp.delete_cookie("refresh_token")
    if not token:
        return resp
    try:
        payload = decode_refresh_token(token)
    except Exception:
        return resp

    stored = db.query(RefreshToken).filter(RefreshToken.jti == payload.get("jti")).first()
    if stored:
        stored.revoked_at = utc_now()
        db.add(stored)
        db.commit()

    return resp


@router.post("/forgot-password", dependencies=[Depends(rate_limit(limit=5, window_seconds=60))])
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db, scope="function")):
    if settings.app_env != "development" and not settings.smtp_host:
        raise HTTPException(status_code=503, detail="Password reset delivery not configured")
    if settings.smtp_host:
        consume_limit("smtp:daily", settings.smtp_daily_message_limit, 86400)
        consume_limit("smtp:recipient:" + hashlib.sha256(payload.email.lower().encode()).hexdigest(), 3, 3600)
    user = db.query(User).filter(User.email == payload.email).with_for_update().first()
    if not user:
        return success({"message": "If the account exists, a reset link was sent."})

    token_payload = {
        "sub": str(user.id),
        "purpose": "password_reset",
        "password_version": hashlib.sha256(user.password_hash.encode()).hexdigest(),
        "exp": int((utc_now() + timedelta(minutes=30)).timestamp()),
    }
    token = jwt.encode(token_payload, settings.jwt_secret, algorithm="HS256")

    if settings.app_env == "development" and not settings.smtp_host:
        return success({"reset_token": token})
    try:
        send_password_reset(user.email, token)
    except Exception:
        # Do not disclose whether this address exists through SMTP failure responses.
        import logging
        logging.getLogger(__name__).error("Password reset delivery failed")
    return success({"message": "If the account exists, a reset link was sent."})


@router.post("/reset-password", dependencies=[Depends(rate_limit(limit=10, window_seconds=60))])
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db, scope="function")):
    try:
        decoded = jwt.decode(payload.token, settings.jwt_secret, algorithms=["HS256"],
                             options={"require": ["sub", "exp", "purpose", "password_version"]})
        user_id = int(decoded["sub"])
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=400, detail="Invalid reset token") from exc

    if decoded.get("purpose") != "password_reset":
        raise HTTPException(status_code=400, detail="Invalid reset token")

    user = db.query(User).filter(User.id == user_id).with_for_update().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    expected_version = hashlib.sha256(user.password_hash.encode()).hexdigest()
    if not hmac.compare_digest(str(decoded["password_version"]), expected_version):
        raise HTTPException(status_code=400, detail="Invalid reset token")
    previous_hash = user.password_hash
    changed = db.query(User).filter(User.id == user.id, User.password_hash == previous_hash).update(
        {"password_hash": hash_password(payload.new_password)}, synchronize_session=False)
    if changed != 1:
        db.rollback()
        raise HTTPException(status_code=400, detail="Invalid reset token")
    db.query(RefreshToken).filter(RefreshToken.user_id == user.id, RefreshToken.revoked_at.is_(None)).update(
        {"revoked_at": utc_now()}, synchronize_session=False)
    db.add(user)
    db.commit()

    return success({"message": "Password reset"})


@router.get("/me")
def me(user: User = Depends(get_current_user)):
    return success(
        UserSummary(
            id=user.id,
            email=user.email,
            phone=user.phone,
            role=user.role.value,
            status=user.status.value,
            trust_score=user.trust_score,
        ).model_dump()
    )
