# ============================================================
# File: app/schemas/session.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Pydantic schemas for exam session data.
# ============================================================

from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class SessionBase(BaseModel):
    title: str
    department: str
    language: str = "python"
    duration_minutes: int = 60
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None


class SessionCreate(SessionBase):
    pass


class SessionOut(BaseModel):
    id: int
    title: str
    department: str
    language: str
    duration_minutes: int
    status: str
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
