# API Overview

Base URL: `http://localhost:8080/api`

## Auth
- POST `/auth/register`
- POST `/auth/login`
- POST `/auth/refresh`
- POST `/auth/logout`
- POST `/auth/forgot-password`
- POST `/auth/reset-password`
- GET `/auth/me`

## Verification
- GET `/verification/status`
- POST `/verification/submit`
- POST `/verification/assets/upload` (multipart)

## Admin Verification
- GET `/admin/verification/queue`
- GET `/admin/verification/{id}`
- POST `/admin/verification/{id}/approve`
- POST `/admin/verification/{id}/reject`

## Listings
- GET `/listings`
- GET `/listings/{id}`
- POST `/listings`
- PUT `/listings/{id}`
- POST `/listings/{id}/publish`
- POST `/listings/{id}/mark-sold`
- POST `/listings/{id}/confirm-active`
- POST `/listings/{id}/photos` (multipart)
- DELETE `/listings/{id}/photos/{photo_id}`
- POST `/listings/{id}/favorite`
- DELETE `/listings/{id}/favorite`

## Favorites
- GET `/favorites`

## Profile
- GET `/profile/trust`

## Messaging
- GET `/threads`
- GET `/threads/{id}`
- POST `/threads`
- POST `/threads/{id}/messages`
- POST `/threads/{id}/read`

## Appointments
- POST `/appointments`
- GET `/appointments/inbox`
- POST `/appointments/{id}/accept`
- POST `/appointments/{id}/decline`
- POST `/appointments/{id}/reschedule`
- POST `/appointments/{id}/cancel`
- POST `/appointments/{id}/complete`
- POST `/appointments/{id}/no-show`
- POST `/appointments/{id}/rate`

## Reports
- POST `/reports`

## Admin Moderation
- GET `/admin/users`
- GET `/admin/listings`
- POST `/admin/listings/{id}/take-down`
- GET `/admin/reports`

## Response Format

Success:
```
{ "data": ..., "meta": {} }
```

Error:
```
{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": {...} } }
```
