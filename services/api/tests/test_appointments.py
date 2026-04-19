from datetime import timedelta

from fastapi.testclient import TestClient

from app.db.models import User, UserRole
from app.main import app
from app.utils.time import utc_now


def setup_users(client: TestClient, db_session):
    seller_payload = {
        "email": "seller2@trustmarket.local",
        "phone": "5553000000",
        "password": "Pass1234!",
        "name": "Seller",
        "city": "ISTANBUL",
    }
    buyer_payload = {
        "email": "buyer2@trustmarket.local",
        "phone": "5553000001",
        "password": "Pass1234!",
        "name": "Buyer",
        "city": "ISTANBUL",
    }
    client.post("/api/auth/register", json=seller_payload)
    client.post("/api/auth/register", json=buyer_payload)

    db = db_session()
    seller = db.query(User).filter(User.email == seller_payload["email"]).first()
    buyer = db.query(User).filter(User.email == buyer_payload["email"]).first()
    seller.role = UserRole.USER_VERIFIED
    buyer.role = UserRole.USER_VERIFIED
    db.add_all([seller, buyer])
    db.commit()
    db.close()

    seller_token = client.post("/api/auth/login", json={"email": seller_payload["email"], "password": seller_payload["password"]}).json()["data"]["access_token"]
    buyer_token = client.post("/api/auth/login", json={"email": buyer_payload["email"], "password": buyer_payload["password"]}).json()["data"]["access_token"]
    return seller_token, buyer_token


def test_appointment_flow(db_session):
    client = TestClient(app)
    seller_token, buyer_token = setup_users(client, db_session)

    listing_payload = {
        "title": "Audi A4 2019",
        "description": "Well-maintained",
        "price": 650000,
        "city": "ISTANBUL",
        "district": "Besiktas",
        "car_details": {
            "brand": "Audi",
            "model": "A4",
            "year": 2019,
            "mileage": 50000,
            "transmission": "Automatic",
            "fuel": "Gasoline",
            "color": "White",
        },
    }
    listing = client.post("/api/listings", json=listing_payload, headers={"Authorization": f"Bearer {seller_token}"})
    listing_id = listing.json()["data"]["id"]
    client.post(f"/api/listings/{listing_id}/publish", headers={"Authorization": f"Bearer {seller_token}"})

    appointment_payload = {
        "listing_id": listing_id,
        "scheduled_at": (utc_now() + timedelta(days=1)).isoformat(),
        "location": "Besiktas Center",
        "notes": "Bring documents",
    }
    create = client.post("/api/appointments", json=appointment_payload, headers={"Authorization": f"Bearer {buyer_token}"})
    assert create.status_code == 201
    appointment_id = create.json()["data"]["id"]

    accept = client.post(f"/api/appointments/{appointment_id}/accept", headers={"Authorization": f"Bearer {seller_token}"})
    assert accept.status_code == 200
