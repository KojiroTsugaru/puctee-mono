#!/bin/bash

# Activate virtual environment if not already activated
if [ -z "$VIRTUAL_ENV" ]; then
    if [ -d ".venv" ]; then
        source .venv/bin/activate
    else
        echo "Virtual environment not found. Please ensure .venv directory exists."
        exit 1
    fi
fi

# Add app directory to Python path
export PYTHONPATH=$PYTHONPATH:$(pwd)

# Run tests
pytest tests/ -v --cov=app --cov-report=term-missing

# Error handling
if [ $? -ne 0 ]; then
    echo "An error occurred while running tests."
    exit 1
fi