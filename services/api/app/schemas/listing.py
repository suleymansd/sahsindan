from datetime import datetime
from pydantic import BaseModel, Field


class CarDetailIn(BaseModel):
    brand: str
    model: str
    year: int
    mileage: int
    transmission: str
    fuel: str
    color: str
    vin_optional: str | None = None
    changed_parts: list[str] = Field(default_factory=list)


class ListingCreate(BaseModel):
    title: str
    description: str
    price: float
    city: str
    district: str
    car_details: CarDetailIn


class ListingUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    price: float | None = None
    district: str | None = None


class ListingPhotoOut(BaseModel):
    id: int
    url: str
    sort_order: int


class ListingPhotoReorder(BaseModel):
    photo_ids: list[int] = Field(min_length=1)


class ListingOwnerOut(BaseModel):
    id: int
    name: str
    trust_score: int
    response_time_bucket: str | None
    last_active_bucket: str


class ListingOut(BaseModel):
    id: int
    state: str
    stale_state: str | None
    title: str
    description: str
    price: float
    city: str
    district: str
    last_confirmed_at: datetime
    owner: ListingOwnerOut
    car_details: CarDetailIn
    photos: list[ListingPhotoOut] = []
