from fastapi import APIRouter, Depends, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.core.response import success
from app.db.models import VerificationRequest, VerificationStatus, VerificationAsset, User
from app.db.session import get_db
from app.schemas.verification import VerificationStatusOut, VerificationSubmit
from app.utils.storage import scan_file_placeholder, upload_bytes

router = APIRouter()

ALLOWED_TYPES = {"image/jpeg", "image/png", "application/pdf"}
MAX_UPLOAD_SIZE = 5 * 1024 * 1024


@router.get("/status")
def status(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    req = (
        db.query(VerificationRequest)
        .filter(VerificationRequest.user_id == user.id)
        .order_by(VerificationRequest.created_at.desc())
        .first()
    )
    if not req:
        return success(VerificationStatusOut(status="NOT_SUBMITTED", reason=None).model_dump())
    return success(VerificationStatusOut(status=req.status.value, reason=req.reason).model_dump())


@router.post("/submit")
def submit(payload: VerificationSubmit, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if payload.phone_otp != "123456":
        raise HTTPException(status_code=400, detail="Invalid OTP")
    if not payload.background_consent:
        raise HTTPException(status_code=400, detail="Consent required")

    req = VerificationRequest(user_id=user.id, status=VerificationStatus.PENDING)
    db.add(req)
    db.commit()
    db.refresh(req)

    if payload.profession_proof:
        if user.profile:
            user.profile.profession_verified = True
            db.add(user.profile)
            db.commit()

    return success({"request_id": req.id, "status": req.status.value})


@router.post("/assets/upload")
async def upload_asset(
    request_id: int,
    type: str,
    file: UploadFile,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    req = db.query(VerificationRequest).filter(VerificationRequest.id == request_id).first()
    if not req or req.user_id != user.id:
        raise HTTPException(status_code=404, detail="Request not found")

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Invalid file type")

    content = await file.read()
    if len(content) > MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=400, detail="File too large")

    scan_file_placeholder(content)

    key = f"verification/{user.id}/{request_id}/{type}/{file.filename}"
    upload_bytes(key, content, file.content_type)

    asset = VerificationAsset(request_id=request_id, type=type, s3_key=key, private_bool=True)
    db.add(asset)
    db.commit()

    return success({"asset_id": asset.id, "key": key})
