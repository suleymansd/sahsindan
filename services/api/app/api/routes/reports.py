from fastapi import APIRouter, Body, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.deps import require_verified
from app.core.response import success
from app.core.rate_limit import rate_limit
from app.db.models import Listing, Report, User
from app.db.session import get_db

router = APIRouter()


@router.post("", dependencies=[Depends(rate_limit(10, 3600))])
def create_report(
    listing_id: int = Body(embed=True),
    reason: str = Body(embed=True, min_length=1, max_length=2000),
    category: str | None = Body(default=None, embed=True, max_length=50),
    user: User = Depends(require_verified),
    db: Session = Depends(get_db, scope="function"),
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
