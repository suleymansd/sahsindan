from __future__ import annotations

from pydantic import BaseModel, Field


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
    stale_days: int | None = Field(default=None, ge=1)
    confirm_window_days: int | None = Field(default=None, ge=1)
    photo_max_count: int | None = Field(default=None, ge=1, le=100)
    photo_max_mb: int | None = Field(default=None, ge=1, le=8)
    listing_fee: float | None = Field(default=None, ge=0, allow_inf_nan=False)
    membership_fee: float | None = Field(default=None, ge=0, allow_inf_nan=False)
    feature_flags: dict | None = None
    city_lock: str | None = Field(default=None, min_length=1, max_length=120)
