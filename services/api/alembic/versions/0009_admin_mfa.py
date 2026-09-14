"""Encrypted TOTP enrollment and replay protection."""
from alembic import op
import sqlalchemy as sa

revision = "0009_admin_mfa"
down_revision = "0008_storage_budget"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("users", sa.Column("mfa_secret", sa.Text(), nullable=True))
    op.add_column("users", sa.Column("mfa_last_counter", sa.BigInteger(), server_default="-1", nullable=False))


def downgrade():
    op.drop_column("users", "mfa_last_counter")
    op.drop_column("users", "mfa_secret")
