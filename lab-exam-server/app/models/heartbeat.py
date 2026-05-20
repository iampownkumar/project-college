# ============================================================
# File: app/models/heartbeat.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: SQLAlchemy ORM model for Heartbeat.
#              Tracks the last known live status of each student client.
#              Upsert-style: one record per student per session.
# ============================================================


# pyrefly: ignore [missing-import]
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func, UniqueConstraint

# pyrefly: ignore [missing-import]
from sqlalchemy.orm import relationship
from app.db.base import Base


class Heartbeat(Base):
    __tablename__ = "heartbeats"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(
        Integer, ForeignKey("exam_sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id = Column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True
    )
    machine_name = Column(String(100), nullable=True)
    machine_ip = Column(String(50), nullable=True)
    client_state = Column(String(50), nullable=True, default="idle")
    last_seen_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Unique: one live heartbeat record per student per session
    __table_args__ = (
        UniqueConstraint("session_id", "student_id", name="uq_heartbeat_session_student"),
    )

    # Relationships
    session = relationship("ExamSession", back_populates="heartbeats")
    student = relationship("Student", back_populates="heartbeats")

    def __repr__(self) -> str:
        return (
            f"<Heartbeat session={self.session_id} student={self.student_id} "
            f"state={self.client_state} last_seen={self.last_seen_at}>"
        )
