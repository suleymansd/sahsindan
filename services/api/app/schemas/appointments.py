from datetime import datetime
from pydantic import BaseModel, Field


class AppointmentCreate(BaseModel):
    listing_id: int
    scheduled_at: datetime
    location: str = Field(min_length=1, max_length=255)
    notes: str | None = Field(default=None, max_length=2000)


class AppointmentOut(BaseModel):
    id: int
    listing_id: int
    buyer_id: int
    seller_id: int
    status: str
    scheduled_at: datetime
    location: str = Field(min_length=1, max_length=255)
    notes: str | None
