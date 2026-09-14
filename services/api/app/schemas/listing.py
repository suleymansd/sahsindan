from datetime import datetime
from pydantic import BaseModel, Field, model_validator


class CarDetailIn(BaseModel):
    brand: str = Field(min_length=1, max_length=120)
    model: str = Field(min_length=1, max_length=120)
    year: int = Field(ge=1886, le=2100)
    mileage: int = Field(ge=0)
    transmission: str = Field(min_length=1, max_length=50)
    fuel: str = Field(min_length=1, max_length=50)
    color: str = Field(min_length=1, max_length=50)
    vin_optional: str | None = Field(default=None, max_length=120)
    changed_parts: list[str] = Field(default_factory=list, max_length=50)


class ListingCreate(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    description: str = Field(max_length=10000)
    price: float = Field(ge=0, le=9999999999.99, allow_inf_nan=False)
    city: str = Field(min_length=1, max_length=120)
    district: str = Field(min_length=1, max_length=120)
    car_details: CarDetailIn


class ListingUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = Field(default=None, max_length=10000)
    car_details: CarDetailIn | None = None
    price: float | None = Field(default=None, ge=0, le=9999999999.99, allow_inf_nan=False)
    district: str | None = Field(default=None, min_length=1, max_length=120)

    @model_validator(mode="before")
    @classmethod
    def reject_null_updates(cls, data):
        if isinstance(data, dict) and any(data[key] is None for key in data if key in cls.model_fields):
            raise ValueError("Listing fields cannot be null")
        return data


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
    description: str = Field(max_length=10000)
    price: float
    city: str = Field(min_length=1, max_length=120)
    district: str = Field(min_length=1, max_length=120)
    last_confirmed_at: datetime
    owner: ListingOwnerOut
    car_details: CarDetailIn
    photos: list[ListingPhotoOut] = []
