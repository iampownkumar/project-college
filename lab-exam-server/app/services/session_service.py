# ============================================================
# File: app/services/session_service.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Business logic for exam session queries.
# ============================================================

from sqlalchemy.orm import Session as DBSession
from typing import Optional
from app.repositories.student_repo import StudentRepository
from app.repositories.session_repo import SessionRepository
from app.repositories.assignment_repo import AssignmentRepository
from app.models.session import ExamSession
from app.core.logging import get_logger

logger = get_logger(__name__)


class SessionService:
    """Handles session lookup business logic."""

    def __init__(self, db: DBSession):
        self.db = db
        self.student_repo = StudentRepository(db)
        self.session_repo = SessionRepository(db)
        self.assignment_repo = AssignmentRepository(db)

    def get_current_session_for_student(
        self, registration_number: str
    ) -> Optional[ExamSession]:
        """
        Return the active session for a given student,
        only if they have an assignment in that session.
        """
        student = self.student_repo.get_by_registration(registration_number)
        if not student or not student.enabled:
            return None

        session = self.session_repo.get_active()
        if not session:
            return None

        assignment = self.assignment_repo.get_by_student_and_session(
            student.id, session.id
        )
        if not assignment:
            return None

        return session
