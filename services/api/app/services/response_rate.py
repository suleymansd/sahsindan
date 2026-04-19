from sqlalchemy.orm import Session

from app.db.models import Message, Thread, User
from app.utils.time import ensure_aware, utc_now


def update_response_time(db: Session, thread: Thread, sender_id: int):
    if sender_id != thread.seller_id:
        return

    last_buyer_message = (
        db.query(Message)
        .filter(Message.thread_id == thread.id, Message.sender_id == thread.buyer_id)
        .order_by(Message.created_at.desc())
        .first()
    )
    if not last_buyer_message:
        return

    delta = utc_now() - ensure_aware(last_buyer_message.created_at)
    minutes = max(1, int(delta.total_seconds() / 60))
    user = db.query(User).filter(User.id == thread.seller_id).first()
    if not user:
        return

    if user.response_time_minutes_avg is None:
        user.response_time_minutes_avg = minutes
    else:
        user.response_time_minutes_avg = int((user.response_time_minutes_avg + minutes) / 2)
    db.add(user)
    db.commit()
