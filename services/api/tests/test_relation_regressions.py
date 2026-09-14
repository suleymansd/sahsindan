import pytest
from sqlalchemy.exc import IntegrityError

from app.db.models import Favorite, Follow, Thread
from app.services.unique_relations import get_or_create_relation


@pytest.mark.parametrize("kind,model", [("favorite", Favorite), ("follow", Follow), ("thread", Thread)])
def test_repeated_relation_create_returns_existing_record(client, db_session, make_user, make_listing, kind, model):
    seller, _ = make_user()
    _, headers = make_user()
    listing_id = make_listing(seller)
    path = {"favorite": f"/api/listings/{listing_id}/favorite", "follow": f"/api/follows/{seller}",
            "thread": "/api/threads"}[kind]
    responses = [client.post(path, headers=headers, json={"listing_id": listing_id}) for _ in range(2)]
    assert [response.status_code for response in responses] == ([200, 200] if kind == "favorite" else [201, 200])
    if kind == "thread":
        assert responses[0].json()["data"]["id"] == responses[1].json()["data"]["id"]
    with db_session() as db:
        assert db.query(model).count() == 1


def test_relation_insert_does_not_swallow_unrelated_constraint_errors(db_session, make_user, make_listing):
    seller, _ = make_user()
    buyer, _ = make_user()
    listing_id = make_listing(seller)
    with db_session() as db:
        with pytest.raises(IntegrityError):
            get_or_create_relation(db, Thread, {"listing_id": listing_id, "buyer_id": buyer})
        db.rollback()
        assert db.query(Thread).count() == 0


def test_relation_insert_obeys_caller_rollback(db_session, make_user, make_listing):
    seller, _ = make_user()
    buyer, _ = make_user()
    listing_id = make_listing(seller)
    with db_session() as db:
        get_or_create_relation(db, Favorite, {"listing_id": listing_id, "user_id": buyer})
        db.rollback()
    with db_session() as db:
        assert db.query(Favorite).count() == 0
