import re

from pydantic import BaseModel, Field, field_validator

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class EmailMixin(BaseModel):
    email: str

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        if not EMAIL_RE.match(value):
            raise ValueError("Invalid email format")
        return value.strip().lower()


class RegisterRequest(EmailMixin):
    phone: str = Field(min_length=6, max_length=32)
    password: str = Field(min_length=8)
    name: str = Field(min_length=2)
    city: str = Field(min_length=2)
    profession_category: str | None = None


class LoginRequest(EmailMixin):
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class RefreshResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None


class ForgotPasswordRequest(EmailMixin):
    pass


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=8)


class UserSummary(BaseModel):
    id: int
    email: str
    phone: str
    role: str
    status: str
    trust_score: int


class AuthResponse(BaseModel):
    access_token: str
    user: UserSummary
    refresh_token: str | None = None
