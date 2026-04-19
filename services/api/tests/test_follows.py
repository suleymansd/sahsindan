from fastapi.testclient import TestClient

from app.db.models import User, UserRole
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
    me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    return token, me.json()["data"]["id"]


def test_follow_lifecycle(db_session):
    client = TestClient(app)

    token_a, user_a = _make_verified(
        client,
        db_session,
        email="follow_a@trustmarket.local",
        phone="5552200001",
        name="FollowA",
    )
    _, user_b = _make_verified(
        client,
        db_session,
        email="follow_b@trustmarket.local",
        phone="5552200002",
        name="FollowB",
    )

    before = client.get(f"/api/follows/status/{user_b}", headers={"Authorization": f"Bearer {token_a}"})
    assert before.status_code == 200
    assert before.json()["data"]["is_following"] is False

    create = client.post(f"/api/follows/{user_b}", headers={"Authorization": f"Bearer {token_a}"})
    assert create.status_code == 201
    assert create.json()["data"]["following"] is True

    status = client.get(f"/api/follows/status/{user_b}", headers={"Authorization": f"Bearer {token_a}"})
    assert status.status_code == 200
    assert status.json()["data"]["is_following"] is True
    assert status.json()["data"]["followers_count"] >= 1

    mine = client.get("/api/follows/mine", headers={"Authorization": f"Bearer {token_a}"})
    assert mine.status_code == 200
    assert any(item["id"] == user_b for item in mine.json()["data"]["following"])

    remove = client.delete(f"/api/follows/{user_b}", headers={"Authorization": f"Bearer {token_a}"})
    assert remove.status_code == 200
    assert remove.json()["data"]["following"] is False

    status2 = client.get(f"/api/follows/status/{user_b}", headers={"Authorization": f"Bearer {token_a}"})
    assert status2.status_code == 200
    assert status2.json()["data"]["is_following"] is False

    cannot_self = client.post(f"/api/follows/{user_a}", headers={"Authorization": f"Bearer {token_a}"})
    assert cannot_self.status_code == 400

