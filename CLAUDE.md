# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Monorepo Layout

- `apps/web` — Next.js 14 App Router (TypeScript, Tailwind, React Query, shadcn-style UI)
- `apps/mobile` — Flutter + Riverpod + go_router + Dio
- `services/api` — FastAPI + SQLAlchemy 2 + Alembic (SQLite locally, Postgres in Docker)
- `infra` — docker-compose (Postgres, Redis, MinIO, API, Nginx) + nginx.conf
- `scripts` / `services/api/scripts` — dev runners and seed scripts
- `docs` — `ARCHITECTURE.md`, `API.md`, `SECURITY.md`, `SETUP.md`, `DESIGN_SYSTEM.md`

## Running the Stack

Two supported modes — pick one, don't mix:

**1. Full Docker (Postgres + Redis + MinIO + Nginx)** — `make dev` or `./infra/dev.sh`. API is reachable at `http://localhost:8080/api` (Nginx proxies it, so the `/api` prefix is required). Migrations + seed run automatically. MinIO is the object store; `/storage` is proxied through Nginx.

**2. Docker-free (SQLite + in-memory Redis + local static storage)** — `services/api/scripts/dev_local.sh`. API runs directly on `http://127.0.0.1:8080` with **no `/api` prefix** (Nginx isn't in the loop). Storage is served by FastAPI at `/storage/...`. This mode also runs `alembic upgrade head` and `scripts/seed.py` before starting uvicorn.

The `/api` prefix difference between the two modes is the most common footgun — the Flutter `API_BASE_URL` and web client base URL must match the mode you're running.

Combined one-shot for Flutter web + docker-free API: `./scripts/dev_mobile_web.sh` (API on 8080, Flutter web on 3005).

## Per-App Commands

**Web** (`apps/web`):
- `pnpm dev` — Next.js dev server (default port 3000)
- `pnpm build` / `pnpm start`
- `pnpm lint` — next lint (ESLint)
- No test runner configured.

**API** (`services/api`):
- `pytest` — run the test suite (`tests/` dir, see `pytest.ini`)
- `pytest tests/test_listings.py::test_name` — single test
- `alembic upgrade head` — apply migrations
- `alembic revision --autogenerate -m "msg"` — new migration
- `python scripts/seed.py` (Postgres) or `python scripts/seed_sqlite.py` (SQLite) — seed demo data
- `python scripts/create_admin.py` — create admin user
- No linter configured; the repo relies on Python 3.12 defaults.

**Mobile** (`apps/mobile`):
- `flutter pub get` → `flutter run`
- `flutter run -d chrome --web-port=3005 --web-hostname=127.0.0.1` for web target
- `flutter test`
- Build-time override: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` (Android emulator uses `10.0.2.2` for host loopback)

## API Architecture

FastAPI app entrypoint: `services/api/app/main.py`. Routers are composed in `app/api/router.py` under the `/api` prefix and split per domain in `app/api/routes/` (`auth`, `verification`, `listings`, `favorites`, `follows`, `messaging`, `appointments`, `reports`, `profile`, `admin`, `ws`).

Layering:
- `app/api/routes/*` — HTTP handlers, validation, response shaping
- `app/schemas/*` — Pydantic request/response models
- `app/services/*` — domain logic (`stale`, `trust`, `listing_helpers`, `listing_cache`, `audit`, `realtime`, `response_rate`)
- `app/db/` — `models.py` (SQLAlchemy), `session.py`, `base.py`
- `app/core/` — `config` (pydantic-settings), `deps` (FastAPI dependencies), `security` (JWT, hashing), `rate_limit`, `redis`, `response` (uniform `{data,meta}` / `{error}` envelope)

Cross-cutting behaviors in `main.py`:
- Exception handlers return the standard error envelope (`VALIDATION_ERROR`, `HTTP_ERROR`, `SERVICE_UNAVAILABLE`, `DATABASE_ERROR`). Preserve this shape when adding new handlers.
- Background `stale_job_loop` runs every 60s (unless `DISABLE_STALE_JOB=1`): transitions listings older than `STALE_DAYS` to `NEEDS_CONFIRMATION`, then to `ARCHIVED` after `CONFIRM_WINDOW_DAYS`.
- `/storage` is only mounted when `DISABLE_STORAGE=1` (docker-free mode); in Docker, MinIO+Nginx serves storage instead.

Config is environment-driven via `app/core/config.py` (`Settings` reads `.env` at `services/api/.env`). Key knobs: `DATABASE_URL`, `REDIS_URL` (supports `memory://` in dev), `LISTINGS_CACHE_*`, `STALE_DAYS`, `CONFIRM_WINDOW_DAYS`, `CITY_LOCK` (MVP is Istanbul-only).

## Core Domain Flows

1. **Auth** — register → login (bcrypt + JWT access + refresh). Web uses httpOnly refresh cookie; mobile sends `X-Client: mobile` and gets the refresh token in the JSON body (managed via `flutter_secure_storage`). 401 → refresh → retry is an interceptor on the Dio client.
2. **Verification wizard** — user submits assets (`POST /verification/submit` + multipart `/verification/assets/upload`) → moderator approves/rejects via `/admin/verification/*`. Browsing is open; creating listings/messages/appointments/reports/favorites requires verified status.
3. **Listings lifecycle** — DRAFT → PUBLISHED → (SOLD | ARCHIVED | REJECTED). `NEEDS_CONFIRMATION` is the intermediate stale state. `POST /listings/{id}/confirm-active` resets `last_confirmed_at`.
4. **Messaging** — thread-based with read receipts; WebSocket updates via `/api/ws`.
5. **Appointments** — accept/decline/reschedule/cancel/complete/no-show/rate. These events feed the trust score.
6. **Trust score** — base 50 after verification; +10 profession verified; +5 per completed appointment (cap +20); −20 per no-show; −10 per confirmed report. Implemented in `app/services/trust.py`.

## Web Architecture

Next.js App Router with route groups for access control: `(public)`, `(app)`, `(account)`, `(admin)`, `(pending)`. `components/route-guard.tsx` enforces auth/verification state. API access goes through `lib/api.ts`; auth state is in `lib/auth.tsx`. Turkish strings live in `lib/strings.tr.ts`.

UI follows shadcn-style primitives in `components/ui/`. `docs/DESIGN_SYSTEM.md` is authoritative for tokens and patterns — consult it before introducing new visual patterns.

## Testing Notes

- API tests (`services/api/tests/`) use `conftest.py` to spin up an isolated DB. Coverage spans auth, listings, messaging, appointments, follows, rate limiting, and the stale job.
- Rate limits are Redis-backed (`app/core/rate_limit.py`); tests rely on the `memory://` Redis fallback.

## Demo Credentials (from seed)

- Admin: `admin@trustmarket.local` / `Admin123!`
- Moderator: `mod@trustmarket.local` / `Mod123!`
- Verified User: `user1@trustmarket.local` / `User123!`
- Verified Seller: `seller1@trustmarket.local` / `User123!`
- Pending: `pending@trustmarket.local` / `User123!`
- Dev phone OTP: `123456`

## Response Envelope

All API responses use `{ "data": ..., "meta": {} }` on success and `{ "error": { "code", "message", "details" } }` on failure. New endpoints and error handlers must keep this shape (helpers in `app/core/response.py`).
