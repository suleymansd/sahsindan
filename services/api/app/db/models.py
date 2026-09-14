import enum

from sqlalchemy import (
    Boolean,
    BigInteger,
    CheckConstraint,
    Column,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Index,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    JSON,
)
from sqlalchemy.orm import relationship

from app.db.base import Base
from app.utils.time import utc_now


class UserRole(str, enum.Enum):
    ADMIN = "ADMIN"
    MODERATOR = "MODERATOR"
    USER_VERIFIED = "USER_VERIFIED"
    USER_PENDING = "USER_PENDING"
    BANNED = "BANNED"


class UserStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"


class VerificationStatus(str, enum.Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class ListingState(str, enum.Enum):
    DRAFT = "DRAFT"
    PUBLISHED = "PUBLISHED"
    SOLD = "SOLD"
    ARCHIVED = "ARCHIVED"
    REJECTED = "REJECTED"


class StaleState(str, enum.Enum):
    NEEDS_CONFIRMATION = "NEEDS_CONFIRMATION"


class AppointmentStatus(str, enum.Enum):
    REQUESTED = "REQUESTED"
    ACCEPTED = "ACCEPTED"
    DECLINED = "DECLINED"
    RESCHEDULED = "RESCHEDULED"
    CANCELLED = "CANCELLED"
    COMPLETED = "COMPLETED"
    NO_SHOW = "NO_SHOW"


class ReportStatus(str, enum.Enum):
    OPEN = "OPEN"
    IN_REVIEW = "IN_REVIEW"
    RESOLVED = "RESOLVED"
    CONFIRMED = "CONFIRMED"
    REJECTED = "REJECTED"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    phone = Column(String(32), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    mfa_secret = Column(Text, nullable=True)
    mfa_last_counter = Column(BigInteger, nullable=False, default=-1, server_default="-1")
    role = Column(Enum(UserRole), nullable=False, default=UserRole.USER_PENDING)
    status = Column(Enum(UserStatus), nullable=False, default=UserStatus.ACTIVE)
    trust_score = Column(Integer, nullable=False, default=0)
    response_time_minutes_avg = Column(Integer, nullable=True)
    last_login_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)

    profile = relationship("Profile", back_populates="user", uselist=False)
    listings = relationship("Listing", back_populates="owner")


class Profile(Base):
    __tablename__ = "profiles"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    name = Column(String(255), nullable=False)
    city = Column(String(120), nullable=False)
    profession_category = Column(String(120), nullable=True)
    profession_verified = Column(Boolean, default=False, nullable=False)

    user = relationship("User", back_populates="profile")


class VerificationRequest(Base):
    __tablename__ = "verification_requests"
    __table_args__ = (Index('ix_verification_user_created', 'user_id', 'created_at'),)

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(Enum(VerificationStatus), default=VerificationStatus.PENDING, nullable=False)
    reviewer_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    reason = Column(Text, nullable=True)
    reason_code = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    assets = relationship("VerificationAsset", back_populates="request")


class VerificationAsset(Base):
    __tablename__ = "verification_assets"

    id = Column(Integer, primary_key=True)
    request_id = Column(Integer, ForeignKey("verification_requests.id"), nullable=False)
    type = Column(String(50), nullable=False)
    s3_key = Column(String(255), nullable=False)
    size_bytes = Column(BigInteger, nullable=False, default=0, server_default="0")
    private_bool = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)

    request = relationship("VerificationRequest", back_populates="assets")


class Listing(Base):
    __tablename__ = "listings"
    __table_args__ = (CheckConstraint("price >= 0", name="ck_listing_price_positive"), Index('ix_listings_state_city_created', 'state', 'city', 'created_at', 'id'), Index('ix_listings_owner_created', 'owner_id', 'created_at'), Index('ix_listings_state_confirmed', 'state', 'last_confirmed_at'),)

    id = Column(Integer, primary_key=True)
    state = Column(Enum(ListingState), default=ListingState.DRAFT, nullable=False)
    stale_state = Column(Enum(StaleState), nullable=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    price = Column(Numeric(12, 2), nullable=False)
    city = Column(String(120), nullable=False)
    district = Column(String(120), nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    last_confirmed_at = Column(DateTime, default=utc_now, nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    owner = relationship("User", back_populates="listings")
    car_details = relationship("CarDetail", back_populates="listing", uselist=False)
    photos = relationship("ListingPhoto", back_populates="listing")


class CarDetail(Base):
    __tablename__ = "car_details"

    id = Column(Integer, primary_key=True)
    listing_id = Column(Integer, ForeignKey("listings.id"), unique=True, nullable=False)
    brand = Column(String(120), nullable=False)
    model = Column(String(120), nullable=False)
    year = Column(Integer, nullable=False)
    mileage = Column(Integer, nullable=False)
    transmission = Column(String(50), nullable=False)
    fuel = Column(String(50), nullable=False)
    color = Column(String(50), nullable=False)
    vin_optional = Column(String(120), nullable=True)
    changed_parts = Column(JSON, nullable=True)

    listing = relationship("Listing", back_populates="car_details")


class ListingPhoto(Base):
    __tablename__ = "listing_photos"
    __table_args__ = (Index('ix_listing_photos_listing_sort', 'listing_id', 'sort_order'),)

    id = Column(Integer, primary_key=True)
    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=False)
    s3_key = Column(String(255), nullable=False)
    size_bytes = Column(BigInteger, nullable=False, default=0, server_default="0")
    sort_order = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)

    listing = relationship("Listing", back_populates="photos")


class Favorite(Base):
    __tablename__ = "favorites"
    __table_args__ = (UniqueConstraint("user_id", "listing_id", name="uq_favorite_user_listing"),)

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)


