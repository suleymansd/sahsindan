from __future__ import annotations

from pydantic import BaseModel


class AdminUserRoleUpdate(BaseModel):
    role: str


class AdminUserBan(BaseModel):
    reason: str | None = None


class AdminUserNote(BaseModel):
    note: str


class AdminListingAction(BaseModel):
    reason: str | None = None
    reason_code: str | None = None


class AdminReportStatusUpdate(BaseModel):
    status: str


class AdminReportAction(BaseModel):
    action: str
    note: str | None = None


class AdminSettingsUpdate(BaseModel):
    stale_days: int | None = None
    confirm_window_days: int | None = None
    photo_max_count: int | None = None
    photo_max_mb: int | None = None
    listing_fee: float | None = None
    membership_fee: float | None = None
    feature_flags: dict | None = None
    city_lock: str | None = None
