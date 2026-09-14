import pytest

from app.api.routes import admin, appointments
from app.db.models import (
    Appointment, AppointmentEvent, AppointmentStatus, AuditLog, Listing,
    ListingState, Report, ReportStatus, SystemSetting, User, UserRole,
    VerificationRequest, VerificationStatus,
)
from app.utils.time import utc_now


def fail_after_flush(db, *args, **kwargs):
    db.flush()
    raise RuntimeError("simulated persistence failure")


def test_appointment_and_event_roll_back_when_trust_fails(client, db_session, make_user, make_listing, monkeypatch):
    seller, headers = make_user(trust_score=50)
    buyer, _ = make_user()
    listing_id = make_listing(seller)
    with db_session() as db:
        appointment = Appointment(listing_id=listing_id, buyer_id=buyer, seller_id=seller,
                                  status=AppointmentStatus.ACCEPTED, scheduled_at=utc_now(), location="Test")
        db.add(appointment)
        db.commit()
        appointment_id = appointment.id
    monkeypatch.setattr(appointments, "recalculate_trust_score", fail_after_flush)
    with pytest.raises(RuntimeError, match="simulated persistence failure"):
        client.post(f"/api/appointments/{appointment_id}/complete", headers=headers)
    with db_session() as db:
        assert db.get(Appointment, appointment_id).status == AppointmentStatus.ACCEPTED
        assert db.query(AppointmentEvent).count() == 0
        assert db.get(User, seller).trust_score == 50


@pytest.mark.parametrize("action", ["approve", "reject", "request-more-info"])
def test_verification_rolls_back_when_audit_fails(client, db_session, make_user, monkeypatch, action):
    target_id, _ = make_user(role=UserRole.USER_PENDING)
    _, headers = make_user(role=UserRole.ADMIN)
    with db_session() as db:
        request = VerificationRequest(user_id=target_id)
        db.add(request)
        db.commit()
        request_id = request.id
    monkeypatch.setattr(admin, "log_audit", fail_after_flush)
    with pytest.raises(RuntimeError, match="simulated persistence failure"):
        client.post(f"/api/admin/verification/{request_id}/{action}", headers=headers,
                    json={"reason": "Test", "note": "Test"})
    with db_session() as db:
        request = db.get(VerificationRequest, request_id)
        assert request.status == VerificationStatus.PENDING
        assert request.reason is None
        assert request.reviewer_id is None
        assert db.get(User, target_id).role == UserRole.USER_PENDING
        assert db.get(User, target_id).trust_score == 0
        assert db.query(AuditLog).count() == 0


@pytest.mark.parametrize("action,payload", [("ban", {}), ("unban", {"role": "USER_PENDING"}),
                                            ("role", {"role": "USER_PENDING"})])
def test_user_change_rolls_back_when_audit_fails(client, db_session, make_user, monkeypatch, action, payload):
    target_id, _ = make_user(trust_score=50)
    _, headers = make_user(role=UserRole.ADMIN)
    monkeypatch.setattr(admin, "log_audit", fail_after_flush)
    with pytest.raises(RuntimeError, match="simulated persistence failure"):
        client.post(f"/api/admin/users/{target_id}/{action}", headers=headers, json=payload)
    with db_session() as db:
        assert db.get(User, target_id).role == UserRole.USER_VERIFIED
        assert db.get(User, target_id).trust_score == 50


@pytest.mark.parametrize("action", ["take-down", "reject", "archive", "restore"])
def test_listing_change_rolls_back_when_audit_fails(client, db_session, make_user, make_listing, monkeypatch, action):
    owner_id, _ = make_user()
    _, headers = make_user(role=UserRole.ADMIN)
    listing_id = make_listing(owner_id, state=ListingState.DRAFT)
    monkeypatch.setattr(admin, "log_audit", fail_after_flush)
    with pytest.raises(RuntimeError, match="simulated persistence failure"):
        client.post(f"/api/admin/listings/{listing_id}/{action}", headers=headers, json={"reason": "Test"})
    with db_session() as db:
        assert db.get(Listing, listing_id).state == ListingState.DRAFT


def test_report_and_score_roll_back_when_audit_fails(client, db_session, make_user, make_listing, monkeypatch):
    seller, _ = make_user(trust_score=50)
    reporter, headers = make_user(role=UserRole.ADMIN)
    listing_id = make_listing(seller)
    with db_session() as db:
        report = Report(listing_id=listing_id, reporter_id=reporter, reason="Test")
        db.add(report)
        db.commit()
        report_id = report.id
    monkeypatch.setattr(admin, "log_audit", fail_after_flush)
    with pytest.raises(RuntimeError, match="simulated persistence failure"):
        client.post(f"/api/admin/reports/{report_id}/set-status", headers=headers, json={"status": "CONFIRMED"})
    with db_session() as db:
        assert db.get(Report, report_id).status == ReportStatus.OPEN
        assert db.get(User, seller).trust_score == 50