class Follow(Base):
    __tablename__ = "follows"
    __table_args__ = (UniqueConstraint("follower_id", "following_id", name="uq_follow_follower_following"),)

    id = Column(Integer, primary_key=True)
    follower_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    following_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)


class Thread(Base):
    __tablename__ = "threads"
    __table_args__ = (UniqueConstraint("listing_id", "buyer_id", name="uq_thread_listing_buyer"), Index("ix_threads_buyer_updated_at", "buyer_id", "updated_at"), Index("ix_threads_seller_updated_at", "seller_id", "updated_at"),)

    id = Column(Integer, primary_key=True)
    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=False)
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)
    last_message_at = Column(DateTime, nullable=True)
    buyer_last_read_at = Column(DateTime, nullable=True)
    seller_last_read_at = Column(DateTime, nullable=True)


class Message(Base):
    __tablename__ = "messages"
    __table_args__ = (Index('ix_messages_thread_id_order', 'thread_id', 'id'), Index('ix_messages_thread_unread', 'thread_id', 'read_at', 'sender_id'),)

    id = Column(Integer, primary_key=True)
    thread_id = Column(Integer, ForeignKey("threads.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    body = Column(Text, nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    read_at = Column(DateTime, nullable=True)


class Appointment(Base):
    __tablename__ = "appointments"
    __table_args__ = (Index('ix_appointments_buyer_updated_at', 'buyer_id', 'updated_at'), Index('ix_appointments_seller_updated_at', 'seller_id', 'updated_at'),)

    id = Column(Integer, primary_key=True)
    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=False)
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(Enum(AppointmentStatus), default=AppointmentStatus.REQUESTED, nullable=False)
    scheduled_at = Column(DateTime, nullable=False)
    location = Column(String(255), nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)


class AppointmentEvent(Base):
    __tablename__ = "appointment_events"

    id = Column(Integer, primary_key=True)
    appointment_id = Column(Integer, ForeignKey("appointments.id"), nullable=False)
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    event_type = Column(String(50), nullable=False)
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)


class Report(Base):
    __tablename__ = "reports"

    id = Column(Integer, primary_key=True)
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=False)
    reason = Column(Text, nullable=False)
    category = Column(String(50), nullable=True)
    target_type = Column(String(50), nullable=False, default="listing")
    target_id = Column(Integer, nullable=True)
    status = Column(Enum(ReportStatus), default=ReportStatus.OPEN, nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    resolved_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    resolved_at = Column(DateTime, nullable=True)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True)
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String(120), nullable=False)
    target_type = Column(String(120), nullable=False)
    target_id = Column(Integer, nullable=True)
    meta = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)


class SystemSetting(Base):
    __tablename__ = "system_settings"

    id = Column(Integer, primary_key=True)
    stale_days = Column(Integer, nullable=False, default=30)
    confirm_window_days = Column(Integer, nullable=False, default=7)
    fees = Column(JSON, nullable=True)
    membership_fee = Column(Numeric(12, 2), nullable=False, default=0)
    listing_fee = Column(Numeric(12, 2), nullable=False, default=0)
    photo_max_count = Column(Integer, nullable=False, default=20)
    photo_max_mb = Column(Integer, nullable=False, default=8)
    feature_flags = Column(JSON, nullable=True)
    city_lock = Column(String(120), nullable=False)


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    __table_args__ = (Index('ix_refresh_user_expiry', 'user_id', 'expires_at'),)

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    jti = Column(String(64), nullable=False, unique=True)
    expires_at = Column(DateTime, nullable=False)
    revoked_at = Column(DateTime, nullable=True)


class StorageUsage(Base):
    __tablename__ = "storage_usage"
    id = Column(Integer, primary_key=True)
    used_bytes = Column(BigInteger, nullable=False, default=0, server_default="0")
