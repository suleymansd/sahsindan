from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.deps import require_verified
from app.core.rate_limit import rate_limit
from app.core.response import success
from app.db.models import Listing, ListingPhoto, ListingState, Message, Profile, Thread, User
from app.db.session import get_db
from app.schemas.messaging import MessageCreate, ThreadCreate
from app.services.listing_helpers import last_active_bucket, response_time_bucket
from app.services.realtime import realtime_hub
from app.services.response_rate import update_response_time
from app.utils.time import utc_now
from app.utils.storage import presigned_url

router = APIRouter()


def _thread_out(db: Session, thread: Thread) -> dict:
    messages = (
        db.query(Message)
        .filter(Message.thread_id == thread.id)
        .order_by(Message.created_at.asc())
        .all()
    )
    return {
        "id": thread.id,
        "listing_id": thread.listing_id,
        "buyer_id": thread.buyer_id,
        "seller_id": thread.seller_id,
        "last_message_at": thread.last_message_at.isoformat() if thread.last_message_at else None,
        "messages": [
            {
                "id": message.id,
                "sender_id": message.sender_id,
                "recipient_id": thread.seller_id if message.sender_id == thread.buyer_id else thread.buyer_id,
                "body": message.body,
                "created_at": message.created_at.isoformat() if message.created_at else None,
                "read_at": message.read_at.isoformat() if message.read_at else None,
            }
            for message in messages
        ],
    }


def _thread_out_with_messages(thread: Thread, messages: list[Message]) -> dict:
    return {
        "id": thread.id,
        "listing_id": thread.listing_id,
        "buyer_id": thread.buyer_id,
        "seller_id": thread.seller_id,
        "last_message_at": thread.last_message_at.isoformat() if thread.last_message_at else None,
        "messages": [
            {
                "id": message.id,
                "sender_id": message.sender_id,
                "recipient_id": thread.seller_id if message.sender_id == thread.buyer_id else thread.buyer_id,
                "body": message.body,
                "created_at": message.created_at.isoformat() if message.created_at else None,
                "read_at": message.read_at.isoformat() if message.read_at else None,
            }
            for message in messages
        ],
    }


def _threads_out_batch(db: Session, threads: list[Thread]) -> list[dict]:
    if not threads:
        return []

    thread_ids = [thread.id for thread in threads]
    messages = (
        db.query(Message)
        .filter(Message.thread_id.in_(thread_ids))
        .order_by(Message.thread_id.asc(), Message.created_at.asc(), Message.id.asc())
        .all()
    )
    messages_by_thread: dict[int, list[Message]] = {}
    for message in messages:
        messages_by_thread.setdefault(message.thread_id, []).append(message)

    return [_thread_out_with_messages(thread, messages_by_thread.get(thread.id, [])) for thread in threads]


def _thread_summaries_out_batch(db: Session, current_user: User, threads: list[Thread]) -> list[dict]:
    if not threads:
        return []

    thread_ids = [thread.id for thread in threads]
    listing_ids = list({thread.listing_id for thread in threads})
    other_user_ids = list(
        {
            thread.seller_id if current_user.id == thread.buyer_id else thread.buyer_id
            for thread in threads
        }
    )

    last_message_subquery = (
        db.query(
            Message.thread_id.label("thread_id"),
            func.max(Message.id).label("last_message_id"),
        )
        .filter(Message.thread_id.in_(thread_ids))
        .group_by(Message.thread_id)
        .subquery()
    )
    last_message_rows = (
        db.query(Message.thread_id, Message.body)
        .join(last_message_subquery, Message.id == last_message_subquery.c.last_message_id)
        .all()
    )
    last_message_map = {thread_id: body for thread_id, body in last_message_rows}

    unread_rows = (
        db.query(Message.thread_id, func.count(Message.id))
        .filter(
            Message.thread_id.in_(thread_ids),
            Message.sender_id != current_user.id,
            Message.read_at.is_(None),
        )
        .group_by(Message.thread_id)
        .all()
    )
    unread_map = {thread_id: count for thread_id, count in unread_rows}

    users = db.query(User).filter(User.id.in_(other_user_ids)).all() if other_user_ids else []
    users_by_id = {item.id: item for item in users}
    profiles = db.query(Profile).filter(Profile.user_id.in_(other_user_ids)).all() if other_user_ids else []
    profiles_by_user = {item.user_id: item for item in profiles}

    listings = db.query(Listing).filter(Listing.id.in_(listing_ids)).all() if listing_ids else []
    listings_by_id = {item.id: item for item in listings}
    photos = (
        db.query(ListingPhoto)
        .filter(ListingPhoto.listing_id.in_(listing_ids))
        .order_by(ListingPhoto.listing_id.asc(), ListingPhoto.sort_order.asc(), ListingPhoto.id.asc())
        .all()
        if listing_ids
        else []
    )
    first_photo_by_listing: dict[int, ListingPhoto] = {}
    for photo in photos:
        first_photo_by_listing.setdefault(photo.listing_id, photo)

    result: list[dict] = []
    for thread in threads:
        other_id = thread.seller_id if current_user.id == thread.buyer_id else thread.buyer_id
        other = users_by_id.get(other_id)
        profile = profiles_by_user.get(other_id)
        if other:
            other_user = {
                "id": other.id,
                "name": profile.name if profile else "Doğrulanmış Kullanıcı",
                "trust_score": other.trust_score,
                "response_time_bucket": response_time_bucket(other.response_time_minutes_avg),
                "last_active_bucket": last_active_bucket(other),
            }
        else:
            other_user = {
                "id": other_id,
                "name": "Kullanıcı",
                "trust_score": 0,
                "response_time_bucket": None,
                "last_active_bucket": "Bu ay aktifti",
            }

        listing = listings_by_id.get(thread.listing_id)
        listing_photo = first_photo_by_listing.get(thread.listing_id)
        listing_summary = {
            "id": thread.listing_id,
            "title": listing.title if listing else None,
            "photo_url": presigned_url(listing_photo.s3_key) if listing_photo else None,
        }

        result.append(
            {
                "id": thread.id,
                "listing_id": thread.listing_id,
                "buyer_id": thread.buyer_id,
                "seller_id": thread.seller_id,
                "last_message_at": thread.last_message_at.isoformat() if thread.last_message_at else None,
                "last_message_body": last_message_map.get(thread.id),
                "unread_count": unread_map.get(thread.id, 0),
                "listing": listing_summary,
                "other_user": other_user,
                "messages": [],
            }
        )
    return result


