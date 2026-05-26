# ============================================================
# File: app/schemas/submission.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Pydantic schemas for final code submission payloads.
# ============================================================

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class SubmissionRequest(BaseModel):
    """Payload sent by student client on final submit."""
    registration_number: str = Field(..., min_length=3, max_length=50)
    session_id: int
    question_id: int
    source_code: Optional[str] = None
    stdout: Optional[str] = None
    stderr: Optional[str] = None
    exit_code: Optional[int] = None
    submitted_at: Optional[datetime] = None
    # How the submit was triggered: normal | auto_tab_switch | auto_timer | resubmission
    submission_type: Optional[str] = "normal"


class SubmissionOut(BaseModel):
    """Submission record returned from DB."""
    id: int
    session_id: int
    student_id: int
    question_id: int
    final_status: Optional[str] = None
    submitted_at: Optional[datetime] = None
    submission_type: Optional[str] = "normal"
    submit_count: int = 1

    model_config = {"from_attributes": True}
