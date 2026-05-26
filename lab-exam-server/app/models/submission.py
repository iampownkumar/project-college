# ============================================================
# File: app/models/submission.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: SQLAlchemy ORM model for Submission.
#              Stores the final code submission from each student.
#              One record per student per session (upsert on re-submit).
# ============================================================

from sqlalchemy import (
    Column, Integer, String, Text, ForeignKey, DateTime, func, UniqueConstraint
)
from sqlalchemy.orm import relationship
from app.db.base import Base


class Submission(Base):
    __tablename__ = "submissions"

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
    source_code = Column(Text, nullable=True)
    stdout = Column(Text, nullable=True)
    stderr = Column(Text, nullable=True)
    exit_code = Column(Integer, nullable=True)
    submitted_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), nullable=True)
    final_status = Column(String(50), nullable=True, default="submitted")
    # How the submission was triggered:
    #   normal        - student clicked Submit
    #   auto_tab_switch - 3-strike lock forced auto-submit
    #   auto_timer    - session timer expired, auto-submit
    #   resubmission  - student submitted again after first submit
    submission_type = Column(String(30), nullable=True, default="normal")
    submit_count = Column(Integer, nullable=False, default=1)  # incremented on resubmit
    score_json = Column(Text, nullable=True)  # Reserved for future scoring

    # Unique constraint: one submission per student per session
    __table_args__ = (
        UniqueConstraint("session_id", "student_id", name="uq_submission_session_student"),
    )

    # Relationships
    session = relationship("ExamSession", back_populates="submissions")
    student = relationship("Student", back_populates="submissions")
    question = relationship("Question", back_populates="submissions")

    def __repr__(self) -> str:
        return (
            f"<Submission id={self.id} student={self.student_id} "
            f"status={self.final_status}>"
        )
