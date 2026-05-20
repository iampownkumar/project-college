# ============================================================
# File: app/services/question_service.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Business logic for fetching assigned questions.
# ============================================================

from sqlalchemy.orm import Session
from typing import Optional
from app.repositories.student_repo import StudentRepository
from app.repositories.session_repo import SessionRepository
from app.repositories.assignment_repo import AssignmentRepository
from app.repositories.question_repo import QuestionRepository
from app.models.question import Question
from app.core.logging import get_logger

logger = get_logger(__name__)


class QuestionService:
    """Handles assigned question retrieval for a student."""

    def __init__(self, db: Session):
        self.db = db
        self.student_repo = StudentRepository(db)
        self.session_repo = SessionRepository(db)
        self.assignment_repo = AssignmentRepository(db)
        self.question_repo = QuestionRepository(db)

    def get_assigned_question(self, registration_number: str) -> Optional[Question]:
        """
        Return the full Question assigned to this student in the current active session.
        Returns None if student not found, no active session, or no assignment.
        """
        student = self.student_repo.get_by_registration(registration_number)
        if not student or not student.enabled:
            logger.warning(f"Question fetch: student not found or disabled reg={registration_number}")
            return None

        session = self.session_repo.get_active()
        if not session:
            logger.warning(f"Question fetch: no active session for reg={registration_number}")
            return None

        assignment = self.assignment_repo.get_by_student_and_session(
            student.id, session.id
        )
        if not assignment:
            logger.warning(f"Question fetch: no assignment for reg={registration_number}")
            return None

        question = self.question_repo.get_by_id(assignment.question_id)
        return question
