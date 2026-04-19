from fastapi.testclient import TestClient

from app.db.models import User, UserRole
from app.main import app


def create_verified_user(client: TestClient, db_session):
    payload = {
        "email": "seller@trustmarket.local",
        "phone": "5552000000",
        "password": "Pass1234!",
        "name": "Seller",
        "city": "ISTANBUL",
    }
    client.post("/api/auth/register", json=payload)
    db = db_session()
    user = db.query(User).filter(User.email == payload["email"]).first()
    user.role = UserRole.USER_VERIFIED
    db.add(user)
    db.commit()
    db.close()

    login = client.post("/api/auth/login", json={"email": payload["email"], "password": payload["password"]})
    token = login.json()["data"]["access_token"]
    return token


def test_listing_flow(db_session):
    client = TestClient(app)
    token = create_verified_user(client, db_session)

    listing_payload = {
        "title": "BMW X5 2018",
        "description": "Clean, full history",
        "price": 900000,
        "city": "ISTANBUL",
        "district": "Kadikoy",
        "car_details": {
            "brand": "BMW",
            "model": "X5",
            "year": 2018,
            "mileage": 60000,
            "transmission": "Automatic",
            "fuel": "Diesel",
            "color": "Black",
            "changed_parts": ["hood", "left_front_fender"],
        },
    }

    res = client.post("/api/listings", json=listing_payload, headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 201
    listing_id = res.json()["data"]["id"]
    assert res.json()["data"]["car_details"]["changed_parts"] == ["hood", "left_front_fender"]

    publish = client.post(f"/api/listings/{listing_id}/publish", headers={"Authorization": f"Bearer {token}"})
    assert publish.status_code == 200

    list_res = client.get("/api/listings", headers={"Authorization": f"Bearer {token}"})
    assert list_res.status_code == 200
    assert len(list_res.json()["data"]) >= 1
    assert "changed_parts" in list_res.json()["data"][0]["car_details"]
