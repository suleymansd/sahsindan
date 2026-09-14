import jwt
from fastapi import APIRouter, Depends, HTTPException, UploadFile, Response
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.core.config import settings
from app.core.response import success
from app.services.storage_budget import reserve_storage, release_storage
from app.core.resource_limits import consume_upload_budget
from app.utils.file_validation import validate_upload
from app.core.rate_limit import rate_limit
from app.db.models import VerificationRequest, VerificationStatus, VerificationAsset, User
from app.db.session import get_db
from app.schemas.verification import VerificationStatusOut, VerificationSubmit
from app.utils.storage import upload_bytes, upload_key, read_private_bytes, delete_bytes

router = APIRouter()

ALLOWED_TYPES = {"image/jpeg", "image/png"}
MAX_UPLOAD_SIZE = 5 * 1024 * 1024


@router.get("/assets/download")
def download_asset(token: str, db: Session = Depends(get_db, scope="function")):
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"],
                             options={"require": ["purpose", "key", "exp"]})
        if payload["purpose"] != "verification_download" or not isinstance(payload["key"], str):
            raise jwt.InvalidTokenError("Invalid download token")
    except jwt.InvalidTokenError as exc:
        raise HTTPException(status_code=401, detail="Invalid download token") from exc
    asset = db.query(VerificationAsset).filter(VerificationAsset.s3_key == payload["key"]).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    try:
        content = read_private_bytes(asset.s3_key)
    except (FileNotFoundError, ValueError) as exc:
        raise HTTPException(status_code=404, detail="Asset not found") from exc
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Storage unavailable") from exc
    if asset.s3_key.lower().endswith(".pdf") or content.startswith(b"%PDF-"):
        raise HTTPException(status_code=415, detail="Legacy PDF quarantined; request a JPEG or PNG replacement")
    return Response(content, media_type="application/octet-stream", headers={
        "Content-Disposition": 'attachment; filename="verification-document"',
        "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff",
    })


@router.get("/status")
def status(user: User = Depends(get_current_user), db: Session = Depends(get_db, scope="function")):
    req = (
        db.query(VerificationRequest)
        .filter(VerificationRequest.user_id == user.id)
        .order_by(VerificationRequest.created_at.desc())
        .first()
    )
    if not req:
        return success(VerificationStatusOut(status="NOT_SUBMITTED", reason=None).model_dump())
    return success(VerificationStatusOut(status=req.status.value, reason=req.reason, reason_code=req.reason_code).model_dump())


@router.post("/submit", dependencies=[Depends(rate_limit(5, 3600))])
def submit(payload: VerificationSubmit, user: User = Depends(get_current_user), db: Session = Depends(get_db, scope="function")):
    if settings.verification_mode == "disabled":
        raise HTTPException(status_code=503, detail="Verification is temporarily unavailable")
    if not payload.background_consent:
        raise HTTPException(status_code=400, detail="Consent required")
    # Manual review never treats a user-supplied OTP or selfie flag as proof.
    db.query(User).filter(User.id == user.id).with_for_update().first()
    existing = db.query(VerificationRequest).filter(VerificationRequest.user_id == user.id, VerificationRequest.status == VerificationStatus.PENDING).first()
    if existing:
        return success({"request_id": existing.id, "status": existing.status.value})
    req = VerificationRequest(user_id=user.id, status=VerificationStatus.PENDING)
    db.add(req)
    db.commit()
    db.refresh(req)

    return success({"request_id": req.id, "status": req.status.value})


@router.post("/assets/upload")
def upload_asset(
    request_id: int,
    type: str,
    file: UploadFile,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db, scope="function"),
):
    req = db.query(VerificationRequest).filter(VerificationRequest.id == request_id).with_for_update().first()
    if not req or req.user_id != user.id:
        raise HTTPException(status_code=404, detail="Request not found")
    if req.status != VerificationStatus.PENDING:
        raise HTTPException(status_code=409, detail="Request is already reviewed")
    if type not in {"selfie", "identity", "id_front", "id_back", "profession", "background"}:
        raise HTTPException(status_code=400, detail="Invalid asset type")

    existing = db.query(VerificationAsset).filter(VerificationAsset.request_id == request_id, VerificationAsset.type == type).first()
    if not existing and db.query(VerificationAsset).filter(VerificationAsset.request_id == request_id).count() >= settings.max_verification_assets:
        raise HTTPException(status_code=409, detail="Verification asset limit reached")

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Invalid file type")

    content = file.file.read(MAX_UPLOAD_SIZE + 1)
    if len(content) > MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=400, detail="File too large")

    consume_upload_budget(user.id, len(content))
    content = validate_upload(content, file.content_type)

    reserve_storage(db, len(content))
    key = upload_key(f"verification/{user.id}/{request_id}/{type}", file.content_type)
    if not upload_bytes(key, content, file.content_type):
        raise HTTPException(status_code=503, detail="Storage unavailable")

    old_key, old_size = (existing.s3_key, existing.size_bytes) if existing else (None, 0)
    asset = existing or VerificationAsset(request_id=request_id, type=type, private_bool=True)
    asset.s3_key, asset.size_bytes = key, len(content)
    db.add(asset)
    db.commit()
    if old_key:
        try:
            delete_bytes(old_key)
            release_storage(db, old_size)
            db.commit()
        except Exception:
            db.rollback()

    return success({"asset_id": asset.id, "key": key})
