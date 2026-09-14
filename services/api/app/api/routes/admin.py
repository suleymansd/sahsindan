from datetime import datetime, timedelta

from fastapi import APIRouter, Body, Depends, HTTPException, Query
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.core.deps import require_role
from app.core.response import success
from app.core.config import settings
from app.db.models import (
    AuditLog,
    Listing,
    ListingState,
    Report,
    ReportStatus,
    Profile,
    SystemSetting,
    User,
    UserRole,
    UserStatus,
    VerificationAsset,
    VerificationRequest,
    VerificationStatus,
)
from app.db.session import get_db
from app.schemas.admin import (
    AdminListingAction,
    AdminReportAction,
    AdminReportStatusUpdate,
    AdminSettingsUpdate,
    AdminUserBan,
    AdminUserNote,
    AdminUserRoleUpdate,
)
from app.schemas.verification import AdminVerificationDecision, AdminVerificationMoreInfo
from app.services.audit import log_audit
from app.services.listing_cache import invalidate_listings_cache
from app.services.listing_helpers import serialize_listing
from app.services.trust import recalculate_trust_score, trust_breakdown
from app.utils.storage import signed_url
from app.utils.time import utc_now

router = APIRouter()


def _parse_date(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


def _paginate(query, page: int, page_size: int):
    total = query.count()
    items = query.offset((page - 1) * page_size).limit(page_size).all()
    return items, {"page": page, "page_size": page_size, "total": total}


@router.get("/dashboard")
def dashboard(user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])), db: Session = Depends(get_db, scope="function")):
    now = utc_now()
    pending_verifications = (
        db.query(VerificationRequest).filter(VerificationRequest.status == VerificationStatus.PENDING).count()
    )
    approved_today = (
        db.query(VerificationRequest)
        .filter(
            VerificationRequest.status == VerificationStatus.APPROVED,
            VerificationRequest.updated_at >= now - timedelta(days=1),
        )
        .count()
    )
    published_listings = db.query(Listing).filter(Listing.state == ListingState.PUBLISHED).count()
    reports_last_7d = db.query(Report).filter(Report.created_at >= now - timedelta(days=7)).count()
    top_reports = (
        db.query(Report.listing_id, func.count(Report.id).label("count"))
        .filter(Report.listing_id.isnot(None))
        .group_by(Report.listing_id)
        .order_by(func.count(Report.id).desc())
        .limit(5)
        .all()
    )
    top_reported = []
    if top_reports:
        listing_map = {l.id: l for l in db.query(Listing).filter(Listing.id.in_([r[0] for r in top_reports])).all()}
        for listing_id, count in top_reports:
            listing = listing_map.get(listing_id)
            if listing:
                top_reported.append(
                    {"id": listing.id, "title": listing.title, "state": listing.state.value, "count": count}
                )
    return success(
        {
            "pending_verifications": pending_verifications,
            "approved_today": approved_today,
            "published_listings": published_listings,
            "reports_last_7d": reports_last_7d,
            "top_reported": top_reported,
        }
    )


@router.get("/verification/queue")
def verification_queue(
    status: str | None = Query(default=None),
    city: str | None = Query(default=None),
    profession: str | None = Query(default=None),
    start: str | None = Query(default=None),
    end: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=5, le=100),
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    start_dt = _parse_date(start)
    end_dt = _parse_date(end)
    query = db.query(VerificationRequest, User).join(User, VerificationRequest.user_id == User.id).outerjoin(
        User.profile
    )
    if status:
        try:
            query = query.filter(VerificationRequest.status == VerificationStatus(status))
        except ValueError:
            pass
    else:
        query = query.filter(VerificationRequest.status == VerificationStatus.PENDING)
    if city:
        query = query.filter(User.profile.has(city=city))
    if profession:
        query = query.filter(User.profile.has(profession_category=profession))
    if start_dt:
        query = query.filter(VerificationRequest.created_at >= start_dt)
    if end_dt:
        query = query.filter(VerificationRequest.created_at <= end_dt)

    reqs = query.order_by(VerificationRequest.created_at.desc())
    items, meta = _paginate(reqs, page, page_size)

    data = []
    for req in items:
        request = req[0]
        target = req[1]
        profile = target.profile
        data.append(
            {
                "id": request.id,
                "status": request.status.value,
                "created_at": request.created_at.isoformat() if request.created_at else None,
                "user": {
                    "id": target.id,
                    "email": target.email,
                    "phone": target.phone,
                    "name": profile.name if profile else None,
                    "city": profile.city if profile else None,
                    "profession": profile.profession_category if profile else None,
                },
            }
        )
    return success(data, meta)


