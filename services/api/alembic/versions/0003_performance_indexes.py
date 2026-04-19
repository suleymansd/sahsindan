"""performance indexes

Revision ID: 0003_performance_indexes
Revises: 0002_admin_panel
Create Date: 2026-04-10 19:45:00.000000
"""

from alembic import op


# revision identifiers, used by Alembic.
revision = "0003_performance_indexes"
down_revision = "0002_admin_panel"
branch_labels = None
depends_on = None


def upgrade():
    op.create_index("ix_listings_owner_id", "listings", ["owner_id"], unique=False)
    op.create_index("ix_listings_state_created_at", "listings", ["state", "created_at"], unique=False)
    op.create_index("ix_listings_city_district", "listings", ["city", "district"], unique=False)
    op.create_index("ix_listings_price", "listings", ["price"], unique=False)

    op.create_index("ix_car_details_brand", "car_details", ["brand"], unique=False)
    op.create_index("ix_car_details_model", "car_details", ["model"], unique=False)
    op.create_index("ix_car_details_year", "car_details", ["year"], unique=False)
    op.create_index("ix_car_details_mileage", "car_details", ["mileage"], unique=False)
    op.create_index("ix_car_details_transmission", "car_details", ["transmission"], unique=False)
    op.create_index("ix_car_details_fuel", "car_details", ["fuel"], unique=False)
    op.create_index("ix_car_details_color", "car_details", ["color"], unique=False)

    op.create_index("ix_listing_photos_listing_sort", "listing_photos", ["listing_id", "sort_order"], unique=False)


def downgrade():
    op.drop_index("ix_listing_photos_listing_sort", table_name="listing_photos")

    op.drop_index("ix_car_details_color", table_name="car_details")
    op.drop_index("ix_car_details_fuel", table_name="car_details")
    op.drop_index("ix_car_details_transmission", table_name="car_details")
    op.drop_index("ix_car_details_mileage", table_name="car_details")
    op.drop_index("ix_car_details_year", table_name="car_details")
    op.drop_index("ix_car_details_model", table_name="car_details")
    op.drop_index("ix_car_details_brand", table_name="car_details")

    op.drop_index("ix_listings_price", table_name="listings")
    op.drop_index("ix_listings_city_district", table_name="listings")
    op.drop_index("ix_listings_state_created_at", table_name="listings")
    op.drop_index("ix_listings_owner_id", table_name="listings")
