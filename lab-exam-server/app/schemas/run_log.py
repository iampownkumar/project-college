# ============================================================
# File: app/schemas/run_log.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Pydantic schemas for code run-log payloads.
# ============================================================

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class RunLogRequest(BaseModel):
    """Payload sent by student client after each code run."""
    registration_number: str = Field(..., min_length=3, max_length=50)
    session_id: int
    question_id: int
    source_code: Optional[str] = None
    stdout: Optional[str] = None
    stderr: Optional[str] = None
    exit_code: Optional[int] = None
    duration_ms: Optional[int] = None
    timestamp: Optional[datetime] = None


class RunLogOut(BaseModel):
    """Run log record returned from DB."""
    id: int
    session_id: int
    student_id: int
    question_id: int
    exit_code: Optional[int] = None
    duration_ms: Optional[int] = None
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
