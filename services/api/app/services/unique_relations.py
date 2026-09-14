from sqlalchemy.dialects.postgresql import insert as postgres_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.orm import Session


def get_or_create_relation(db: Session, model, identity: dict, defaults: dict | None = None):
    """Insert on the relation's unique key, without committing the caller's transaction."""
    dialect = db.get_bind().dialect.name
    if dialect == "postgresql":
        insert = postgres_insert
    elif dialect == "sqlite":
        insert = sqlite_insert
    else:
        raise NotImplementedError(f"Unsupported database: {dialect}")
    statement = (
        insert(model)
        .values(**{**(defaults or {}), **identity})
        .on_conflict_do_nothing(index_elements=list(identity))
        .returning(model)
    )
    relation = db.scalars(statement).one_or_none()
    if relation is not None:
        return relation, True
    # Only the specified unique-key conflict is ignored; other integrity errors propagate.
    return db.query(model).filter_by(**identity).one(), False
