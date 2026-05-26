# ============================================================
# File: app/models/question_assignment.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: SQLAlchemy ORM model for QuestionAssignment.
#              Maps a student to a specific question within a session.
# ============================================================

from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint, func
from sqlalchemy.orm import relationship
from app.db.base import Base


class QuestionAssignment(Base):
    __tablename__ = "question_assignments"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(
        Integer, ForeignKey("exam_sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id = Column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True
    )
    question_id = Column(
        Integer, ForeignKey("questions.id", ondelete="CASCADE"), nullable=False
    )
    assigned_at = Column(DateTime(timezone=True), server_default=func.now())

    # Unique constraint: one student has at most one question per session
    __table_args__ = (
        UniqueConstraint("session_id", "student_id", name="uq_session_student"),
    )

    # Relationships
    session = relationship("ExamSession", back_populates="assignments")
    student = relationship("Student", back_populates="assignments")
    question = relationship("Question", back_populates="assignments")

    def __repr__(self) -> str:
        return (
            f"<QuestionAssignment session={self.session_id} "
            f"student={self.student_id} question={self.question_id}>"
        )
