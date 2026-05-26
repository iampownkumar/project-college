# ============================================================
# File: app/schemas/auth.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Pydantic schemas for student login / auth flow.
# ============================================================

from pydantic import BaseModel, Field
from typing import Optional, Any
from datetime import datetime


class LoginRequest(BaseModel):
    """Payload sent by the student client to log in."""
    registration_number: str = Field(..., min_length=3, max_length=50)
    machine_name: str = Field(..., max_length=100)
    machine_ip: str = Field(..., max_length=50)
    client_version: str = Field(..., max_length=20)


class StudentOut(BaseModel):
    """Student details returned in login response."""
    id: int
    registration_number: str
    name: str
    department: str
    batch: str
    year: str
    section: str

    model_config = {"from_attributes": True}


class SessionOut(BaseModel):
    """Session details returned in login response."""
    id: int
    title: str
    department: str
    language: str
    duration_minutes: int
    status: str
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None

    model_config = {"from_attributes": True}


class AssignmentOut(BaseModel):
    """Assigned question summary returned in login response."""
    question_id: int
    question_title: str
    language: str


class LoginResponse(BaseModel):
    """Full response returned after a successful login."""
    success: bool
    message: str
    student: Optional[StudentOut] = None
    session: Optional[SessionOut] = None
    assignment: Optional[AssignmentOut] = None
