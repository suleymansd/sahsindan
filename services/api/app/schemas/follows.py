from pydantic import BaseModel


class FollowUserSummary(BaseModel):
    id: int
    name: str
    trust_score: int


class FollowStatusOut(BaseModel):
    target_user_id: int
    is_following: bool
    followers_count: int
    following_count: int

