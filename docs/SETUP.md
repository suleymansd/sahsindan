# Setup

## Prerequisites
- Docker + Docker Compose
- Node.js + pnpm
- Flutter SDK
- Python 3.12

## Infra

```bash
./infra/dev.sh
```

or

```bash
make dev
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
flutter pub get
flutter run
```

## Seed Data

`infra/dev.sh` runs migrations and seed automatically.

## Environment Files

Copy and adjust:
- `.env.example`
- `services/api/.env.example`
- `apps/web/.env.example`
- `apps/mobile/.env.example`
