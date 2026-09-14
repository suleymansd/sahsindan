import re

from pydantic import BaseModel, Field, field_validator

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class EmailMixin(BaseModel):
    email: str = Field(max_length=254)

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        value = value.strip().lower()
        if not EMAIL_RE.match(value):
            raise ValueError("Invalid email format")
        return value


def validate_password_bytes(value: str) -> str:
    if len(value.encode("utf-8")) > 72:
        raise ValueError("Password must be at most 72 UTF-8 bytes")
    return value


class RegisterRequest(EmailMixin):
    phone: str = Field(min_length=6, max_length=32)
    password: str = Field(min_length=8, max_length=72)
    name: str = Field(min_length=2, max_length=120)
    city: str = Field(min_length=2, max_length=80)
    profession_category: str | None = Field(default=None, max_length=120)

    _validate_password = field_validator("password")(validate_password_bytes)


class LoginRequest(EmailMixin):
    password: str = Field(max_length=256)
    otp_code: str | None = Field(default=None, pattern=r"^[0-9]{6}$")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class RefreshResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None


class ForgotPasswordRequest(EmailMixin):
    pass


class ResetPasswordRequest(BaseModel):
    token: str = Field(max_length=4096)
    new_password: str = Field(min_length=8, max_length=72)

    _validate_password = field_validator("new_password")(validate_password_bytes)


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


class RefreshRequest(BaseModel):
    refresh_token: str | None = Field(default=None, max_length=4096)