@router.get("/verification/{request_id}")
def get_verification(
    request_id: int,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    req = (
        db.query(VerificationRequest)
        .options(joinedload(VerificationRequest.assets))
        .filter(VerificationRequest.id == request_id)
        .first()
    )
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    target = db.query(User).filter(User.id == req.user_id).first()
    profile = target.profile if target else None
    assets = [
        {"id": asset.id, "type": asset.type, "key": asset.s3_key}
        for asset in req.assets
    ]
    audit = (
        db.query(AuditLog)
        .filter(AuditLog.target_id == req.user_id, AuditLog.target_type == "user")
        .order_by(AuditLog.created_at.desc())
        .limit(20)
        .all()
    )
    return success(
        {
            "id": req.id,
            "status": req.status.value,
            "reason": req.reason,
            "reason_code": req.reason_code,
            "created_at": req.created_at.isoformat() if req.created_at else None,
            "updated_at": req.updated_at.isoformat() if req.updated_at else None,
            "user": {
                "id": target.id if target else None,
                "email": target.email if target else None,
                "phone": target.phone if target else None,
                "role": target.role.value if target else None,
                "status": target.status.value if target else None,
                "trust_score": target.trust_score if target else None,
                "name": profile.name if profile else None,
                "city": profile.city if profile else None,
                "profession": profile.profession_category if profile else None,
            },
            "assets": assets,
            "audit": [
                {
                    "id": item.id,
                    "action": item.action,
                    "meta": item.meta,
                    "created_at": item.created_at.isoformat() if item.created_at else None,
                }
                for item in audit
            ],
        }
    )


@router.get("/verification/{request_id}/assets/{asset_id}/signed-url")
def get_verification_asset_url(
    request_id: int,
    asset_id: int,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    asset = (
        db.query(VerificationAsset)
        .filter(VerificationAsset.id == asset_id, VerificationAsset.request_id == request_id)
        .first()
    )
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    return success({"url": signed_url(asset.s3_key)})


@router.post("/verification/{request_id}/approve")
def approve_verification(
    request_id: int,
    payload: AdminVerificationDecision,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    req = db.query(VerificationRequest).filter(VerificationRequest.id == request_id).with_for_update().first()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if req.status != VerificationStatus.PENDING:
        raise HTTPException(status_code=409, detail="Request is already reviewed")
    target = db.query(User).filter(User.id == req.user_id).populate_existing().with_for_update(key_share=True).first()
    if not target or target.role == UserRole.BANNED or target.status == UserStatus.SUSPENDED:
        raise HTTPException(status_code=409, detail="Account cannot be verified")
    if settings.app_env == "production":
        asset_types = {asset.type for asset in req.assets}
        if not ({"id_front", "selfie"} <= asset_types or {"identity", "selfie"} <= asset_types):
            raise HTTPException(status_code=409, detail="Identity and selfie documents are required for review")
    req.status = VerificationStatus.APPROVED
    req.reviewer_id = user.id
    req.reason = payload.reason
    req.reason_code = payload.reason_code
    db.add(req)

    if target:
        if target.role == UserRole.USER_PENDING:
            target.role = UserRole.USER_VERIFIED
        if target.profile and any(asset.type == "profession" for asset in req.assets):
            target.profile.profession_verified = True
        db.add(target)
        db.flush()
        recalculate_trust_score(db, target.id)
    log_audit(db, user.id, "VERIFICATION_APPROVED", "user", req.user_id, {"request_id": req.id})
    db.commit()
    invalidate_listings_cache()
    return success({"status": "approved"})


@router.post("/verification/{request_id}/reject")
def reject_verification(
    request_id: int,
    payload: AdminVerificationDecision,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    if not payload.reason:
        raise HTTPException(status_code=400, detail="Reason required")
    req = db.query(VerificationRequest).filter(VerificationRequest.id == request_id).with_for_update().first()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if req.status != VerificationStatus.PENDING:
        raise HTTPException(status_code=409, detail="Request is already reviewed")
    req.status = VerificationStatus.REJECTED
    req.reviewer_id = user.id
    req.reason = payload.reason
    req.reason_code = payload.reason_code
    db.add(req)
    db.flush()

    log_audit(db, user.id, "VERIFICATION_REJECTED", "user", req.user_id, {"request_id": req.id})
    db.commit()
    return success({"status": "rejected"})


@router.post("/verification/{request_id}/request-more-info")
def request_more_info(
    request_id: int,
    payload: AdminVerificationMoreInfo,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    req = db.query(VerificationRequest).filter(VerificationRequest.id == request_id).with_for_update().first()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if req.status != VerificationStatus.PENDING:
        raise HTTPException(status_code=409, detail="Request is already reviewed")
    req.status = VerificationStatus.PENDING
    req.reason = payload.note
    req.reason_code = "MORE_INFO"
    req.reviewer_id = user.id
    db.add(req)
    db.flush()

    log_audit(db, user.id, "VERIFICATION_MORE_INFO", "user", req.user_id, {"request_id": req.id})
    db.commit()
    return success({"status": "more_info_requested"})


@router.get("/users")
def list_users(
    query: str | None = Query(default=None),
    role: str | None = Query(default=None),
    status: str | None = Query(default=None),
    city: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=5, le=100),
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    base = db.query(User).outerjoin(Profile, Profile.user_id == User.id)
    if query:
        like = f"%{query.lower()}%"
        base = base.filter(
            or_(
                func.lower(User.email).like(like),
                func.lower(User.phone).like(like),
                func.lower(Profile.name).like(like),
            )
        )
    if role:
        try:
            base = base.filter(User.role == UserRole(role))
        except ValueError:
            pass
    if status:
        try:
            base = base.filter(User.status == UserStatus(status))
        except ValueError:
            pass
    if city:
        base = base.filter(Profile.city == city)

    users = base.order_by(User.id.desc())
    items, meta = _paginate(users, page, page_size)
    data = []
    for u in items:
        profile = u.profile
        data.append(
            {
                "id": u.id,
                "email": u.email,
                "phone": u.phone,
                "role": u.role.value,
                "status": u.status.value,
                "trust_score": u.trust_score,
                "last_login_at": u.last_login_at.isoformat() if u.last_login_at else None,
                "name": profile.name if profile else None,
                "city": profile.city if profile else None,
            }
        )
    return success(data, meta)


@router.get("/users/{user_id}")
def get_user(
    user_id: int,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    profile = target.profile
    verifications = (
        db.query(VerificationRequest)
        .filter(VerificationRequest.user_id == user_id)
        .order_by(VerificationRequest.created_at.desc())
        .all()
    )
    listings = db.query(Listing).filter(Listing.owner_id == user_id).order_by(Listing.created_at.desc()).all()
    audit = (
        db.query(AuditLog)
        .filter(AuditLog.target_id == user_id, AuditLog.target_type == "user")
        .order_by(AuditLog.created_at.desc())
        .limit(20)
        .all()
    )
    return success(
        {
            "id": target.id,
            "email": target.email,
            "phone": target.phone,
            "role": target.role.value,
            "status": target.status.value,
            "trust_score": target.trust_score,
            "last_login_at": target.last_login_at.isoformat() if target.last_login_at else None,
            "created_at": target.created_at.isoformat() if target.created_at else None,
            "profile": {
                "name": profile.name if profile else None,
                "city": profile.city if profile else None,
                "profession": profile.profession_category if profile else None,
                "profession_verified": profile.profession_verified if profile else False,
            },
            "verification_requests": [
                {
                    "id": req.id,
                    "status": req.status.value,
                    "reason": req.reason,
                    "reason_code": req.reason_code,
                    "created_at": req.created_at.isoformat() if req.created_at else None,
                }
                for req in verifications
            ],
            "listings": [
                {"id": listing.id, "title": listing.title, "state": listing.state.value}
                for listing in listings
            ],
            "trust": trust_breakdown(db, target.id),
            "audit": [
                {
                    "id": item.id,
                    "action": item.action,
                    "meta": item.meta,
                    "created_at": item.created_at.isoformat() if item.created_at else None,
                }
                for item in audit
            ],
        }
    )


@router.post("/users/{user_id}/ban")
def ban_user(
    user_id: int,
    payload: AdminUserBan,
    user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db, scope="function"),
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    previous_role = target.role.value
    target.role = UserRole.BANNED
    target.status = UserStatus.SUSPENDED
    db.add(target)
    recalculate_trust_score(db, target.id)
    log_audit(
        db,
        user.id,
        "USER_BANNED",
        "user",
        user_id,
        {"reason": payload.reason, "previous_role": previous_role},
    )
    db.commit()
    invalidate_listings_cache()
    return success({"status": "banned"})


@router.post("/users/{user_id}/unban")
def unban_user(
    user_id: int,
    payload: AdminUserRoleUpdate | None = Body(default=None),
    user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db, scope="function"),
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    target.status = UserStatus.ACTIVE
    if payload and payload.role:
        try:
            target.role = UserRole(payload.role)
        except ValueError as exc:  # noqa: BLE001
            raise HTTPException(status_code=400, detail="Invalid role") from exc
    else:
        target.role = UserRole.USER_PENDING
    if target.role == UserRole.BANNED:
        raise HTTPException(status_code=400, detail="Cannot unban with BANNED role")
    db.add(target)
    recalculate_trust_score(db, target.id)
    log_audit(db, user.id, "USER_UNBANNED", "user", user_id, {"role": target.role.value})
    db.commit()
    invalidate_listings_cache()
    return success({"status": "unbanned"})


@router.post("/users/{user_id}/role")
def update_user_role(
    user_id: int,
    payload: AdminUserRoleUpdate,
    user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db, scope="function"),
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    try:
        target.role = UserRole(payload.role)
    except ValueError as exc:  # noqa: BLE001
        raise HTTPException(status_code=400, detail="Invalid role") from exc
    if target.role == UserRole.BANNED:
        target.status = UserStatus.SUSPENDED
    else:
        target.status = UserStatus.ACTIVE
    db.add(target)
    db.flush()
    log_audit(db, user.id, "USER_ROLE_UPDATED", "user", user_id, {"role": target.role.value})
    recalculate_trust_score(db, target.id)
    db.commit()
    invalidate_listings_cache()
    return success({"status": "updated"})


@router.post("/users/{user_id}/internal-note")
def add_user_note(
    user_id: int,
    payload: AdminUserNote,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    log_audit(db, user.id, "USER_NOTE", "user", user_id, {"note": payload.note})
    db.commit()
    return success({"status": "noted"})


@router.get("/listings")
def list_listings(
    state: str | None = Query(default=None),
    city: str | None = Query(default=None),
    flagged: bool | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=5, le=100),
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    base = db.query(Listing).options(joinedload(Listing.owner))
    if state:
        try:
            base = base.filter(Listing.state == ListingState(state))
        except ValueError:
            pass
    if city:
        base = base.filter(Listing.city == city)
    if flagged is not None:
        flagged_ids = (
            db.query(Report.listing_id)
            .filter(Report.status.in_([ReportStatus.OPEN, ReportStatus.IN_REVIEW]))
            .subquery()
        )
        if flagged:
            base = base.filter(Listing.id.in_(flagged_ids))
        else:
            base = base.filter(~Listing.id.in_(flagged_ids))

    listings = base.order_by(Listing.created_at.desc())
    items, meta = _paginate(listings, page, page_size)
    data = []
    for listing in items:
        data.append(
            {
                "id": listing.id,
                "title": listing.title,
                "state": listing.state.value,
                "city": listing.city,
                "price": float(listing.price),
                "owner": {
                    "id": listing.owner.id,
                    "email": listing.owner.email,
                },
                "created_at": listing.created_at.isoformat() if listing.created_at else None,
            }
        )
    return success(data, meta)


@router.get("/listings/{listing_id}")
def get_listing(
    listing_id: int,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    listing = (
        db.query(Listing)
        .options(joinedload(Listing.owner), joinedload(Listing.photos), joinedload(Listing.car_details))
        .filter(Listing.id == listing_id)
        .first()
    )
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    audit = (
        db.query(AuditLog)
        .filter(AuditLog.target_id == listing_id, AuditLog.target_type == "listing")
        .order_by(AuditLog.created_at.desc())
        .limit(20)
        .all()
    )
    return success(
        {
            "listing": serialize_listing(listing, signed_url),
            "audit": [
                {
                    "id": item.id,
                    "action": item.action,
                    "meta": item.meta,
                    "created_at": item.created_at.isoformat() if item.created_at else None,
                }
                for item in audit
            ],
        }
    )


@router.post("/listings/{listing_id}/take-down")
def take_down_listing(
    listing_id: int,
    payload: AdminListingAction,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    if not payload.reason:
        raise HTTPException(status_code=400, detail="Reason required")
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    listing.state = ListingState.REJECTED
    db.add(listing)
    db.flush()

    log_audit(db, user.id, "LISTING_TAKEDOWN", "listing", listing_id, {"reason": payload.reason})
    db.commit()
    invalidate_listings_cache()
    return success({"status": "taken_down"})


@router.post("/listings/{listing_id}/reject")
def reject_listing(
    listing_id: int,
    payload: AdminListingAction,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    if not payload.reason:
        raise HTTPException(status_code=400, detail="Reason required")
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    listing.state = ListingState.REJECTED
    db.add(listing)
    db.flush()
    log_audit(
        db,
        user.id,
        "LISTING_REJECTED",
        "listing",
        listing_id,
        {"reason": payload.reason, "reason_code": payload.reason_code},
    )
    db.commit()
    invalidate_listings_cache()
    return success({"status": "rejected"})


@router.post("/listings/{listing_id}/archive")
def archive_listing(
    listing_id: int,
    payload: AdminListingAction,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    listing.state = ListingState.ARCHIVED
    db.add(listing)
    db.flush()
    log_audit(db, user.id, "LISTING_ARCHIVED", "listing", listing_id, {"reason": payload.reason})
    db.commit()
    invalidate_listings_cache()
    return success({"status": "archived"})


@router.post("/listings/{listing_id}/note")
def add_listing_note(
    listing_id: int,
    payload: AdminListingAction,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    if not payload.reason:
        raise HTTPException(status_code=400, detail="Reason required")
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    log_audit(db, user.id, "LISTING_NOTE", "listing", listing_id, {"note": payload.reason})
    db.commit()
    return success({"status": "noted"})


@router.post("/listings/{listing_id}/restore")
def restore_listing(
    listing_id: int,
    payload: AdminListingAction,
    user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db, scope="function"),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    listing.state = ListingState.PUBLISHED
    db.add(listing)
    db.flush()
    log_audit(db, user.id, "LISTING_RESTORED", "listing", listing_id, {"reason": payload.reason})
    db.commit()
    invalidate_listings_cache()
    return success({"status": "restored"})


@router.get("/reports")
def list_reports(
    status: str | None = Query(default=None),
    report_type: str | None = Query(default=None),
    reason: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=5, le=100),
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    base = db.query(Report, User).join(User, Report.reporter_id == User.id)
    if status:
        try:
            base = base.filter(Report.status == ReportStatus(status))
        except ValueError:
            pass
    if report_type:
        base = base.filter(Report.target_type == report_type)
    if reason:
        base = base.filter(Report.category == reason)
    reports = base.order_by(Report.created_at.desc())
    items, meta = _paginate(reports, page, page_size)
    data = []
    for report, reporter in items:
        data.append(
            {
                "id": report.id,
                "listing_id": report.listing_id,
                "target_type": report.target_type,
                "target_id": report.target_id,
                "reason": report.reason,
                "category": report.category,
                "status": report.status.value,
                "created_at": report.created_at.isoformat() if report.created_at else None,
                "reporter": {"id": reporter.id, "email": reporter.email},
            }
        )
    return success(data, meta)


@router.get("/reports/{report_id}")
def get_report(
    report_id: int,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    reporter = db.query(User).filter(User.id == report.reporter_id).first()
    audit = (
        db.query(AuditLog)
        .filter(AuditLog.target_id == report_id, AuditLog.target_type == "report")
        .order_by(AuditLog.created_at.desc())
        .limit(20)
        .all()
    )
    return success(
        {
            "id": report.id,
            "listing_id": report.listing_id,
            "target_type": report.target_type,
            "target_id": report.target_id,
            "reason": report.reason,
            "category": report.category,
            "status": report.status.value,
            "created_at": report.created_at.isoformat() if report.created_at else None,
            "reporter": {"id": reporter.id, "email": reporter.email} if reporter else None,
            "audit": [
                {
                    "id": item.id,
                    "action": item.action,
                    "meta": item.meta,
                    "created_at": item.created_at.isoformat() if item.created_at else None,
                }
                for item in audit
            ],
        }
    )


@router.post("/reports/{report_id}/set-status")
def set_report_status(
    report_id: int,
    payload: AdminReportStatusUpdate,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    report = db.query(Report).filter(Report.id == report_id).with_for_update().first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    try:
        report.status = ReportStatus(payload.status)
    except ValueError as exc:  # noqa: BLE001
        raise HTTPException(status_code=400, detail="Invalid status") from exc
    if report.status == ReportStatus.RESOLVED:
        report.resolved_by = user.id
        report.resolved_at = utc_now()
    else:
        report.resolved_by = None
        report.resolved_at = None
    db.add(report)
    db.flush()
    if report.listing_id:
        listing = db.query(Listing).filter(Listing.id == report.listing_id).first()
        if listing:
            recalculate_trust_score(db, listing.owner_id)
    log_audit(db, user.id, "REPORT_STATUS_UPDATED", "report", report_id, {"status": report.status.value})
    db.commit()
    invalidate_listings_cache()
    return success({"status": report.status.value})


@router.post("/reports/{report_id}/action")
def report_action(
    report_id: int,
    payload: AdminReportAction,
    user: User = Depends(require_role([UserRole.ADMIN, UserRole.MODERATOR])),
    db: Session = Depends(get_db, scope="function"),
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    meta = {"action": payload.action, "note": payload.note}
    if payload.action == "take_down_listing" and report.listing_id:
        listing = db.query(Listing).filter(Listing.id == report.listing_id).first()
        if listing:
            listing.state = ListingState.REJECTED
            db.add(listing)
            db.flush()
            meta["listing_id"] = listing.id
    log_audit(db, user.id, "REPORT_ACTION", "report", report_id, meta)
    db.commit()
    if "listing_id" in meta:
        invalidate_listings_cache()
    return success({"status": "action_applied"})


@router.get("/settings")
def get_settings(user: User = Depends(require_role([UserRole.ADMIN])), db: Session = Depends(get_db, scope="function")):
    settings = db.query(SystemSetting).first()
    if not settings:
        settings = SystemSetting(city_lock="ISTANBUL")
        db.add(settings)
        db.commit()
    return success(
        {
            "stale_days": settings.stale_days,
            "confirm_window_days": settings.confirm_window_days,
            "photo_max_count": settings.photo_max_count,
            "photo_max_mb": settings.photo_max_mb,
            "listing_fee": float(settings.listing_fee),
            "membership_fee": float(settings.membership_fee),
            "feature_flags": settings.feature_flags or {},
            "city_lock": settings.city_lock,
        }
    )


@router.put("/settings")
def update_settings(
    payload: AdminSettingsUpdate,
    user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db, scope="function"),
):
    settings = db.query(SystemSetting).first()
    if not settings:
        settings = SystemSetting(city_lock="ISTANBUL")
        db.add(settings)
        db.flush()

    updated = {}
    if payload.stale_days is not None:
        settings.stale_days = payload.stale_days
        updated["stale_days"] = payload.stale_days
    if payload.confirm_window_days is not None:
        settings.confirm_window_days = payload.confirm_window_days
        updated["confirm_window_days"] = payload.confirm_window_days
    if payload.photo_max_count is not None:
        settings.photo_max_count = payload.photo_max_count
        updated["photo_max_count"] = payload.photo_max_count
    if payload.photo_max_mb is not None:
        settings.photo_max_mb = payload.photo_max_mb
        updated["photo_max_mb"] = payload.photo_max_mb
    if payload.listing_fee is not None:
        settings.listing_fee = payload.listing_fee
        updated["listing_fee"] = payload.listing_fee
    if payload.membership_fee is not None:
        settings.membership_fee = payload.membership_fee
        updated["membership_fee"] = payload.membership_fee
    if payload.feature_flags is not None:
        settings.feature_flags = payload.feature_flags
        updated["feature_flags"] = payload.feature_flags
    if payload.city_lock is not None:
        settings.city_lock = payload.city_lock
        updated["city_lock"] = payload.city_lock
    if payload.listing_fee is not None or payload.membership_fee is not None:
        fees = dict(settings.fees or {})
        if payload.listing_fee is not None:
            fees["listing_fee"] = payload.listing_fee
        if payload.membership_fee is not None:
            fees["membership_fee"] = payload.membership_fee
        settings.fees = fees
    db.add(settings)
    db.flush()
    log_audit(db, user.id, "SETTINGS_UPDATED", "system", settings.id, {"updated": updated})
    db.commit()
    return success({"status": "updated"})
