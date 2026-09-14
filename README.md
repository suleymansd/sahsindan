# şahsından.com (TrustMarket MVP)

Closed, verified-only marketplace for car listings in Istanbul. Built to eliminate stale listings, fake profiles, and wasted time.

## Monorepo Structure

```
/apps/web        Next.js 15 + Tailwind + shadcn-style components
/apps/mobile     Flutter + Riverpod
/services/api    FastAPI + SQLAlchemy 2 + Alembic
/infra           docker-compose, nginx, scripts
/docs            Architecture, Security, API, Setup
```

## One-Command Local Run (Infra)

```bash
./infra/dev.sh
```

or

```bash
make dev
```

This will:
- build and start Postgres, Redis, MinIO, API, Nginx
- run migrations
- seed demo data

You can also run:
```bash
cd infra
docker compose up --build
```

## Web

```bash
cd apps/web
pnpm install
pnpm dev
```

## Mobile

```bash
cd apps/mobile
cp .env.example .env # first run only; preserve an existing .env
flutter pub get
flutter run
```

## URLs

- API (via nginx): `http://localhost:8080/api`
- MinIO console: `http://localhost:9001`
- MinIO storage proxy: `http://localhost:8080/storage`

## Demo Credentials

- Admin: `admin@trustmarket.local` / `Admin123!`
- Moderator: `mod@trustmarket.local` / `Mod123!`
- Verified User: `user1@trustmarket.local` / `User123!`
- Verified Seller: `seller1@trustmarket.local` / `User123!`
- Verified Demo: `verified@test.com` / `Test1234!`
- Pending: `pending@trustmarket.local` / `User123!`

## Dev OTP

- Phone OTP: `123456`

## Sample cURL

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user1@trustmarket.local","password":"User123!"}'
```

```bash
curl -X GET http://localhost:8080/api/listings \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

## Tests

```bash
cd services/api
python -m pip install -r requirements-dev.txt
python -m pytest --cov=app
```

## Docker-Free API (Local SQLite)

Web checks: `cd apps/web && npm run lint && npm run typecheck && npm run build`.
Browser tests: install Chromium with `npx playwright install chromium`, then run
`npm run test:e2e` from `apps/web`. Set `API_PYTHON` to your API virtualenv's Python
if necessary. Tests start disposable API data on port 8091 and the web app on 3080.
They build into `.next-e2e`, preserving the normal web build.

Audit findings, limitations and prioritized next steps: [docs/AUDIT_REPORT_TR.md](docs/AUDIT_REPORT_TR.md).

Docker calistiramiyorsan (veya hizli smoke test icin), API'yi SQLite ile host'ta calistirabilirsin:

```bash
services/api/scripts/dev_local.sh
```

- API: `http://127.0.0.1:8080/api`
- Storage (local): `http://127.0.0.1:8080/storage/...`

## Environment

- Root: `.env.example`
- API: `services/api/.env.example`
- Web: `apps/web/.env.example`
- Mobile: `apps/mobile/.env.example`

## Docs

- Architecture: `docs/ARCHITECTURE.md`
- Security: `docs/SECURITY.md`
- API: `docs/API.md`
- Setup: `docs/SETUP.md`

## Future Integration Hooks

- e-Devlet verification provider
- Liveness/selfie verification API
- Payments + escrow
- KYC risk scoring
- Insurance/vehicle history APIs

## Production readiness

- [Güncel denetim, test ve üretim doğrulama raporu](docs/FINAL_READINESS_TR.md)
- [Yayın, maliyet sınırları ve yedekleme kılavuzu](docs/YAYIN_KILAVUZU_TR.md)
- Önceki denetim bulguları: [AUDIT_REPORT_TR.md](docs/AUDIT_REPORT_TR.md)

Üretim için `infra/compose.production.yml` kullanılır. Yerel geliştirme Compose dosyası üretim yapılandırması değildir. Ücretli AI/SMS hizmeti etkin değildir; barındırma ve trafik maliyetinin sıfır olacağı garanti edilmez.
