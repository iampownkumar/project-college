#!/usr/bin/env bash
# ============================================================
# File: runtime/setup_env.sh
# Project: Lab Exam Client - Koreliurm Labs
# Run this ONCE on each student machine to create the bundled
# Python virtual environment with all required packages.
#
# Usage:
#   chmod +x setup_env.sh
#   ./setup_env.sh
#
# What it does:
#   1. Finds the best available Python 3.9+ interpreter
#   2. Creates a venv at runtime/venv/
#   3. Installs pandas, numpy, matplotlib, seaborn into it
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
REQUIREMENTS="$SCRIPT_DIR/requirements.txt"

echo "========================================"
echo "  Koreliurm Lab Exam — Python Setup"
echo "========================================"
echo ""

# ── Find Python 3 ─────────────────────────────────────────
find_python() {
  for cmd in python3.12 python3.11 python3.10 python3.9 python3 python; do
    if command -v "$cmd" &>/dev/null; then
      ver=$("$cmd" -c "import sys; print(sys.version_info[:2])" 2>/dev/null)
      # Accept 3.9 and above
      if "$cmd" -c "import sys; sys.exit(0 if sys.version_info >= (3,9) else 1)" 2>/dev/null; then
        echo "$cmd"
        return 0
      fi
    fi
  done
  return 1
}

PYTHON_BIN=$(find_python)
if [ -z "$PYTHON_BIN" ]; then
  echo "ERROR: Python 3.9 or later is required but not found."
  echo "Please install Python from https://python.org and re-run this script."
  exit 1
fi

PYTHON_VERSION=$("$PYTHON_BIN" --version 2>&1)
echo "Using:  $PYTHON_BIN  ($PYTHON_VERSION)"
echo "Target: $VENV_DIR"
echo ""

# ── Create venv ───────────────────────────────────────────
if [ -d "$VENV_DIR" ]; then
  echo "→ Removing old environment..."
  rm -rf "$VENV_DIR"
fi

echo "→ Creating virtual environment..."
"$PYTHON_BIN" -m venv "$VENV_DIR"

VENV_PYTHON="$VENV_DIR/bin/python3"
if [ ! -f "$VENV_PYTHON" ]; then
  # Windows Git Bash path fallback
  VENV_PYTHON="$VENV_DIR/Scripts/python.exe"
fi

# ── Upgrade pip silently ───────────────────────────────────
echo "→ Upgrading pip..."
"$VENV_PYTHON" -m pip install --upgrade pip --quiet

# ── Install packages ───────────────────────────────────────
echo "→ Installing packages (this may take a few minutes)..."
echo ""
"$VENV_PYTHON" -m pip install -r "$REQUIREMENTS" --progress-bar on

echo ""
echo "========================================"
echo "  ✅ Setup complete!"
echo ""
echo "  Python: $("$VENV_PYTHON" --version)"
echo "  Path:   $VENV_PYTHON"
echo "========================================"
