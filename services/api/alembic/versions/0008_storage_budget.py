"""Persistent storage accounting; reservations participate in upload transactions."""
from alembic import op
import sqlalchemy as sa

revision = "0008_storage_budget"
down_revision = "0007_capacity_indexes"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table("storage_usage", sa.Column("id", sa.Integer(), primary_key=True), sa.Column("used_bytes", sa.BigInteger(), nullable=False, server_default="0"))
    op.add_column("listing_photos", sa.Column("size_bytes", sa.BigInteger(), nullable=False, server_default="0"))
    op.add_column("verification_assets", sa.Column("size_bytes", sa.BigInteger(), nullable=False, server_default="0"))


def downgrade():
    op.drop_column("verification_assets", "size_bytes")
    op.drop_column("listing_photos", "size_bytes")
    op.drop_table("storage_usage")
