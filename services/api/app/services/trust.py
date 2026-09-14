from sqlalchemy.orm import Session

from app.db.models import Appointment, AppointmentStatus, Listing, Report, ReportStatus, User, UserRole


def recalculate_trust_score(db: Session, user_id: int) -> int:
    """Recalculate within the caller's transaction, serializing changes per user."""
    # Sessions disable autoflush: counts must include the triggering mutation.
    db.flush()
    # NO KEY UPDATE permits concurrent FK checks from appointment/audit inserts.
    user = db.query(User).filter(User.id == user_id).populate_existing().with_for_update(key_share=True).first()
    if not user:
        return 0

    score = 0
    if user.role == UserRole.USER_VERIFIED or user.role in [UserRole.ADMIN, UserRole.MODERATOR]:
        score += 50

    if user.profile and user.profile.profession_verified:
        score += 10

    completed = (
        db.query(Appointment)
        .filter(Appointment.seller_id == user_id, Appointment.status == AppointmentStatus.COMPLETED)
        .count()
    )
    score += min(completed * 5, 20)

    no_shows = (
        db.query(Appointment)
        .filter(Appointment.seller_id == user_id, Appointment.status == AppointmentStatus.NO_SHOW)
        .count()
    )
    score -= no_shows * 20

    confirmed_reports = (
        db.query(Report)
        .join(Listing, Listing.id == Report.listing_id)
        .filter(Report.status == ReportStatus.CONFIRMED, Listing.owner_id == user_id)
        .count()
    )
    if confirmed_reports:
        score -= 10 * confirmed_reports

    score = max(0, min(100, score))
    user.trust_score = score
    db.add(user)
    db.flush()
    return score


def trust_breakdown(db: Session, user_id: int) -> dict:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return {"total": 0}

    base = 50 if user.role in [UserRole.USER_VERIFIED, UserRole.ADMIN, UserRole.MODERATOR] else 0
    profession = 10 if user.profile and user.profile.profession_verified else 0

    completed = (
        db.query(Appointment)
        .filter(Appointment.seller_id == user_id, Appointment.status == AppointmentStatus.COMPLETED)
        .count()
    )
    completed_points = min(completed * 5, 20)

    no_shows = (
        db.query(Appointment)
        .filter(Appointment.seller_id == user_id, Appointment.status == AppointmentStatus.NO_SHOW)
        .count()
    )
    no_show_penalty = no_shows * 20

    confirmed_reports = (
        db.query(Report)
        .join(Listing, Listing.id == Report.listing_id)
        .filter(Report.status == ReportStatus.CONFIRMED, Listing.owner_id == user_id)
        .count()
    )
    report_penalty = confirmed_reports * 10

    total = max(0, min(100, base + profession + completed_points - no_show_penalty - report_penalty))

    return {
        "total": total,
        "base": base,
        "profession": profession,
        "completed_appointments": completed_points,
        "no_show_penalty": no_show_penalty,
        "report_penalty": report_penalty,
    }
