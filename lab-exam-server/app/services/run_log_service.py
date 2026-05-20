# ============================================================
# File: app/services/run_log_service.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Business logic for recording code execution run logs.
# ============================================================

from sqlalchemy.orm import Session
from app.repositories.student_repo import StudentRepository
from app.repositories.session_repo import SessionRepository
from app.repositories.run_log_repo import RunLogRepository
from app.models.run_log import RunLog
from app.schemas.run_log import RunLogRequest, RunLogOut
from app.schemas.common import SuccessResponse, ErrorResponse
from app.core.logging import get_logger

logger = get_logger(__name__)


class RunLogService:
    """Handles run log recording and validation."""

    def __init__(self, db: Session):
        self.db = db
        self.student_repo = StudentRepository(db)
        self.session_repo = SessionRepository(db)
        self.run_log_repo = RunLogRepository(db)

    def record(self, payload: RunLogRequest):
        """
        Validate and store a code execution run log.
        Returns SuccessResponse or ErrorResponse.
        """
        student = self.student_repo.get_by_registration(payload.registration_number)
        if not student or not student.enabled:
            logger.warning(f"RunLog: unknown student reg={payload.registration_number}")
            return ErrorResponse(message="Student not found or disabled.")

        session = self.session_repo.get_by_id(payload.session_id)
        if not session:
            logger.warning(f"RunLog: unknown session id={payload.session_id}")
            return ErrorResponse(message="Session not found.")

        run_log = RunLog(
            student_id=student.id,
            session_id=session.id,
            question_id=payload.question_id,
            source_code=payload.source_code,
            stdout=payload.stdout,
            stderr=payload.stderr,
            exit_code=payload.exit_code,
            duration_ms=payload.duration_ms,
        )
        saved = self.run_log_repo.create(run_log)

        logger.debug(
            f"RunLog recorded: reg={payload.registration_number} "
            f"exit_code={payload.exit_code}"
        )

        return SuccessResponse(
            message="Run log recorded.",
            data=RunLogOut.model_validate(saved),
        )
