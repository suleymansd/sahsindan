from fastapi import APIRouter

from app.api.routes import admin, appointments, auth, favorites, follows, listings, messaging, profile, reports, verification, ws

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(verification.router, prefix="/verification", tags=["verification"])
api_router.include_router(listings.router, prefix="/listings", tags=["listings"])
api_router.include_router(favorites.router, prefix="/favorites", tags=["favorites"])
api_router.include_router(follows.router, prefix="/follows", tags=["follows"])
api_router.include_router(messaging.router, prefix="/threads", tags=["messaging"])
api_router.include_router(appointments.router, prefix="/appointments", tags=["appointments"])
api_router.include_router(reports.router, prefix="/reports", tags=["reports"])
api_router.include_router(profile.router, prefix="/profile", tags=["profile"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(ws.router, prefix="/ws", tags=["ws"])
