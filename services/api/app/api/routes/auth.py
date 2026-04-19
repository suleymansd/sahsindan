from datetime import timedelta

import jwt
from fastapi import APIRouter, Cookie, Depends, HTTPException, Response, Query, Request
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.rate_limit import rate_limit
from app.core.response import success
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
)
from app.db.models import Profile, RefreshToken, User, UserRole
from app.db.session import get_db
from app.core.deps import get_current_user
from app.utils.time import utc_now
from app.schemas.auth import (
    AuthResponse,
    ForgotPasswordRequest,
    LoginRequest,
    RefreshResponse,
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
        samesite="lax",
        max_age=settings.refresh_token_ttl_days * 24 * 3600,
    )


@router.post("/register")
def register(payload: RegisterRequest, request: Request, response: Response, db: Session = Depends(get_db)):
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
    db.commit()
    db.refresh(user)

    profile = Profile(
        user_id=user.id,
        name=payload.name,
        city=payload.city,
        profession_category=payload.profession_category,
    )
    db.add(profile)
    db.commit()

    access_token = create_access_token(user.id, user.role.value)
    refresh_token, jti, expires_at = create_refresh_token(user.id)

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
def login(payload: LoginRequest, request: Request, response: Response, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if user.role == UserRole.BANNED:
        raise HTTPException(status_code=403, detail="Account banned")

    user.last_login_at = utc_now()
    db.add(user)
    db.commit()

    access_token = create_access_token(user.id, user.role.value)
    refresh_token, jti, expires_at = create_refresh_token(user.id)
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
    db: Session = Depends(get_db),
    refresh_token: str | None = Cookie(default=None),
    refresh_token_param: str | None = Query(default=None, alias="refresh_token"),
):
    token = refresh_token or refresh_token_param
    if not token:
        raise HTTPException(status_code=401, detail="Missing refresh token")
    try:
        payload = jwt.decode(token, settings.jwt_refresh_secret, algorithms=["HS256"])
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=401, detail="Invalid refresh token") from exc

    stored = db.query(RefreshToken).filter(RefreshToken.jti == payload["jti"]).first()
    if not stored or stored.revoked_at is not None:
        raise HTTPException(status_code=401, detail="Refresh token revoked")

    stored.revoked_at = utc_now()
    db.add(stored)

    user = db.query(User).filter(User.id == int(payload["sub"])).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    new_token, new_jti, expires_at = create_refresh_token(user.id)
    db.add(RefreshToken(user_id=user.id, jti=new_jti, expires_at=expires_at))
    db.commit()

    access_token = create_access_token(user.id, user.role.value)
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
    db: Session = Depends(get_db),
    refresh_token: str | None = Cookie(default=None),
    refresh_token_param: str | None = Query(default=None, alias="refresh_token"),
):
    token = refresh_token or refresh_token_param
    if not token:
        return success({"message": "logged out"})
    try:
        payload = jwt.decode(token, settings.jwt_refresh_secret, algorithms=["HS256"])
    except Exception:
        return success({"message": "logged out"})

    stored = db.query(RefreshToken).filter(RefreshToken.jti == payload.get("jti")).first()
    if stored:
        stored.revoked_at = utc_now()
        db.add(stored)
        db.commit()

    resp = success({"message": "logged out"})
    resp.delete_cookie("refresh_token")
    return resp


@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        return success({"message": "If the account exists, a reset link was sent."})

    token_payload = {
        "sub": str(user.id),
        "purpose": "password_reset",
        "exp": int((utc_now() + timedelta(minutes=30)).timestamp()),
    }
    token = jwt.encode(token_payload, settings.jwt_secret, algorithm="HS256")

    return success({"reset_token": token})


@router.post("/reset-password")
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    try:
        decoded = jwt.decode(payload.token, settings.jwt_secret, algorithms=["HS256"])
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=400, detail="Invalid reset token") from exc

    if decoded.get("purpose") != "password_reset":
        raise HTTPException(status_code=400, detail="Invalid reset token")

    user = db.query(User).filter(User.id == int(decoded["sub"])).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.password_hash = hash_password(payload.new_password)
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
