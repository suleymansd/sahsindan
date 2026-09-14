from pydantic import BaseModel


class VerificationStatusOut(BaseModel):
    status: str
    reason: str | None
    reason_code: str | None = None


class VerificationSubmit(BaseModel):
    phone_otp: str = ""
    selfie_passed: bool = False
    profession_proof: str | None = None
    background_consent: bool


class AdminVerificationDecision(BaseModel):
    reason: str | None = None
    reason_code: str | None = None


class AdminVerificationMoreInfo(BaseModel):
    note: str | None = None
