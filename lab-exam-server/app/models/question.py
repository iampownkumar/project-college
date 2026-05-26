# ============================================================
# File: app/models/question.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-26
# Location: Tamil Nadu, India
# Description: SQLAlchemy ORM model for Question.
#              Stores programming problem statements and metadata.
# ============================================================

from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from app.db.base import Base


class Question(Base):
    __tablename__ = "questions"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(
        Integer, ForeignKey("exam_sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    language = Column(String(50), nullable=False, default="python")
    title = Column(String(300), nullable=False)
    statement = Column(Text, nullable=False)
    starter_code = Column(Text, nullable=True)
    visible_examples_json = Column(Text, nullable=True)   # JSON array
    constraints_json = Column(Text, nullable=True)        # JSON array
    test_cases_json = Column(Text, nullable=True)         # JSON array of hidden test cases with marks
    metadata_json = Column(Text, nullable=True)           # JSON object
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    session = relationship("ExamSession", back_populates="questions")
    assignments = relationship(
        "QuestionAssignment", back_populates="question", cascade="all, delete-orphan"
    )
    run_logs = relationship(
        "RunLog", back_populates="question", cascade="all, delete-orphan"
    )
    submissions = relationship(
        "Submission", back_populates="question", cascade="all, delete-orphan"
    )
    files = relationship(
        "QuestionFile",
        back_populates="question",
        cascade="all, delete-orphan",
        order_by="QuestionFile.filename",
    )

    def __repr__(self) -> str:
        return f"<Question id={self.id} title={self.title}>"
