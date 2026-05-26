# ============================================================
# File: app/schemas/heartbeat.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Pydantic schemas for heartbeat payloads.
# ============================================================

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class HeartbeatRequest(BaseModel):
    """Payload sent by student client periodically."""
    registration_number: str = Field(..., min_length=3, max_length=50)
    session_id: int
    machine_name: str = Field(..., max_length=100)
    machine_ip: str = Field(..., max_length=50)
    client_state: str = Field(default="idle", max_length=50)
    timestamp: Optional[datetime] = None


class HeartbeatOut(BaseModel):
    """Heartbeat record returned from DB."""
    id: int
    session_id: int
    student_id: int
    machine_name: Optional[str] = None
    machine_ip: Optional[str] = None
    client_state: Optional[str] = None
    last_seen_at: Optional[datetime] = None
    # True when the session has been closed/expired — client must logout
    session_closed: bool = False

    model_config = {"from_attributes": True}
