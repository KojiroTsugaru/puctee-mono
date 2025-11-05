"""add content moderation tables

Revision ID: h5i6j7k8l9m0
Revises: g4h5i6j7k8l9
Create Date: 2025-11-04 19:23:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'h5i6j7k8l9m0'
down_revision: Union[str, None] = 'g4h5i6j7k8l9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create content_reports table
    op.create_table(
        'content_reports',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('reporter_user_id', sa.Integer(), nullable=False),
        sa.Column('reported_user_id', sa.Integer(), nullable=True),
        sa.Column('content_type', sa.String(), nullable=False),
        sa.Column('content_id', sa.Integer(), nullable=True),
        sa.Column('reason', sa.String(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('status', sa.String(), nullable=False, server_default='pending'),
        sa.Column('admin_notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['reporter_user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['reported_user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_content_reports_id'), 'content_reports', ['id'], unique=False)
    
    # Create blocked_users table
    op.create_table(
        'blocked_users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('blocker_user_id', sa.Integer(), nullable=False),
        sa.Column('blocked_user_id', sa.Integer(), nullable=False),
        sa.Column('reason', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['blocker_user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['blocked_user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_blocked_users_id'), 'blocked_users', ['id'], unique=False)
    
    # Create unique constraint to prevent duplicate blocks
    op.create_index(
        'ix_blocked_users_blocker_blocked',
        'blocked_users',
        ['blocker_user_id', 'blocked_user_id'],
        unique=True
    )


def downgrade() -> None:
    # Drop blocked_users table
    op.drop_index('ix_blocked_users_blocker_blocked', table_name='blocked_users')
    op.drop_index(op.f('ix_blocked_users_id'), table_name='blocked_users')
    op.drop_table('blocked_users')
    
    # Drop content_reports table
    op.drop_index(op.f('ix_content_reports_id'), table_name='content_reports')
    op.drop_table('content_reports')
