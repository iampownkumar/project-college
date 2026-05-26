# ============================================================
# File: app/repositories/assignment_repo.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Data-access layer for QuestionAssignment model.
# ============================================================

from sqlalchemy.orm import Session
from typing import Optional, List
from app.models.question_assignment import QuestionAssignment


class AssignmentRepository:
    """Repository for QuestionAssignment queries."""

    def __init__(self, db: Session):
        self.db = db

    def get_by_student_and_session(
        self, student_id: int, session_id: int
    ) -> Optional[QuestionAssignment]:
        return (
            self.db.query(QuestionAssignment)
            .filter(
                QuestionAssignment.student_id == student_id,
                QuestionAssignment.session_id == session_id,
            )
            .first()
        )

    def get_all_for_session(self, session_id: int) -> List[QuestionAssignment]:
        return (
            self.db.query(QuestionAssignment)
            .filter(QuestionAssignment.session_id == session_id)
            .all()
        )

    def create(self, assignment: QuestionAssignment) -> QuestionAssignment:
        self.db.add(assignment)
        self.db.commit()
        self.db.refresh(assignment)
        return assignment

    def create_many(self, assignments: List[QuestionAssignment]) -> List[QuestionAssignment]:
        self.db.add_all(assignments)
        self.db.commit()
        return assignments
