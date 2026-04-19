# Architecture

## High-Level

- **Web**: Next.js App Router + React Query + Tailwind
- **Mobile**: Flutter + Riverpod
- **API**: FastAPI + SQLAlchemy 2 + Alembic
- **Infra**: Postgres, Redis, MinIO, Nginx

## Core Flows

1. Auth -> JWT access + refresh cookie
2. Verification wizard -> moderator approval
3. Listings lifecycle -> DRAFT/PUBLISHED/SOLD/ARCHIVED/REJECTED
4. Messaging threads + read receipts
5. Appointments + events + trust scoring
6. Stale listing job -> NEEDS_CONFIRMATION -> ARCHIVED

## Data Model

- users, profiles
- verification_requests, verification_assets
- listings, car_details, listing_photos
- favorites
- threads, messages
- appointments, appointment_events
- reports, audit_logs
- system_settings

## Stale Listing Enforcement

- Background task runs every 60s (dev)
- If last_confirmed_at > stale_days -> NEEDS_CONFIRMATION
- If not confirmed within confirm_window -> ARCHIVED

## Trust Score

- base 50 after verification
- +10 profession verified
- +5 per completed appointment (cap +20)
- -20 per no-show
- -10 per confirmed report