@router.get("")
def list_threads(request: Request, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    threads = (
        db.query(Thread)
        .filter((Thread.buyer_id == user.id) | (Thread.seller_id == user.id))
        .order_by(Thread.updated_at.desc())
        .all()
    )
    client = request.headers.get("x-client", "").lower()
    if client == "mobile":
        return success(_thread_summaries_out_batch(db, user, threads))
    return success(_threads_out_batch(db, threads))


@router.get("/{thread_id}")
def get_thread(thread_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    thread = db.query(Thread).filter(Thread.id == thread_id).first()
    if not thread or user.id not in [thread.buyer_id, thread.seller_id]:
        raise HTTPException(status_code=404, detail="Thread not found")
    return success(_thread_out(db, thread))


@router.post("")
def create_thread(payload: ThreadCreate, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.id == payload.listing_id).first()
    if not listing or listing.state != ListingState.PUBLISHED:
        raise HTTPException(status_code=400, detail="Listing not available")
    if listing.owner_id == user.id:
        raise HTTPException(status_code=400, detail="Cannot message yourself")

    existing = (
        db.query(Thread)
        .filter(Thread.listing_id == listing.id, Thread.buyer_id == user.id)
        .first()
    )
    if existing:
        return success(_thread_out(db, existing))

    thread = Thread(listing_id=listing.id, buyer_id=user.id, seller_id=listing.owner_id)
    db.add(thread)
    db.commit()
    db.refresh(thread)
    return success(_thread_out(db, thread), status_code=201)


@router.post("/{thread_id}/messages", dependencies=[Depends(rate_limit(limit=20, window_seconds=60))])
async def send_message(
    thread_id: int,
    payload: MessageCreate,
    user: User = Depends(require_verified),
    db: Session = Depends(get_db),
):
    thread = db.query(Thread).filter(Thread.id == thread_id).first()
    if not thread or user.id not in [thread.buyer_id, thread.seller_id]:
        raise HTTPException(status_code=404, detail="Thread not found")

    message = Message(thread_id=thread.id, sender_id=user.id, body=payload.body)
    db.add(message)
    thread.last_message_at = utc_now()
    db.add(thread)
    db.commit()
    db.refresh(message)

    update_response_time(db, thread, user.id)

    recipient_id = thread.seller_id if message.sender_id == thread.buyer_id else thread.buyer_id
    await realtime_hub.emit_to_many(
        [thread.buyer_id, thread.seller_id],
        {
            "type": "new_message",
            "thread_id": thread.id,
            "message": {
                "id": message.id,
                "sender_id": message.sender_id,
                "recipient_id": recipient_id,
                "body": message.body,
                "created_at": message.created_at.isoformat() if message.created_at else None,
                "read_at": message.read_at.isoformat() if message.read_at else None,
            },
        },
    )

    return success({"message_id": message.id})


@router.post("/{thread_id}/read")
async def mark_read(thread_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db)):
    thread = db.query(Thread).filter(Thread.id == thread_id).first()
    if not thread or user.id not in [thread.buyer_id, thread.seller_id]:
        raise HTTPException(status_code=404, detail="Thread not found")

    now = utc_now()
    if user.id == thread.buyer_id:
        thread.buyer_last_read_at = now
    else:
        thread.seller_last_read_at = now

    db.query(Message).filter(
        Message.thread_id == thread.id,
        Message.sender_id != user.id,
        Message.read_at.is_(None),
    ).update({"read_at": now})
    db.add(thread)
    db.commit()

    await realtime_hub.emit_to_many(
        [thread.buyer_id, thread.seller_id],
        {
            "type": "messages_read",
            "thread_id": thread.id,
            "reader_id": user.id,
            "read_at": now.isoformat(),
        },
    )
    return success({"read": True})
