"""Verify the live API before building an App Store Connect IPA. No automatic upload."""
import argparse
import ipaddress
import json
from pathlib import Path
import plistlib
import re
import shutil
import socket
import subprocess
import time
from urllib.error import HTTPError
from urllib.parse import urlsplit
from urllib.request import build_opener, HTTPRedirectHandler

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "apps/mobile"


def validate_url(value):
    url = urlsplit(value)
    host = url.hostname or ""
    if (url.scheme != "https" or not host or url.username or url.password
            or url.query or url.fragment or url.path.rstrip("/") != "/api"
            or host in {"localhost", "example.com", "example.org", "example.net"}
            or host.endswith((".localhost", ".local", ".test", ".invalid", ".example",
                              ".example.com", ".example.org", ".example.net"))):
        raise ValueError("Supply the real public HTTPS API URL ending in /api")
    # Reject private literal addresses; DNS results are checked by preflight too.
    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        address = None
    if address and not address.is_global:
        raise ValueError("TestFlight requires a publicly reachable API")
    return value.rstrip("/")


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def preflight(api_url):
    url = urlsplit(api_url)
    addresses = socket.getaddrinfo(url.hostname, url.port or 443, type=socket.SOCK_STREAM)
    if not addresses or any(not ipaddress.ip_address(item[4][0]).is_global for item in addresses):
        raise ValueError("API DNS must resolve to public addresses")
    opener = build_opener(NoRedirects())  # System TLS verification remains enabled.
    origin = f"https://{url.netloc}"
    # This is a closed marketplace: even browsing requires a session.
    for path, expected in [("/ready", 200), ("/api/listings?limit=1", 401), ("/api/auth/me", 401)]:
        try:
            response = opener.open(origin + path, timeout=15)
        except HTTPError as error:
            response = error
        with response:
            if response.status != expected:
                raise ValueError(f"{path}: expected {expected}, received {response.status}")
            data = json.loads(response.read(1024 * 1024))
            if not isinstance(data, dict):
                raise ValueError(f"{path}: unexpected JSON response")
            if path == "/ready" and data.get("status") != "ready":
                raise ValueError("Backend is not ready")
            if expected == 401 and not isinstance(data.get("error"), dict):
                raise ValueError("Unexpected authentication error contract")
        print(f"PASS {path} ({expected})")


def check_asset_env():
    # Flutter includes this asset in every build. Never bundle operator secrets.
    path = MOBILE / ".env"
    if not path.is_file():
        raise ValueError("Create apps/mobile/.env from .env.example; it may contain only public client settings")
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, separator, value = line.partition("=")
        if not separator or key.strip() not in {"API_BASE_URL", "LOG_NETWORK"}:
            raise ValueError("Mobile .env contains an unsupported key; do not bundle secrets")
        if key.strip() == "API_BASE_URL":
            parsed = urlsplit(value.strip().strip('\"\''))
            if parsed.username or parsed.password or parsed.query or parsed.fragment:
                raise ValueError("Mobile .env API URL must not contain credentials or tokens")


def validate_archive(archive, build_number):
    app = archive / "Products/Applications/Runner.app"
    with (app / "Info.plist").open("rb") as file:
        info = plistlib.load(file)
    if info.get("CFBundleIdentifier") != "com.sahsindan.app":
        raise ValueError("Archive bundle identifier does not match the existing Apple profile")
    if str(info.get("CFBundleVersion")) != build_number:
        raise ValueError("Archive has a stale build number")
    if info.get("NSAppTransportSecurity", {}).get("NSAllowsArbitraryLoads"):
        raise ValueError("Archive disables App Transport Security")
    if not info.get("NSPhotoLibraryUsageDescription"):
        raise ValueError("Archive is missing the photo-library permission explanation")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["check", "build"])
    parser.add_argument("--api-url", required=True)
    parser.add_argument("--build-number", help="New positive App Store Connect build number")
    parser.add_argument("--flutter", default=shutil.which("flutter") or "flutter")
    args = parser.parse_args()
    try:
        api_url = validate_url(args.api_url)
        check_asset_env()
        preflight(api_url)
        if args.action == "check":
            return 0
        if not re.fullmatch(r"[1-9][0-9]{0,8}", args.build_number or ""):
            raise ValueError("Provide a new positive --build-number (up to 9 digits)")
        started = time.time()
        subprocess.run([
            args.flutter, "build", "ipa", "--release",
            f"--build-number={args.build_number}",
            f"--dart-define=API_BASE_URL={api_url}", "--dart-define=LOG_NETWORK=false",
            f"--export-options-plist={MOBILE / 'ios/ExportOptions.plist'}",
        ], cwd=MOBILE, check=True)
        archive = MOBILE / "build/ios/archive/Runner.xcarchive"
        validate_archive(archive, args.build_number)
        artifacts = [p for p in (MOBILE / "build/ios/ipa").glob("*.ipa") if p.stat().st_mtime >= started]
        if len(artifacts) != 1:
            raise ValueError("No new IPA exported. Inspect Xcode distribution signing; an archive alone is not an IPA")
        manifest = {"api_url": api_url, "build_number": args.build_number,
                    "ipa": str(artifacts[0]), "testflight_uploaded": False}
        (artifacts[0].parent / "release.json").write_text(json.dumps(manifest, indent=2) + "\n")
        print(f"Exported {artifacts[0]}. Upload with Xcode Organizer or Transporter; TestFlight is not yet published.")
        return 0
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Release blocked: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
