"""merge content moderation and existing heads

Revision ID: 68b3fbd653a5
Revises: 0c910b963c61, h5i6j7k8l9m0
Create Date: 2025-11-04 19:44:48.291401

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '68b3fbd653a5'
down_revision: Union[str, None] = ('0c910b963c61', 'h5i6j7k8l9m0')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
