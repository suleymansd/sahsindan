"""Create a private production env file without printing secrets or overwriting files."""
import argparse
import base64
import os
from pathlib import Path
import re
import secrets

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--domain", required=True)
parser.add_argument("--email", required=True)
parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "infra/.env.production")
args = parser.parse_args()
if not re.fullmatch(r"[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?", args.domain) or "." not in args.domain or ".." in args.domain:
    parser.error("Supply a bare lowercase DNS hostname")
if not re.fullmatch(r"[a-zA-Z0-9_.+%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", args.email):
    parser.error("Supply a certificate contact email")
text = Path(__file__).resolve().parents[1].joinpath("infra/.env.production.example").read_text()
values = {"DOMAIN": args.domain, "ACME_EMAIL": args.email, "POSTGRES_PASSWORD": secrets.token_hex(32),
          "MFA_ENCRYPTION_KEY": base64.urlsafe_b64encode(secrets.token_bytes(32)).decode(),
          "JWT_SECRET": secrets.token_hex(48), "JWT_REFRESH_SECRET": secrets.token_hex(48)}
for key, value in values.items():
    text = re.sub(rf"^{key}=.*$", f"{key}={value}", text, flags=re.MULTILINE)
fd = os.open(args.output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
with os.fdopen(fd, "w") as file:
    file.write(text)
print(f"Created {args.output}; secrets were not printed. Configure an existing SMTP relay before release.")
