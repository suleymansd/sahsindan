from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import require_verified
from app.core.response import success
from app.db.session import get_db
from app.services.trust import trust_breakdown

router = APIRouter()


@router.get("/trust")
def get_trust_breakdown(user=Depends(require_verified), db: Session = Depends(get_db)):
    return success(trust_breakdown(db, user.id))
