#!/bin/bash
# Database migration script for Railway

set -e

echo "Running Alembic migrations..."
alembic upgrade head
echo "✅ Migrations completed successfully!"
