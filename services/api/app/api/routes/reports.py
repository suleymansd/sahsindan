from fastapi import APIRouter, Body, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.deps import require_verified
from app.core.response import success
from app.db.models import Listing, Report, User
from app.db.session import get_db

router = APIRouter()


@router.post("")
def create_report(
    listing_id: int = Body(embed=True),
    reason: str = Body(embed=True),
    category: str | None = Body(default=None, embed=True),
    user: User = Depends(require_verified),
    db: Session = Depends(get_db),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    report = Report(
        reporter_id=user.id,
        listing_id=listing_id,
        reason=reason,
        category=category,
        target_type="listing",
        target_id=listing_id,
    )
    db.add(report)
    db.commit()
    return success({"report_id": report.id})
