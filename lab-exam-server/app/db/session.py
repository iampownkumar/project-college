# ============================================================
# File: app/db/session.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Re-exports session dependency from core/database.py
#              for clean import paths across the application.
# ============================================================

from app.core.database import get_db, SessionLocal, engine

__all__ = ["get_db", "SessionLocal", "engine"]
