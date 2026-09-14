from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

import pytest
from sqlalchemy import event

from app.api.routes import admin, appointments
from app.core.security import create_refresh_token
from app.db.models import (
    Appointment, AppointmentStatus, AuditLog, Favorite, Follow, Thread,
    RefreshToken, Report, ReportStatus, User, UserRole, VerificationRequest,
)
from app.utils.time import utc_now

pytestmark = pytest.mark.postgres


@pytest.mark.parametrize("kind,model", [("favorite", Favorite), ("follow", Follow), ("thread", Thread)])
def test_simultaneous_relation_creation_is_idempotent(client, db_session, make_user, make_listing, kind, model):
    seller, _ = make_user()
    _, headers = make_user()
    listing_id = make_listing(seller)
    paths = {"favorite": f"/api/listings/{listing_id}/favorite", "follow": f"/api/follows/{seller}",
             "thread": "/api/threads"}
    barrier = Barrier(2, timeout=10)
    engine = db_session.kw["bind"]

    def before_insert(conn, cursor, statement, parameters, context, executemany):
        # Favorite quota now serializes on the user row. Synchronize before
        # acquiring that lock; waiting at INSERT would deadlock the test itself.
        if kind == "favorite":
            if "FROM users" in statement and "FOR UPDATE" in statement:
                barrier.wait()
        elif statement.startswith(f"INSERT INTO {model.__tablename__} "):
            barrier.wait()

    def create(_):
        return client.post(paths[kind], headers=headers, json={"listing_id": listing_id})

    event.listen(engine, "before_cursor_execute", before_insert)
    try:
        with ThreadPoolExecutor(max_workers=2) as pool:
            responses = list(pool.map(create, range(2)))
    finally:
        event.remove(engine, "before_cursor_execute", before_insert)
    assert sorted(response.status_code for response in responses) == ([200, 200] if kind == "favorite" else [200, 201])
    if kind == "thread":
        assert responses[0].json()["data"]["id"] == responses[1].json()["data"]["id"]
    with db_session() as db:
        assert db.query(model).count() == 1


@pytest.mark.parametrize("actions,score", [(["complete", "complete"], 60), (["complete", "no-show"], 35)])
def test_simultaneous_appointment_results_preserve_both_score_changes(client, db_session, make_user, make_listing, monkeypatch, actions, score):
    seller, headers = make_user(trust_score=50)
    buyer, _ = make_user()
    listing_id = make_listing(seller)
    with db_session() as db:
        rows = [Appointment(listing_id=listing_id, buyer_id=buyer, seller_id=seller,
                            status=AppointmentStatus.ACCEPTED, scheduled_at=utc_now(), location="Test") for _ in range(2)]
        db.add_all(rows)
        db.commit()
        ids = [row.id for row in rows]
    barrier = Barrier(2, timeout=10)
    original = appointments.recalculate_trust_score

    def synchronized_recalculate(db, user_id):
        barrier.wait()
        return original(db, user_id)

    monkeypatch.setattr(appointments, "recalculate_trust_score", synchronized_recalculate)
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(lambda pair: client.post(f"/api/appointments/{pair[0]}/{pair[1]}", headers=headers), zip(ids, actions)))
    assert [response.status_code for response in responses] == [200, 200]
    with db_session() as db:
        assert db.get(User, seller).trust_score == score
        assert db.query(Appointment).filter_by(status=AppointmentStatus.ACCEPTED).count() == 0


def test_concurrent_verification_decisions_have_one_winner(client, db_session, make_user):
    target_id, _ = make_user(role=UserRole.USER_PENDING)
    _, headers = make_user(role=UserRole.ADMIN)
    with db_session() as db:
        request = VerificationRequest(user_id=target_id)
        db.add(request)
        db.commit()
        request_id = request.id
    barrier = Barrier(2, timeout=10)

    def decide(action):
        barrier.wait()
        return client.post(f"/api/admin/verification/{request_id}/{action}", headers=headers, json={"reason": "Test"})

    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(decide, ["approve", "reject"]))
    assert sorted(response.status_code for response in responses) == [200, 409]
    with db_session() as db:
        assert db.query(AuditLog).count() == 1


