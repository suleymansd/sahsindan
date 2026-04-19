from datetime import datetime
from pydantic import BaseModel


class AppointmentCreate(BaseModel):
    listing_id: int
    scheduled_at: datetime
    location: str
    notes: str | None = None


class AppointmentOut(BaseModel):
    id: int
    listing_id: int
    buyer_id: int
    seller_id: int
    status: str
    scheduled_at: datetime
    location: str
    notes: str | None
