"""scaling indexes for messaging, appointments and reports

Revision ID: 0004_scaling_indexes
Revises: 0003_performance_indexes
Create Date: 2026-04-10 21:05:00.000000
"""

from alembic import op


# revision identifiers, used by Alembic.
revision = "0004_scaling_indexes"
down_revision = "0003_performance_indexes"
branch_labels = None
depends_on = None


def upgrade():
    op.create_index("ix_threads_buyer_updated_at", "threads", ["buyer_id", "updated_at"], unique=False)
    op.create_index("ix_threads_seller_updated_at", "threads", ["seller_id", "updated_at"], unique=False)

    op.create_index("ix_messages_thread_created_at", "messages", ["thread_id", "created_at"], unique=False)
    op.create_index("ix_messages_thread_read_at", "messages", ["thread_id", "read_at"], unique=False)
    op.create_index("ix_messages_thread_sender_read_at", "messages", ["thread_id", "sender_id", "read_at"], unique=False)

    op.create_index("ix_appointments_buyer_updated_at", "appointments", ["buyer_id", "updated_at"], unique=False)
    op.create_index("ix_appointments_seller_updated_at", "appointments", ["seller_id", "updated_at"], unique=False)

    op.create_index("ix_reports_status_created_at", "reports", ["status", "created_at"], unique=False)
    op.create_index("ix_reports_listing_status", "reports", ["listing_id", "status"], unique=False)
    op.create_index("ix_reports_target_type_status", "reports", ["target_type", "status"], unique=False)
    op.create_index("ix_reports_category", "reports", ["category"], unique=False)

    op.create_index("ix_audit_logs_target_created_at", "audit_logs", ["target_type", "target_id", "created_at"], unique=False)


def downgrade():
    op.drop_index("ix_audit_logs_target_created_at", table_name="audit_logs")

    op.drop_index("ix_reports_category", table_name="reports")
    op.drop_index("ix_reports_target_type_status", table_name="reports")
    op.drop_index("ix_reports_listing_status", table_name="reports")
    op.drop_index("ix_reports_status_created_at", table_name="reports")

    op.drop_index("ix_appointments_seller_updated_at", table_name="appointments")
    op.drop_index("ix_appointments_buyer_updated_at", table_name="appointments")

    op.drop_index("ix_messages_thread_sender_read_at", table_name="messages")
    op.drop_index("ix_messages_thread_read_at", table_name="messages")
    op.drop_index("ix_messages_thread_created_at", table_name="messages")

    op.drop_index("ix_threads_seller_updated_at", table_name="threads")
    op.drop_index("ix_threads_buyer_updated_at", table_name="threads")
