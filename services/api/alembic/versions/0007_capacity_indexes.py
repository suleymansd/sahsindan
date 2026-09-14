"""Indexes for bounded marketplace queries."""
from alembic import op

revision = "0007_capacity_indexes"
down_revision = "0006_follow_system"
branch_labels = None
depends_on = None

def upgrade():
    op.create_index('ix_listings_state_city_created', 'listings', ['state', 'city', 'created_at', 'id'])
    op.create_index('ix_listings_owner_created', 'listings', ['owner_id', 'created_at'])
    op.create_index('ix_listings_state_confirmed', 'listings', ['state', 'last_confirmed_at'])
    op.create_index('ix_messages_thread_id_order', 'messages', ['thread_id', 'id'])
    op.create_index('ix_messages_thread_unread', 'messages', ['thread_id', 'read_at', 'sender_id'])
    op.create_index('ix_verification_user_created', 'verification_requests', ['user_id', 'created_at'])
    op.create_index('ix_refresh_user_expiry', 'refresh_tokens', ['user_id', 'expires_at'])

def downgrade():
    op.drop_index('ix_refresh_user_expiry', table_name='refresh_tokens')
    op.drop_index('ix_verification_user_created', table_name='verification_requests')
    op.drop_index('ix_messages_thread_unread', table_name='messages')
    op.drop_index('ix_messages_thread_id_order', table_name='messages')
    op.drop_index('ix_listings_state_confirmed', table_name='listings')
    op.drop_index('ix_listings_owner_created', table_name='listings')
    op.drop_index('ix_listings_state_city_created', table_name='listings')
