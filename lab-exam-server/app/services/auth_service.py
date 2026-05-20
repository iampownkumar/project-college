# ============================================================
# File: app/services/auth_service.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Business logic for student login/verification.
#              Validates student, session, and question assignment.
# ============================================================

from sqlalchemy.orm import Session
from app.repositories.student_repo import StudentRepository
from app.repositories.session_repo import SessionRepository
from app.repositories.assignment_repo import AssignmentRepository
from app.repositories.question_repo import QuestionRepository
from app.schemas.auth import LoginRequest, LoginResponse, StudentOut, SessionOut, AssignmentOut
from app.core.logging import get_logger

logger = get_logger(__name__)


class AuthService:
    """Handles student login verification logic."""

    def __init__(self, db: Session):
        self.db = db
        self.student_repo = StudentRepository(db)
        self.session_repo = SessionRepository(db)
        self.assignment_repo = AssignmentRepository(db)
        self.question_repo = QuestionRepository(db)

    def login(self, payload: LoginRequest) -> LoginResponse:
        """
        Verify student login. Checks:
        1. Student exists and is enabled.
        2. There is an active session.
        3. The student has a question assigned for that session.
        """
        # Step 1: Validate student
        student = self.student_repo.get_by_registration(payload.registration_number)
        if not student:
            logger.warning(
                f"Login failed: unknown registration_number={payload.registration_number}"
            )
            return LoginResponse(
                success=False,
                message="Student not found. Please check your registration number.",
            )

        if not student.enabled:
            logger.warning(
                f"Login failed: student disabled reg={payload.registration_number}"
            )
            return LoginResponse(
                success=False,
                message="Your account is currently disabled. Contact your faculty.",
            )

        # Step 2: Find active session
        session = self.session_repo.get_active()
        if not session:
            logger.warning(
                f"Login failed: no active session for reg={payload.registration_number}"
            )
            return LoginResponse(
                success=False,
                message="No active exam session at this time.",
            )

        # Step 3: Find question assignment
        assignment = self.assignment_repo.get_by_student_and_session(
            student_id=student.id,
            session_id=session.id,
        )
        if not assignment:
            logger.warning(
                f"Login failed: no assignment for reg={payload.registration_number} "
                f"session={session.id}"
            )
            return LoginResponse(
                success=False,
                message="No question has been assigned to you for this session.",
            )

        question = self.question_repo.get_by_id(assignment.question_id)
        if not question:
            logger.error(
                f"Assignment references missing question id={assignment.question_id}"
            )
            return LoginResponse(
                success=False,
                message="Assigned question data is missing. Contact faculty.",
            )

        logger.info(
            f"Login success: reg={payload.registration_number} "
            f"session={session.id} question={question.id}"
        )

        return LoginResponse(
            success=True,
            message="Login successful",
            student=StudentOut.model_validate(student),
            session=SessionOut.model_validate(session),
            assignment=AssignmentOut(
                question_id=question.id,
                question_title=question.title,
                language=question.language,
            ),
        )