def test_concurrent_report_confirmations_preserve_both_penalties(client, db_session, make_user, make_listing, monkeypatch):
    seller, _ = make_user(trust_score=50)
    reporter, headers = make_user(role=UserRole.ADMIN)
    listing_id = make_listing(seller)
    with db_session() as db:
        rows = [Report(listing_id=listing_id, reporter_id=reporter, reason="Test") for _ in range(2)]
        db.add_all(rows)
        db.commit()
        ids = [row.id for row in rows]
    barrier = Barrier(2, timeout=10)
    original = admin.recalculate_trust_score

    def synchronized_recalculate(db, user_id):
        barrier.wait()
        return original(db, user_id)

    monkeypatch.setattr(admin, "recalculate_trust_score", synchronized_recalculate)
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(lambda id: client.post(f"/api/admin/reports/{id}/set-status", headers=headers,
                                                        json={"status": "CONFIRMED"}), ids))
    assert [response.status_code for response in responses] == [200, 200]
    with db_session() as db:
        assert db.get(User, seller).trust_score == 30
        assert db.query(Report).filter_by(status=ReportStatus.CONFIRMED).count() == 2
        assert db.query(AuditLog).count() == 2


def test_concurrent_refresh_has_one_winner(client, db_session, make_user):
    user_id, _ = make_user()
    token, jti, expires_at = create_refresh_token(user_id)
    with db_session() as db:
        db.add(RefreshToken(user_id=user_id, jti=jti, expires_at=expires_at))
        db.commit()
    barrier = Barrier(2, timeout=10)

    def rotate(_):
        barrier.wait()
        return client.post("/api/auth/refresh", params={"refresh_token": token})

    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(rotate, range(2)))
    assert sorted(response.status_code for response in responses) == [200, 401]
    with db_session() as db:
        assert db.query(RefreshToken).filter(RefreshToken.revoked_at.is_(None)).count() == 1


def test_concurrent_photo_uploads_cannot_exceed_listing_quota(client, db_session, make_user, make_listing, monkeypatch):
    from io import BytesIO
    from PIL import Image
    from app.core.config import settings
    from app.db.models import ListingPhoto
    owner, headers = make_user()
    listing_id = make_listing(owner)
    monkeypatch.setattr(settings, "photo_max_count", 1)
    monkeypatch.setattr("app.api.routes.listings.upload_bytes", lambda key, *args: key)
    content = BytesIO()
    Image.new("RGB", (4, 4), "white").save(content, format="PNG")
    barrier = Barrier(2, timeout=10)

    def upload(_):
        barrier.wait()
        return client.post(f"/api/listings/{listing_id}/photos", headers=headers, files={"file": ("photo.png", content.getvalue(), "image/png")}).status_code

    with ThreadPoolExecutor(max_workers=2) as pool:
        assert sorted(pool.map(upload, range(2))) == [200, 400]
    with db_session() as db:
        assert db.query(ListingPhoto).count() == 1


def test_favorite_quota_last_slot_is_atomic(client, db_session, make_user, make_listing, monkeypatch):
    from app.core.config import settings
    monkeypatch.setattr(settings, "max_favorites_per_user", 2)
    seller, _ = make_user()
    buyer, headers = make_user()
    ids = [make_listing(seller) for _ in range(3)]
    assert client.post(f"/api/listings/{ids[0]}/favorite", headers=headers).status_code == 200
    barrier = Barrier(2, timeout=10)
    def create(listing_id):
        barrier.wait()
        return client.post(f"/api/listings/{listing_id}/favorite", headers=headers)
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(create, ids[1:]))
    assert sorted(response.status_code for response in responses) == [200, 409]
    assert client.post(f"/api/listings/{ids[0]}/favorite", headers=headers).status_code == 200
    with db_session() as db:
        assert db.query(Favorite).filter_by(user_id=buyer).count() == 2
