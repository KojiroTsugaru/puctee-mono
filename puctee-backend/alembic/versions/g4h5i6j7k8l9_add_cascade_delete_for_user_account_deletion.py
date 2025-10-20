"""add cascade delete for user account deletion

Revision ID: g4h5i6j7k8l9
Revises: f3g4h5i6j7k8
Create Date: 2025-10-20 15:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'g4h5i6j7k8l9'
down_revision: Union[str, None] = 'f3g4h5i6j7k8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add CASCADE delete to foreign keys
    
    # user_trust_stats
    op.drop_constraint('user_trust_stats_user_id_fkey', 'user_trust_stats', type_='foreignkey')
    op.create_foreign_key('user_trust_stats_user_id_fkey', 'user_trust_stats', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    
    # friend_invites
    op.drop_constraint('friend_invites_sender_id_fkey', 'friend_invites', type_='foreignkey')
    op.create_foreign_key('friend_invites_sender_id_fkey', 'friend_invites', 'users', ['sender_id'], ['id'], ondelete='CASCADE')
    
    op.drop_constraint('friend_invites_receiver_id_fkey', 'friend_invites', type_='foreignkey')
    op.create_foreign_key('friend_invites_receiver_id_fkey', 'friend_invites', 'users', ['receiver_id'], ['id'], ondelete='CASCADE')
    
    # plan_invites
    op.drop_constraint('plan_invites_user_id_fkey', 'plan_invites', type_='foreignkey')
    op.create_foreign_key('plan_invites_user_id_fkey', 'plan_invites', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    
    op.drop_constraint('plan_invites_plan_id_fkey', 'plan_invites', type_='foreignkey')
    op.create_foreign_key('plan_invites_plan_id_fkey', 'plan_invites', 'plans', ['plan_id'], ['id'], ondelete='CASCADE')
    
    # penalties
    op.drop_constraint('penalties_user_id_fkey', 'penalties', type_='foreignkey')
    op.create_foreign_key('penalties_user_id_fkey', 'penalties', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    
    op.drop_constraint('penalties_plan_id_fkey', 'penalties', type_='foreignkey')
    op.create_foreign_key('penalties_plan_id_fkey', 'penalties', 'plans', ['plan_id'], ['id'], ondelete='CASCADE')
    
    # locations
    op.drop_constraint('locations_user_id_fkey', 'locations', type_='foreignkey')
    op.create_foreign_key('locations_user_id_fkey', 'locations', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    
    op.drop_constraint('locations_plan_id_fkey', 'locations', type_='foreignkey')
    op.create_foreign_key('locations_plan_id_fkey', 'locations', 'plans', ['plan_id'], ['id'], ondelete='CASCADE')
    
    # notifications
    op.drop_constraint('notifications_user_id_fkey', 'notifications', type_='foreignkey')
    op.create_foreign_key('notifications_user_id_fkey', 'notifications', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    
    # penalty_approval_requests
    op.drop_constraint('penalty_approval_requests_penalty_user_id_fkey', 'penalty_approval_requests', type_='foreignkey')
    op.create_foreign_key('penalty_approval_requests_penalty_user_id_fkey', 'penalty_approval_requests', 'users', ['penalty_user_id'], ['id'], ondelete='CASCADE')
    
    op.drop_constraint('penalty_approval_requests_approver_user_id_fkey', 'penalty_approval_requests', type_='foreignkey')
    op.create_foreign_key('penalty_approval_requests_approver_user_id_fkey', 'penalty_approval_requests', 'users', ['approver_user_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    # Remove CASCADE delete from foreign keys
    
    # penalty_approval_requests
    op.drop_constraint('penalty_approval_requests_approver_user_id_fkey', 'penalty_approval_requests', type_='foreignkey')
    op.create_foreign_key('penalty_approval_requests_approver_user_id_fkey', 'penalty_approval_requests', 'users', ['approver_user_id'], ['id'])
    
    op.drop_constraint('penalty_approval_requests_penalty_user_id_fkey', 'penalty_approval_requests', type_='foreignkey')
    op.create_foreign_key('penalty_approval_requests_penalty_user_id_fkey', 'penalty_approval_requests', 'users', ['penalty_user_id'], ['id'])
    
    # notifications
    op.drop_constraint('notifications_user_id_fkey', 'notifications', type_='foreignkey')
    op.create_foreign_key('notifications_user_id_fkey', 'notifications', 'users', ['user_id'], ['id'])
    
    # locations
    op.drop_constraint('locations_plan_id_fkey', 'locations', type_='foreignkey')
    op.create_foreign_key('locations_plan_id_fkey', 'locations', 'plans', ['plan_id'], ['id'])
    
    op.drop_constraint('locations_user_id_fkey', 'locations', type_='foreignkey')
    op.create_foreign_key('locations_user_id_fkey', 'locations', 'users', ['user_id'], ['id'])
    
    # penalties
    op.drop_constraint('penalties_plan_id_fkey', 'penalties', type_='foreignkey')
    op.create_foreign_key('penalties_plan_id_fkey', 'penalties', 'plans', ['plan_id'], ['id'])
    
    op.drop_constraint('penalties_user_id_fkey', 'penalties', type_='foreignkey')
    op.create_foreign_key('penalties_user_id_fkey', 'penalties', 'users', ['user_id'], ['id'])
    
    # plan_invites
    op.drop_constraint('plan_invites_plan_id_fkey', 'plan_invites', type_='foreignkey')
    op.create_foreign_key('plan_invites_plan_id_fkey', 'plan_invites', 'plans', ['plan_id'], ['id'])
    
    op.drop_constraint('plan_invites_user_id_fkey', 'plan_invites', type_='foreignkey')
    op.create_foreign_key('plan_invites_user_id_fkey', 'plan_invites', 'users', ['user_id'], ['id'])
    
    # friend_invites
    op.drop_constraint('friend_invites_receiver_id_fkey', 'friend_invites', type_='foreignkey')
    op.create_foreign_key('friend_invites_receiver_id_fkey', 'friend_invites', 'users', ['receiver_id'], ['id'])
    
    op.drop_constraint('friend_invites_sender_id_fkey', 'friend_invites', type_='foreignkey')
    op.create_foreign_key('friend_invites_sender_id_fkey', 'friend_invites', 'users', ['sender_id'], ['id'])
    
    # user_trust_stats
    op.drop_constraint('user_trust_stats_user_id_fkey', 'user_trust_stats', type_='foreignkey')
    op.create_foreign_key('user_trust_stats_user_id_fkey', 'user_trust_stats', 'users', ['user_id'], ['id'])
