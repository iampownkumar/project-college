# ============================================================
# File: app/services/heartbeat_service.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Business logic for student heartbeat handling.
# ============================================================

from sqlalchemy.orm import Session
from app.repositories.student_repo import StudentRepository
from app.repositories.session_repo import SessionRepository
from app.repositories.heartbeat_repo import HeartbeatRepository
from app.schemas.heartbeat import HeartbeatRequest, HeartbeatOut
from app.schemas.common import SuccessResponse, ErrorResponse
from app.core.logging import get_logger

logger = get_logger(__name__)


class HeartbeatService:
    """Handles heartbeat upserts and validation."""

    def __init__(self, db: Session):
        self.db = db
        self.student_repo = StudentRepository(db)
        self.session_repo = SessionRepository(db)
        self.heartbeat_repo = HeartbeatRepository(db)

    def record(self, payload: HeartbeatRequest):
        """
        Validate and upsert a heartbeat record.
        Returns SuccessResponse or ErrorResponse.
        If the session has expired/been closed, returns session_closed=True
        so the client can force-logout the student.
        """
        student = self.student_repo.get_by_registration(payload.registration_number)
        if not student or not student.enabled:
            logger.warning(f"Heartbeat: unknown student reg={payload.registration_number}")
            return ErrorResponse(message="Student not found or disabled.")

        session = self.session_repo.get_by_id(payload.session_id)
        if not session:
            logger.warning(f"Heartbeat: unknown session id={payload.session_id}")
            return ErrorResponse(message="Session not found.")

        hb = self.heartbeat_repo.upsert(
            student_id=student.id,
            session_id=session.id,
            machine_name=payload.machine_name,
            machine_ip=payload.machine_ip,
            client_state=payload.client_state,
        )

        # Check if the session is still active (get_active auto-closes expired ones)
        active = self.session_repo.get_active()
        session_closed = (active is None or active.id != payload.session_id)

        logger.debug(
            f"Heartbeat recorded: reg={payload.registration_number} "
            f"state={payload.client_state} session_closed={session_closed}"
        )

        hb_out = HeartbeatOut.model_validate(hb)
        hb_out.session_closed = session_closed

        return SuccessResponse(
            message="Heartbeat recorded.",
            data=hb_out,
        )
