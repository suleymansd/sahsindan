# Security

## Authentication
- bcrypt password hashing
- JWT access tokens + refresh token rotation
- httpOnly refresh cookie for web

## Rate Limiting
- Redis-backed per-endpoint limits (login, messaging, uploads)

## Upload Safety
- Content-type whitelist (jpg/png/pdf)
- Size limits
- Virus scan hook placeholder
- Private verification assets

## Audit Logs
- Sensitive actions recorded (verification decisions, takedowns)

## Threats & Mitigations
- Credential stuffing -> rate limit + bcrypt
- Fake listings -> verified-only access + moderation
- Stale inventory -> confirmation workflow + auto-archive
- No-show abuse -> trust score penalties
