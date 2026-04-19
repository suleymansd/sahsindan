"""admin panel extensions

Revision ID: 0002_admin_panel
Revises: 0001_initial
Create Date: 2025-01-02 22:30:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "0002_admin_panel"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("verification_requests", sa.Column("reason_code", sa.String(length=50), nullable=True))

    # SQLite doesn't support ALTER TYPE; on SQLite enums are represented differently.
    bind = op.get_bind()
    dialect = getattr(getattr(bind, "dialect", None), "name", "")
    if dialect == "postgresql":
        op.execute("ALTER TYPE reportstatus ADD VALUE IF NOT EXISTS 'IN_REVIEW'")
        op.execute("ALTER TYPE reportstatus ADD VALUE IF NOT EXISTS 'RESOLVED'")

    op.add_column("reports", sa.Column("category", sa.String(length=50), nullable=True))
    op.add_column(
        "reports",
        sa.Column("target_type", sa.String(length=50), nullable=False, server_default="listing"),
    )
    op.add_column("reports", sa.Column("target_id", sa.Integer(), nullable=True))

    op.add_column(
        "system_settings",
        sa.Column("membership_fee", sa.Numeric(12, 2), nullable=False, server_default="0"),
    )
    op.add_column(
        "system_settings",
        sa.Column("listing_fee", sa.Numeric(12, 2), nullable=False, server_default="0"),
    )
    op.add_column(
        "system_settings",
        sa.Column("photo_max_count", sa.Integer(), nullable=False, server_default="20"),
    )
    op.add_column(
        "system_settings",
        sa.Column("photo_max_mb", sa.Integer(), nullable=False, server_default="8"),
    )
    op.add_column("system_settings", sa.Column("feature_flags", sa.JSON(), nullable=True))


def downgrade():
    op.drop_column("system_settings", "feature_flags")
    op.drop_column("system_settings", "photo_max_mb")
    op.drop_column("system_settings", "photo_max_count")
    op.drop_column("system_settings", "listing_fee")
    op.drop_column("system_settings", "membership_fee")
    op.drop_column("reports", "target_id")
    op.drop_column("reports", "target_type")
    op.drop_column("reports", "category")
    op.drop_column("verification_requests", "reason_code")
