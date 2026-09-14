from datetime import timedelta

import pytest

from app.db.models import Appointment, AppointmentStatus, Listing, ListingState, Report, User, UserRole
from app.services.stale import run_stale_job
from app.utils.time import utc_now


def test_inactive_listings_and_favorites_are_private(client, make_user, make_listing):
    owner, owner_headers = make_user()
    _, stranger = make_user()
    listing_id = make_listing(owner, state=ListingState.DRAFT)
    response = client.get("/api/listings?include_inactive=true", headers=stranger)
    assert response.status_code == 200
    assert listing_id not in [item["id"] for item in response.json()["data"]]
    assert client.post(f"/api/listings/{listing_id}/favorite", headers=stranger).status_code == 404
    assert client.get(f"/api/listings/{listing_id}", headers=owner_headers).status_code == 200


@pytest.mark.parametrize("state", [ListingState.REJECTED, ListingState.SOLD])
def test_owner_cannot_republish_terminal_listing(client, make_user, make_listing, state):
    owner, headers = make_user()
    listing_id = make_listing(owner, state=state)
    assert client.post(f"/api/listings/{listing_id}/publish", headers=headers).status_code == 409
    assert client.post(f"/api/listings/{listing_id}/confirm-active", headers=headers).status_code == 409


@pytest.mark.parametrize("payload", [{"price": -1}, {"title": None}, {"description": None}, {"price": None}, {"title": ""}])
def test_invalid_listing_update_is_422(client, make_user, make_listing, payload):
    owner, headers = make_user()
    listing_id = make_listing(owner)
    assert client.put(f"/api/listings/{listing_id}", json=payload, headers=headers).status_code == 422


def test_overdue_listing_archives_in_one_run_and_counts_once(db_session, make_user, make_listing):
    owner, _ = make_user()
    listing_id = make_listing(owner, last_confirmed_at=utc_now() - timedelta(days=100))
    with db_session() as db:
        assert run_stale_job(db) == 1
        assert db.get(Listing, listing_id).state == ListingState.ARCHIVED
        assert run_stale_job(db) == 0


def test_appointment_happy_path_and_invalid_transitions(client, db_session, make_user, make_listing, monkeypatch):
    from app.core.config import settings
    monkeypatch.setattr(settings, "listings_cache_enabled", True)
    seller, seller_headers = make_user(trust_score=50)
    _, buyer_headers = make_user()
    _, stranger_headers = make_user()
    listing_id = make_listing(seller)
    assert client.get("/api/listings", headers=buyer_headers).json()["data"][0]["owner"]["trust_score"] == 50
    payload = {"listing_id": listing_id, "scheduled_at": (utc_now() + timedelta(days=1)).isoformat(), "location": "Kadikoy"}
    response = client.post("/api/appointments", json=payload, headers=buyer_headers)
    assert response.status_code == 201
    path = f"/api/appointments/{response.json()['data']['id']}"
    assert client.post(f"{path}/cancel", headers=stranger_headers).status_code == 404
    assert client.post(f"{path}/accept", headers=buyer_headers).status_code == 403
    assert client.post(f"{path}/complete", headers=seller_headers).status_code == 409
    assert client.post(f"{path}/rate?rating=5", headers=buyer_headers).status_code == 409
    assert client.post(f"{path}/accept", headers=seller_headers).status_code == 200
    assert client.post(f"{path}/complete", headers=seller_headers).status_code == 200
    assert client.get("/api/listings", headers=buyer_headers).json()["data"][0]["owner"]["trust_score"] == 55
    assert client.post(f"{path}/cancel", headers=buyer_headers).status_code == 409
    assert client.post(f"{path}/accept", headers=seller_headers).status_code == 409
    assert client.post(f"{path}/reschedule", params={"scheduled_at": payload["scheduled_at"]}, headers=buyer_headers).status_code == 409
    assert client.post(f"{path}/rate?rating=5", headers=buyer_headers).status_code == 200
    with db_session() as db:
        assert db.query(Appointment).one().status == AppointmentStatus.COMPLETED
        assert db.get(User, seller).trust_score == 55


def test_report_confirmation_and_reversal_update_trust(client, db_session, make_user, make_listing):
    seller, _ = make_user()
    reporter, _ = make_user()
    _, admin = make_user(role=UserRole.ADMIN)
    listing_id = make_listing(seller)
    with db_session() as db:
        report = Report(listing_id=listing_id, reporter_id=reporter, reason="Fraud")
        db.add(report)
        db.commit()
        report_id = report.id
    for status, expected_score in [("CONFIRMED", 40), ("REJECTED", 50)]:
        response = client.post(f"/api/admin/reports/{report_id}/set-status", json={"status": status}, headers=admin)
        assert response.status_code == 200
        with db_session() as db:
            assert db.get(User, seller).trust_score == expected_score
