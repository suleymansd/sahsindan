"""Real HTTPS smoke test restricted to an EMPTY local trustmarket-audit deployment.

Run with the API development Python environment and the local Caddy root certificate.
Never invokes SMTP or contacts a paid service. Fixture accounts/files are synthetic.
"""
import argparse
import asyncio
import hashlib
import hmac
from io import BytesIO
import json
import os
from pathlib import Path
import ssl
import struct
import subprocess
import time
from urllib.parse import urlparse

import httpx
from PIL import Image
from websockets.asyncio.client import connect

from backup import compose


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ca", type=Path, required=True)
    parser.add_argument("--base-url", default="https://localhost:8443")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if os.environ.get("COMPOSE_PROJECT_NAME") != "trustmarket-audit" or urlparse(args.base_url).hostname != "localhost":
        parser.error("This fixture generator only supports the isolated localhost trustmarket-audit project")
    fixture = '''
import base64
from app.core.config import settings
from app.core.mfa import encrypt_secret
from app.core.security import hash_password
from app.db.models import User, UserRole, Profile
from app.db.session import SessionLocal
assert settings.public_web_url.startswith('https://localhost:')
with SessionLocal() as db:
    assert db.query(User).count() == 0, 'Smoke requires an empty disposable database'
    user = User(email='operator@example.test', phone='5550000099', password_hash=hash_password('DisposableAudit123!'), role=UserRole.ADMIN, mfa_secret=encrypt_secret(base64.b32encode(b'12345678901234567890').decode()))
    user.profile = Profile(name='Synthetic operator', city='ISTANBUL')
    db.add(user)
    db.commit()
'''
    subprocess.run(compose() + ["exec", "-T", "api", "python", "-c", fixture], check=True)
    checks = []
    context = ssl.create_default_context(cafile=str(args.ca))
    with httpx.Client(base_url=args.base_url, verify=context, timeout=15, trust_env=False) as client:
        def request(method, path, expected=200, **kwargs):
            response = client.request(method, path, **kwargs)
            assert response.status_code == expected, (method, path.split("?")[0], response.status_code, response.text[:200])
            return response

        request("GET", "/ready")
        request("GET", "/giris/kullanici")
        request("GET", "/storage/verification/private.png", 404)
        checks += ["verified HTTPS readiness", "web login page", "private storage isolation"]
        payload = {"email": "operator@example.test", "password": "DisposableAudit123!"}
        request("POST", "/api/auth/login", 401, json=payload)
        counter = struct.pack(">Q", int(time.time()) // 30)
        digest = hmac.new(b"12345678901234567890", counter, hashlib.sha1).digest()
        code = str((struct.unpack(">I", digest[digest[-1] & 15:][:4])[0] & 0x7fffffff) % 1000000).zfill(6)
        admin_data = request("POST", "/api/auth/login", json={**payload, "otp_code": code}).json()["data"]
        admin = {"Authorization": "Bearer " + admin_data["access_token"]}
        request("POST", "/api/auth/login", 401, json={**payload, "otp_code": code})
        checks += ["admin MFA required", "admin MFA success", "MFA replay rejected"]
        output = BytesIO()
        Image.new("RGB", (32, 32), "blue").save(output, format="PNG")
        photo = output.getvalue()
        users = []
        for index in range(2):
            user = request("POST", "/api/auth/register", json={"email": f"smoke{index}@example.test", "phone": f"555000000{index}", "password": "DisposableAudit123!", "name": "Synthetic user", "city": "ISTANBUL"}).json()["data"]
            headers = {"Authorization": "Bearer " + user["access_token"]}
            users.append(headers)
            request("GET", "/api/admin/dashboard", 403, headers=headers)
            req_id = request("POST", "/api/verification/submit", headers=headers, json={"background_consent": True}).json()["data"]["request_id"]
            request("POST", f"/api/admin/verification/{req_id}/approve", 409, headers=admin, json={})
            for kind in ("id_front", "selfie"):
                asset = request("POST", f"/api/verification/assets/upload?request_id={req_id}&type={kind}", headers=headers, files={"file": ("synthetic.png", photo, "image/png")}).json()["data"]
                path = f"/api/admin/verification/{req_id}/assets/{asset['asset_id']}/signed-url"
                request("GET", path, 403, headers=headers)
                url = request("GET", path, headers=admin).json()["data"]["url"]
                result = request("GET", url)
                assert result.headers["cache-control"] == "no-store"
            request("POST", f"/api/admin/verification/{req_id}/approve", headers=admin, json={})
            assert request("GET", "/api/auth/me", headers=headers).json()["data"]["role"] == "USER_VERIFIED"
        checks += ["registration", "role isolation", "document upload", "signed private downloads", "manual verification requires evidence"]
        buyer, seller = users
        car = {"title": "Synthetic production audit", "description": "No real listing", "price": 100000, "city": "ISTANBUL", "district": "Kadikoy", "car_details": {"brand": "Audi", "model": "A4", "year": 2020, "mileage": 100, "transmission": "Automatic", "fuel": "Gasoline", "color": "Blue"}}
        listing_id = request("POST", "/api/listings", 201, headers=seller, json=car).json()["data"]["id"]
        for _ in range(6):
            request("POST", f"/api/listings/{listing_id}/photos", headers=seller, files={"file": ("car.png", photo, "image/png")})
        request("POST", f"/api/listings/{listing_id}/publish", headers=seller)
        request("POST", f"/api/listings/{listing_id}/favorite", headers=buyer)
        assert request("GET", "/api/favorites", headers=buyer).json()["data"][0]["id"] == listing_id
        photo_url = request("GET", f"/api/listings/{listing_id}", headers=buyer).json()["data"]["photos"][0]["url"]
        request("GET", photo_url)
        thread = request("POST", "/api/threads", 201, headers=buyer, json={"listing_id": listing_id}).json()["data"]["id"]

        async def realtime():
            async with connect(args.base_url.replace("https://", "wss://") + "/api/ws/connect", ssl=context, additional_headers=seller, origin=args.base_url, subprotocols=["trustmarket"]) as socket:
                await socket.send("ping")
                assert json.loads(await asyncio.wait_for(socket.recv(), 5))["type"] == "pong"
                request("POST", f"/api/threads/{thread}/messages", headers=buyer, json={"body": "Synthetic HTTPS message"})
                event = json.loads(await asyncio.wait_for(socket.recv(), 10))
                assert event["type"] == "new_message" and event["thread_id"] == thread
        asyncio.run(realtime())
        checks += ["six-photo listing publication", "public photo download", "favorites", "persistent messages", "WSS message delivery"]
    args.output.write_text(json.dumps({"environment": "isolated local production Docker Compose; HTTPS certificate verified", "checks_passed": checks, "real_mail_sent": False, "public_deployment": False}, indent=2) + "\n")
    print(json.dumps({"passed": len(checks), "public_deployment": False}))


if __name__ == "__main__":
    main()
