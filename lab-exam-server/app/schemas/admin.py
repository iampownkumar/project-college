# ============================================================
# File: app/schemas/admin.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Pydantic schemas for all admin API endpoints.
#              Covers session, question, student, assignment,
#              and live-monitor request/response types.
# ============================================================

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ── Session ───────────────────────────────────────────────────

class SessionCreateRequest(BaseModel):
    """Create a new exam session."""
    title: str = Field(..., min_length=3, max_length=200)
    department: str = Field(..., max_length=100)
    language: str = Field(default="python", max_length=50)
    duration_minutes: int = Field(default=60, ge=10, le=480)
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None


class SessionStatusUpdateRequest(BaseModel):
    """Change the status of an existing session."""
    status: str = Field(..., pattern="^(draft|active|closed)$")


class SessionAdminOut(BaseModel):
    """Full session details for admin view."""
    id: int
    title: str
    department: str
    language: str
    duration_minutes: int
    status: str
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    created_at: Optional[datetime] = None
    question_count: int = 0
    student_count: int = 0

    model_config = {"from_attributes": True}


# ── Question ──────────────────────────────────────────────────

class QuestionCreateRequest(BaseModel):
    """Add a new question to a session."""
    session_id: int
    language: str = Field(default="python", max_length=50)
    title: str = Field(..., min_length=3, max_length=300)
    statement: str = Field(..., min_length=10)
    starter_code: Optional[str] = None
    visible_examples: Optional[List[dict]] = None
    test_cases: Optional[List[dict]] = None
    constraints: Optional[List[str]] = None
    metadata: Optional[dict] = None


class QuestionAdminOut(BaseModel):
    """Question details for admin view."""
    id: int
    session_id: int
    language: str
    title: str
    statement: str
    starter_code: Optional[str] = None
    visible_examples_json: Optional[str] = None
    constraints_json: Optional[str] = None
    test_cases_json: Optional[str] = None
    metadata_json: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class QuestionBulkRow(BaseModel):
    """One row for bulk question upload."""
    title: str = Field(..., min_length=3, max_length=300)
    statement: str = Field(..., min_length=10)
    language: str = Field(default="python", max_length=50)
    starter_code: Optional[str] = None
    visible_examples: Optional[List[dict]] = None
    test_cases: Optional[List[dict]] = None
    constraints: Optional[List[str]] = None
    metadata: Optional[dict] = None

class QuestionBulkRequest(BaseModel):
    """Bulk question upload payload."""
    session_id: int
    questions: List[QuestionBulkRow]

class QuestionBulkResult(BaseModel):
    """Result of a bulk question upload."""
    total: int
    created: int
    skipped: int
    errors: List[str] = []

# ── Students ──────────────────────────────────────────────────

class StudentCreateRequest(BaseModel):
    """Add a single student."""
    registration_number: str = Field(..., min_length=3, max_length=50)
    name: str = Field(..., min_length=2, max_length=150)
    department: str = Field(..., max_length=100)
    batch: str = Field(..., max_length=20)
    year: str = Field(..., max_length=20)
    section: str = Field(..., max_length=10)
    enabled: bool = True


class StudentBulkRow(BaseModel):
    """One row for bulk student upload."""
    registration_number: str
    name: str
    department: str
    batch: str
    year: str
    section: str
    enabled: bool = True


class StudentBulkRequest(BaseModel):
    """Bulk student upload payload."""
    students: List[StudentBulkRow]


class StudentBulkResult(BaseModel):
    """Result of a bulk student upload."""
    total: int
    created: int
    skipped: int
    errors: List[str] = []


class StudentAdminOut(BaseModel):
    """Student details for admin view."""
    id: int
    registration_number: str
    name: str
    department: str
    batch: str
    year: str
    section: str
    enabled: bool
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ── Assignments ───────────────────────────────────────────────

class AssignmentCreateRequest(BaseModel):
    """Manually assign a specific question to a student."""
    session_id: int
    registration_number: str
    question_id: int


class BulkAssignRequest(BaseModel):
    """Bulk assignment request payload with optional filters and specific question."""
    session_id: int
    year: Optional[str] = None
    section: Optional[str] = None
    question_id: Optional[int] = None


class AssignmentAdminOut(BaseModel):
    """Assignment record for admin view."""
    id: int
    session_id: int
    student_id: int
    question_id: int
    assigned_at: Optional[datetime] = None
    student_registration: Optional[str] = None
    student_name: Optional[str] = None
    student_department: Optional[str] = None
    student_year: Optional[str] = None
    student_section: Optional[str] = None
    question_title: Optional[str] = None


# ── Live Monitor ──────────────────────────────────────────────

class StudentLiveStatus(BaseModel):
    """Live status of one student during an exam session."""
    registration_number: str
    name: str
    year: Optional[str] = None
    section: Optional[str] = None
    machine_name: Optional[str] = None
    machine_ip: Optional[str] = None
    client_state: Optional[str] = None
    last_seen_at: Optional[datetime] = None
    question_title: Optional[str] = None
    run_count: int = 0
    submitted: bool = False
    has_submitted: bool = False   # alias used by dashboard JS
    is_online: bool = False       # computed by monitor service
    last_exit_code: Optional[int] = None


class MonitorResponse(BaseModel):
    """Full live monitor snapshot for a session."""
    session_id: int
    session_title: str
    session_status: str
    total_students: int
    online_count: int
    submitted_count: int
    students: List[StudentLiveStatus]


# ── Departments ──────────────────────────────────────────────────

class DepartmentCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    code: str = Field(..., min_length=2, max_length=20)

class DepartmentOut(BaseModel):
    id: int
    name: str
    code: str

    model_config = {"from_attributes": True}


# ── Submissions Admin ─────────────────────────────────────────

class SubmissionAdminOut(BaseModel):
    """Submission record for admin view."""
    id: int
    session_id: int
    student_id: int
    registration_number: Optional[str] = None
    student_name: Optional[str] = None
    student_department: Optional[str] = None
    student_year: Optional[str] = None
    student_section: Optional[str] = None
    question_id: int
    question_title: Optional[str] = None
    source_code: Optional[str] = None
    exit_code: Optional[int] = None
    final_status: Optional[str] = None
    submitted_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    # normal | auto_tab_switch | auto_timer | resubmission
    submission_type: Optional[str] = "normal"
    submit_count: int = 1

    model_config = {"from_attributes": True}