def test_settings_creation_rolls_back_when_audit_fails(client, db_session, make_user, monkeypatch):
    _, headers = make_user(role=UserRole.ADMIN)
    monkeypatch.setattr(admin, "log_audit", fail_after_flush)
    with pytest.raises(RuntimeError, match="simulated persistence failure"):
        client.put("/api/admin/settings", headers=headers, json={"stale_days": 5})
    with db_session() as db:
        assert db.query(SystemSetting).count() == 0


def test_report_takedown_rolls_back_when_audit_fails(client, db_session, make_user, make_listing, monkeypatch):
    seller, _ = make_user()
    reporter, headers = make_user(role=UserRole.ADMIN)
    listing_id = make_listing(seller)
    with db_session() as db:
        report = Report(listing_id=listing_id, reporter_id=reporter, reason="Test")
        db.add(report)
        db.commit()
        report_id = report.id
    monkeypatch.setattr(admin, "log_audit", fail_after_flush)
    with pytest.raises(RuntimeError, match="simulated persistence failure"):
        client.post(f"/api/admin/reports/{report_id}/action", headers=headers, json={"action": "take_down_listing"})
    with db_session() as db:
        assert db.get(Listing, listing_id).state == ListingState.PUBLISHED


@pytest.mark.parametrize("kind", ["user", "listing"])
def test_internal_notes_are_committed(client, db_session, make_user, make_listing, kind):
    target_id, _ = make_user()
    actor_id, headers = make_user(role=UserRole.ADMIN)
    if kind == "user":
        path = f"/api/admin/users/{target_id}/internal-note"
        payload = {"note": "Review later"}
    else:
        target_id = make_listing(target_id)
        path = f"/api/admin/listings/{target_id}/note"
        payload = {"reason": "Review later"}
    assert client.post(path, headers=headers, json=payload).status_code == 200
    with db_session() as db:
        log = db.query(AuditLog).one()
        assert (log.actor_id, log.target_id, log.target_type) == (actor_id, target_id, kind)
        assert log.meta == {"note": "Review later"}


def test_reopened_report_clears_resolution_metadata(client, db_session, make_user, make_listing):
    seller, _ = make_user()
    reporter, headers = make_user(role=UserRole.ADMIN)
    listing_id = make_listing(seller)
    with db_session() as db:
        report = Report(listing_id=listing_id, reporter_id=reporter, reason="Test")
        db.add(report)
        db.commit()
        report_id = report.id
    for status in ["RESOLVED", "OPEN"]:
        assert client.post(f"/api/admin/reports/{report_id}/set-status", headers=headers,
                           json={"status": status}).status_code == 200
        with db_session() as db:
            report = db.get(Report, report_id)
            if status == "RESOLVED":
                assert report.resolved_at is not None
                assert report.resolved_by == reporter
            else:
                assert report.resolved_at is None
                assert report.resolved_by is None


def test_ban_and_unban_refresh_trust_and_audit(client, db_session, make_user):
    target_id, _ = make_user(trust_score=50)
    _, headers = make_user(role=UserRole.ADMIN)
    for action, payload, score in [("ban", {}, 0), ("unban", {"role": "USER_VERIFIED"}, 50)]:
        assert client.post(f"/api/admin/users/{target_id}/{action}", headers=headers, json=payload).status_code == 200
        with db_session() as db:
            assert db.get(User, target_id).trust_score == score
            assert db.query(AuditLog).filter_by(action=f"USER_{action.upper()}NED").count() == 1


def test_unban_rejects_banned_role(client, db_session, make_user):
    from app.db.models import UserStatus
    target_id, _ = make_user(role=UserRole.BANNED, status=UserStatus.SUSPENDED)
    _, headers = make_user(role=UserRole.ADMIN)
    response = client.post(f"/api/admin/users/{target_id}/unban", headers=headers, json={"role": "BANNED"})
    assert response.status_code == 400
    with db_session() as db:
        assert db.get(User, target_id).status == UserStatus.SUSPENDED
        assert db.query(AuditLog).count() == 0


def test_repeated_fee_update_keeps_legacy_json_consistent(client, db_session, make_user):
    _, headers = make_user(role=UserRole.ADMIN)
    for fee in [5, 10]:
        assert client.put("/api/admin/settings", headers=headers, json={"listing_fee": fee}).status_code == 200
        with db_session() as db:
            settings = db.query(SystemSetting).one()
            assert settings.fees["listing_fee"] == settings.listing_fee == fee
