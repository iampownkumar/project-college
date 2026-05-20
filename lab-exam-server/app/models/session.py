# ============================================================
# File: app/models/session.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: SQLAlchemy ORM model for ExamSession.
#              Represents a lab exam session managed by faculty.
# ============================================================

from sqlalchemy import Column, Integer, String, DateTime, Enum, func
from sqlalchemy.orm import relationship
from app.db.base import Base
import enum


class SessionStatus(str, enum.Enum):
    draft = "draft"
    active = "active"
    closed = "closed"


class ExamSession(Base):
    __tablename__ = "exam_sessions"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    department = Column(String(100), nullable=False)
    language = Column(String(50), nullable=False, default="python")
    start_time = Column(DateTime(timezone=True), nullable=True)
    end_time = Column(DateTime(timezone=True), nullable=True)
    duration_minutes = Column(Integer, nullable=False, default=60)
    status = Column(
        Enum(SessionStatus, name="session_status"),
        nullable=False,
        default=SessionStatus.draft,
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    questions = relationship(
        "Question", back_populates="session", cascade="all, delete-orphan"
    )
    assignments = relationship(
        "QuestionAssignment", back_populates="session", cascade="all, delete-orphan"
    )
    heartbeats = relationship(
        "Heartbeat", back_populates="session", cascade="all, delete-orphan"
    )
    run_logs = relationship(
        "RunLog", back_populates="session", cascade="all, delete-orphan"
    )
    submissions = relationship(
        "Submission", back_populates="session", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<ExamSession id={self.id} title={self.title} status={self.status}>"
