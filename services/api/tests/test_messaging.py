from fastapi.testclient import TestClient

from app.db.models import Message, User, UserRole
from app.main import app


def _make_verified(client: TestClient, db_session, *, email: str, phone: str, name: str):
    payload = {
        "email": email,
        "phone": phone,
        "password": "Pass1234!",
        "name": name,
        "city": "ISTANBUL",
    }
    client.post("/api/auth/register", json=payload)

    db = db_session()
    user = db.query(User).filter(User.email == email).first()
    user.role = UserRole.USER_VERIFIED
    db.add(user)
    db.commit()
    db.close()

    login = client.post("/api/auth/login", json={"email": email, "password": "Pass1234!"})
    token = login.json()["data"]["access_token"]
    return token


def test_threads_mobile_summary(db_session):
    client = TestClient(app)

    seller_token = _make_verified(
        client,
        db_session,
        email="seller2@trustmarket.local",
        phone="5552000001",
        name="Seller2",
    )
    buyer_token = _make_verified(
        client,
        db_session,
        email="buyer2@trustmarket.local",
        phone="5552000002",
        name="Buyer2",
    )

    listing_payload = {
        "title": "Audi A3 2017",
        "description": "Clean",
        "price": 650000,
        "city": "ISTANBUL",
        "district": "Kadikoy",
        "car_details": {
            "brand": "Audi",
            "model": "A3",
            "year": 2017,
            "mileage": 80000,
            "transmission": "Automatic",
            "fuel": "Gasoline",
            "color": "White",
        },
    }

    created = client.post("/api/listings", json=listing_payload, headers={"Authorization": f"Bearer {seller_token}"})
    assert created.status_code == 201
    listing_id = created.json()["data"]["id"]

    pub = client.post(f"/api/listings/{listing_id}/publish", headers={"Authorization": f"Bearer {seller_token}"})
    assert pub.status_code == 200

    thread = client.post(
        "/api/threads",
        json={"listing_id": listing_id},
        headers={"Authorization": f"Bearer {buyer_token}"},
    )
    assert thread.status_code == 201
    thread_id = thread.json()["data"]["id"]

    msg = client.post(
        f"/api/threads/{thread_id}/messages",
        json={"body": "Merhaba"},
        headers={"Authorization": f"Bearer {buyer_token}"},
    )
    assert msg.status_code == 200

    detail = client.get(
        f"/api/threads/{thread_id}",
        headers={"Authorization": f"Bearer {buyer_token}"},
    )
    assert detail.status_code == 200
    last_msg = detail.json()["data"]["messages"][-1]
    assert last_msg["sender_id"] != last_msg["recipient_id"]
    assert last_msg["recipient_id"] == detail.json()["data"]["seller_id"]

    # Buyer sees 0 unread (sent by buyer)
    buyer_threads = client.get(
        "/api/threads",
        headers={"Authorization": f"Bearer {buyer_token}", "X-Client": "mobile"},
    )
    assert buyer_threads.status_code == 200
    item = buyer_threads.json()["data"][0]
    assert item["id"] == thread_id
    assert item["listing"]["title"] == "Audi A3 2017"
    assert item["other_user"]["name"] == "Seller2"
    assert item["unread_count"] == 0
    assert item["last_message_body"] == "Merhaba"

    # Seller sees 1 unread
    seller_threads = client.get(
        "/api/threads",
        headers={"Authorization": f"Bearer {seller_token}", "X-Client": "mobile"},
    )
    assert seller_threads.status_code == 200
    item2 = seller_threads.json()["data"][0]
    assert item2["unread_count"] == 1


def test_mark_read_only_updates_other_side_messages(db_session):
    client = TestClient(app)

    seller_token = _make_verified(
        client,
        db_session,
        email="seller3@trustmarket.local",
        phone="5552100001",
        name="Seller3",
    )
    buyer_token = _make_verified(
        client,
        db_session,
        email="buyer3@trustmarket.local",
        phone="5552100002",
        name="Buyer3",
    )

    listing_payload = {
        "title": "BMW 320i 2018",
        "description": "Test",
        "price": 720000,
        "city": "ISTANBUL",
        "district": "Kadikoy",
        "car_details": {
            "brand": "BMW",
            "model": "320i",
            "year": 2018,
            "mileage": 95000,
            "transmission": "Automatic",
            "fuel": "Gasoline",
            "color": "Black",
        },
    }
    created = client.post("/api/listings", json=listing_payload, headers={"Authorization": f"Bearer {seller_token}"})
    listing_id = created.json()["data"]["id"]
    client.post(f"/api/listings/{listing_id}/publish", headers={"Authorization": f"Bearer {seller_token}"})

    thread = client.post(
        "/api/threads",
        json={"listing_id": listing_id},
        headers={"Authorization": f"Bearer {buyer_token}"},
    )
    thread_id = thread.json()["data"]["id"]

    client.post(
        f"/api/threads/{thread_id}/messages",
        json={"body": "Buyer message"},
        headers={"Authorization": f"Bearer {buyer_token}"},
    )
    client.post(
        f"/api/threads/{thread_id}/messages",
        json={"body": "Seller response"},
        headers={"Authorization": f"Bearer {seller_token}"},
    )

    mark = client.post(
        f"/api/threads/{thread_id}/read",
        headers={"Authorization": f"Bearer {seller_token}"},
    )
    assert mark.status_code == 200

    db = db_session()
    messages = db.query(Message).filter(Message.thread_id == thread_id).order_by(Message.id.asc()).all()
    db.close()
    assert len(messages) == 2
    assert messages[0].sender_id != messages[1].sender_id
    assert messages[0].read_at is not None
    assert messages[1].read_at is None
