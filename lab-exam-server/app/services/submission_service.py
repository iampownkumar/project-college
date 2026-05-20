# ============================================================
# File: app/services/submission_service.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Business logic for final submission handling.
# ============================================================

from sqlalchemy.orm import Session
from app.repositories.student_repo import StudentRepository
from app.repositories.session_repo import SessionRepository
from app.repositories.submission_repo import SubmissionRepository
from app.schemas.submission import SubmissionRequest, SubmissionOut
from app.schemas.common import SuccessResponse, ErrorResponse
from app.core.logging import get_logger

logger = get_logger(__name__)


class SubmissionService:
    """Handles final code submission storage and validation."""

    def __init__(self, db: Session):
        self.db = db
        self.student_repo = StudentRepository(db)
        self.session_repo = SessionRepository(db)
        self.submission_repo = SubmissionRepository(db)

    def submit(self, payload: SubmissionRequest):
        """
        Validate and upsert a final code submission.
        Re-submission replaces the existing record for this student/session.
        Returns SuccessResponse or ErrorResponse.
        """
        student = self.student_repo.get_by_registration(payload.registration_number)
        if not student or not student.enabled:
            logger.warning(f"Submission: unknown student reg={payload.registration_number}")
            return ErrorResponse(message="Student not found or disabled.")

        session = self.session_repo.get_by_id(payload.session_id)
        if not session:
            logger.warning(f"Submission: unknown session id={payload.session_id}")
            return ErrorResponse(message="Session not found.")

        saved = self.submission_repo.upsert(
            student_id=student.id,
            session_id=session.id,
            question_id=payload.question_id,
            source_code=payload.source_code,
            stdout=payload.stdout,
            stderr=payload.stderr,
            exit_code=payload.exit_code,
            submitted_at=payload.submitted_at,
            submission_type=payload.submission_type or "normal",
        )

        logger.info(
            f"Submission saved: reg={payload.registration_number} "
            f"session={session.id} question={payload.question_id}"
        )

        return SuccessResponse(
            message="Submission received successfully.",
            data=SubmissionOut.model_validate(saved),
        )
