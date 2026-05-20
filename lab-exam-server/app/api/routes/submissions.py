# ============================================================
# File: app/api/routes/submissions.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Final submission and student status routes.
#              POST /api/v1/submission
#              GET  /api/v1/student/status/{registration_number}
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.submission_service import SubmissionService
from app.repositories.student_repo import StudentRepository
from app.repositories.session_repo import SessionRepository
from app.repositories.assignment_repo import AssignmentRepository
from app.repositories.heartbeat_repo import HeartbeatRepository
from app.repositories.run_log_repo import RunLogRepository
from app.repositories.submission_repo import SubmissionRepository
from app.schemas.submission import SubmissionRequest, SubmissionOut
from app.schemas.heartbeat import HeartbeatOut
from app.schemas.run_log import RunLogOut
from pydantic import BaseModel
from typing import Optional

router = APIRouter(tags=["Submissions"])


@router.post(
    "/submission",
    summary="Final code submission",
    description="Store or replace the student's final code submission for this session.",
)
def submit_code(
    payload: SubmissionRequest,
    db: Session = Depends(get_db),
):
    """
    POST /api/v1/submission

    Upserts a final submission. Re-submitting overwrites the previous.
    """
    service = SubmissionService(db)
    return service.submit(payload)


class StudentStatusOut(BaseModel):
    registration_number: str
    session_id: Optional[int] = None
    heartbeat: Optional[HeartbeatOut] = None
    latest_run: Optional[RunLogOut] = None
    submission: Optional[SubmissionOut] = None


@router.get(
    "/student/status/{registration_number}",
    response_model=StudentStatusOut,
    summary="Get student exam status",
    description="Return current heartbeat, latest run log, and submission state for a student.",
)
def get_student_status(
    registration_number: str,
    db: Session = Depends(get_db),
) -> StudentStatusOut:
    """
    GET /api/v1/student/status/{registration_number}

    Aggregates:
    - Active session ID
    - Last heartbeat
    - Latest code run
    - Submission state
    """
    student_repo = StudentRepository(db)
    session_repo = SessionRepository(db)
    assignment_repo = AssignmentRepository(db)
    heartbeat_repo = HeartbeatRepository(db)
    run_log_repo = RunLogRepository(db)
    submission_repo = SubmissionRepository(db)

    student = student_repo.get_by_registration(registration_number)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found.",
        )

    active_session = session_repo.get_active()
    session_id = active_session.id if active_session else None

    heartbeat = None
    latest_run = None
    submission = None

    if session_id:
        hb = heartbeat_repo.get_by_student_and_session(student.id, session_id)
        heartbeat = HeartbeatOut.model_validate(hb) if hb else None

        rl = run_log_repo.get_latest_for_student_session(student.id, session_id)
        latest_run = RunLogOut.model_validate(rl) if rl else None

        sub = submission_repo.get_by_student_and_session(student.id, session_id)
        submission = SubmissionOut.model_validate(sub) if sub else None

    return StudentStatusOut(
        registration_number=registration_number,
        session_id=session_id,
        heartbeat=heartbeat,
        latest_run=latest_run,
        submission=submission,
    )
