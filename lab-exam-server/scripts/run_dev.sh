#!/usr/bin/env bash
# ============================================================
# File: scripts/run_dev.sh
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Development startup script for the coordinator server.
#              Runs on Arch Linux (or any Linux with Python 3.12+).
#
# Usage:
#   cd lab-exam-server/
#   bash scripts/run_dev.sh
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "============================================================"
echo " Lab Exam Server - Development Mode"
echo " Author: Pownkumar A (Founder of Korelium)"
echo "============================================================"

# Ensure .env exists
if [ ! -f ".env" ]; then
    echo "[run_dev] .env not found. Copying from .env.example..."
    cp .env.example .env
    echo "[run_dev] Created .env from .env.example"
fi

# Ensure logs directory exists
mkdir -p logs

# Ensure data directory exists
mkdir -p data

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    echo "[run_dev] Activating virtual environment..."
    source venv/bin/activate
elif [ -d ".venv" ]; then
    echo "[run_dev] Activating .venv..."
    source .venv/bin/activate
else
    echo "[run_dev] WARNING: No venv or .venv found."
    echo "[run_dev] Consider running: python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
fi

# Load HOST and PORT from .env if set, otherwise use defaults
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"

echo "[run_dev] Starting uvicorn at http://${HOST}:${PORT}"
echo "[run_dev] API docs: http://localhost:${PORT}/docs"
echo ""

python -m uvicorn app.main:app \
    --host "$HOST" \
    --port "$PORT" \
    --reload \
    --log-level info
