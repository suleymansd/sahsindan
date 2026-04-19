"""add changed parts field to car details

Revision ID: 0005_car_parts_status
Revises: 0004_scaling_indexes
Create Date: 2026-04-11 01:20:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "0005_car_parts_status"
down_revision = "0004_scaling_indexes"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("car_details", sa.Column("changed_parts", sa.JSON(), nullable=True))


def downgrade():
    op.drop_column("car_details", "changed_parts")
