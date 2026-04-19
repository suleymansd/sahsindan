from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.deps import require_verified
from app.core.response import success
from app.db.models import Appointment, AppointmentEvent, AppointmentStatus, Listing, ListingState, User
from app.db.session import get_db
from app.schemas.appointments import AppointmentCreate
from app.services.trust import recalculate_trust_score
from app.utils.time import utc_now

router = APIRouter()


def _log_event(db: Session, appointment: Appointment, actor_id: int, event_type: str, note: str | None = None):
    event = AppointmentEvent(
        appointment_id=appointment.id,
        actor_id=actor_id,
        event_type=event_type,
        note=note,
    )
    db.add(event)


def _serialize(appointment: Appointment) -> dict:
    return {
        "id": appointment.id,
        "listing_id": appointment.listing_id,
        "buyer_id": appointment.buyer_id,
        "seller_id": appointment.seller_id,
        "status": appointment.status.value,
        "scheduled_at": appointment.scheduled_at.isoformat() if appointment.scheduled_at else None,
        "location": appointment.location,
        "notes": appointment.notes,
    }


@router.post("")
def create_appointment(
    payload: AppointmentCreate,
    user: User = Depends(require_verified),
    db: Session = Depends(get_db),
):
    listing = db.query(Listing).filter(Listing.id == payload.listing_id).first()
    if not listing or listing.state != ListingState.PUBLISHED:
        raise HTTPException(status_code=400, detail="Listing not available")
    if listing.owner_id == user.id:
        raise HTTPException(status_code=400, detail="Cannot book own listing")

    appointment = Appointment(
        listing_id=listing.id,
        buyer_id=user.id,
        seller_id=listing.owner_id,
        scheduled_at=payload.scheduled_at,
        location=payload.location,
        notes=payload.notes,
    )
    db.add(appointment)
    db.flush()
    _log_event(db, appointment, user.id, "REQUESTED")
    db.commit()
    db.refresh(appointment)

    return success(_serialize(appointment), status_code=201)


@router.get("/inbox")
def inbox(user: User = Depends(require_verified), db: Session = Depends(get_db)):
    appointments = (
        db.query(Appointment)
        .filter((Appointment.buyer_id == user.id) | (Appointment.seller_id == user.id))
        .order_by(Appointment.updated_at.desc())
        .all()
    )
    return success([_serialize(a) for a in appointments])


def _transition(
    appointment_id: int,
    user: User,
    db: Session,
    new_status: AppointmentStatus,
    note: str | None = None,
    appointment: Appointment | None = None,
):
    if appointment is None:
        appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment or user.id not in [appointment.buyer_id, appointment.seller_id]:
        raise HTTPException(status_code=404, detail="Appointment not found")

    appointment.status = new_status
    appointment.updated_at = utc_now()
    _log_event(db, appointment, user.id, new_status.value, note)
    db.add(appointment)
    db.commit()

    if new_status in [AppointmentStatus.COMPLETED, AppointmentStatus.NO_SHOW]:
        recalculate_trust_score(db, appointment.seller_id)

    return success(_serialize(appointment))


def _ensure_seller(appointment: Appointment, user: User):
    if user.id != appointment.seller_id:
        raise HTTPException(status_code=403, detail="Only seller can perform this action")


@router.post("/{appointment_id}/accept")
def accept(appointment_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    _ensure_seller(appointment, user)
    return _transition(appointment_id, user, db, AppointmentStatus.ACCEPTED, appointment=appointment)


@router.post("/{appointment_id}/decline")
def decline(appointment_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    _ensure_seller(appointment, user)
    return _transition(appointment_id, user, db, AppointmentStatus.DECLINED, appointment=appointment)


@router.post("/{appointment_id}/reschedule")
def reschedule(appointment_id: int, scheduled_at: datetime, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment or user.id not in [appointment.buyer_id, appointment.seller_id]:
        raise HTTPException(status_code=404, detail="Appointment not found")
    appointment.status = AppointmentStatus.RESCHEDULED
    appointment.scheduled_at = scheduled_at
    appointment.updated_at = utc_now()
    _log_event(db, appointment, user.id, "RESCHEDULED")
    db.add(appointment)
    db.commit()
    return success(_serialize(appointment))


@router.post("/{appointment_id}/cancel")
def cancel(appointment_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    return _transition(appointment_id, user, db, AppointmentStatus.CANCELLED)


@router.post("/{appointment_id}/complete")
def complete(appointment_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    _ensure_seller(appointment, user)
    return _transition(appointment_id, user, db, AppointmentStatus.COMPLETED, appointment=appointment)


@router.post("/{appointment_id}/no-show")
def no_show(appointment_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    _ensure_seller(appointment, user)
    return _transition(appointment_id, user, db, AppointmentStatus.NO_SHOW, appointment=appointment)


@router.post("/{appointment_id}/rate")
def rate(appointment_id: int, rating: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    if rating < 1 or rating > 5:
        raise HTTPException(status_code=400, detail="Rating out of range")
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment or user.id not in [appointment.buyer_id, appointment.seller_id]:
        raise HTTPException(status_code=404, detail="Appointment not found")
    _log_event(db, appointment, user.id, "RATED", note=f"rating:{rating}")
    db.commit()
    return success({"rated": True})
