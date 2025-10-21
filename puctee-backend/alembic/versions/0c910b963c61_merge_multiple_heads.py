"""merge multiple heads

Revision ID: 0c910b963c61
Revises: 54cc51f8edb8, g4h5i6j7k8l9
Create Date: 2025-10-20 18:57:45.687244

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0c910b963c61'
down_revision: Union[str, None] = ('54cc51f8edb8', 'g4h5i6j7k8l9')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
