from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.deps import require_verified
from app.core.response import success
from app.db.models import Follow, Profile, User
from app.db.session import get_db
from app.services.unique_relations import get_or_create_relation

router = APIRouter()


def _user_name(profile: Profile | None) -> str:
    if profile and profile.name:
        return profile.name
    return "Kullanıcı"


@router.post("/{target_user_id}")
def follow_user(target_user_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db, scope="function")):
    if target_user_id == user.id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")

    target = db.query(User).filter(User.id == target_user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    _, created = get_or_create_relation(
        db, Follow, {"follower_id": user.id, "following_id": target_user_id},
    )
    db.commit()
    return success({"following": True}, status_code=201 if created else 200)


@router.delete("/{target_user_id}")
def unfollow_user(target_user_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db, scope="function")):
    if target_user_id == user.id:
        raise HTTPException(status_code=400, detail="Cannot unfollow yourself")

    relation = (
        db.query(Follow)
        .filter(Follow.follower_id == user.id, Follow.following_id == target_user_id)
        .first()
    )
    if relation:
        db.delete(relation)
        db.commit()

    return success({"following": False})


@router.get("/status/{target_user_id}")
def follow_status(target_user_id: int, user: User = Depends(require_verified), db: Session = Depends(get_db, scope="function")):
    target = db.query(User).filter(User.id == target_user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    is_following = (
        db.query(Follow)
        .filter(Follow.follower_id == user.id, Follow.following_id == target_user_id)
        .first()
        is not None
    )
    followers_count = db.query(func.count(Follow.id)).filter(Follow.following_id == target_user_id).scalar() or 0
    following_count = db.query(func.count(Follow.id)).filter(Follow.follower_id == target_user_id).scalar() or 0

    return success(
        {
            "target_user_id": target_user_id,
            "is_following": is_following,
            "followers_count": int(followers_count),
            "following_count": int(following_count),
        }
    )


@router.get("/mine")
def my_follows(user: User = Depends(require_verified), db: Session = Depends(get_db, scope="function"), limit: int = Query(50, ge=1, le=100), offset: int = Query(0, ge=0, le=50000)):
    following_rows = (
        db.query(User, Profile)
        .join(Follow, Follow.following_id == User.id)
        .outerjoin(Profile, Profile.user_id == User.id)
        .filter(Follow.follower_id == user.id)
        .order_by(Follow.id.desc()).offset(offset).limit(limit)
        .all()
    )
    followers_rows = (
        db.query(User, Profile)
        .join(Follow, Follow.follower_id == User.id)
        .outerjoin(Profile, Profile.user_id == User.id)
        .filter(Follow.following_id == user.id)
        .order_by(Follow.id.desc()).offset(offset).limit(limit)
        .all()
    )

    following = [
        {
            "id": item.id,
            "name": _user_name(profile),
            "trust_score": item.trust_score,
        }
        for item, profile in following_rows
    ]
    followers = [
        {
            "id": item.id,
            "name": _user_name(profile),
            "trust_score": item.trust_score,
        }
        for item, profile in followers_rows
    ]

    return success(
        {
            "followers_count": db.query(Follow).filter_by(following_id=user.id).count(),
            "following_count": db.query(Follow).filter_by(follower_id=user.id).count(),
            "followers": followers,
            "following": following,
        }
    )
