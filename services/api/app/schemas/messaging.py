from datetime import datetime
from pydantic import BaseModel, Field


class ThreadCreate(BaseModel):
    listing_id: int


class MessageCreate(BaseModel):
    body: str = Field(min_length=1, max_length=2000)


class MessageOut(BaseModel):
    id: int
    sender_id: int
    body: str
    created_at: datetime
    read_at: datetime | None


class ThreadOut(BaseModel):
    id: int
    listing_id: int
    buyer_id: int
    seller_id: int
    last_message_at: datetime | None
    messages: list[MessageOut] = []
