# ============================================================
# File: app/models/student.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: SQLAlchemy ORM model for Student.
#              Represents a registered student in the system.
# ============================================================

from sqlalchemy import Column, Integer, String, Boolean, DateTime, func
from sqlalchemy.orm import relationship
from app.db.base import Base


class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)
    registration_number = Column(String(50), unique=True, nullable=False, index=True)
    name = Column(String(150), nullable=False)
    department = Column(String(100), nullable=False)
    batch = Column(String(20), nullable=False)
    year = Column(String(20), nullable=False, server_default="1st")
    section = Column(String(10), nullable=False)
    enabled = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    assignments = relationship(
        "QuestionAssignment", back_populates="student", cascade="all, delete-orphan"
    )
    heartbeats = relationship(
        "Heartbeat", back_populates="student", cascade="all, delete-orphan"
    )
    run_logs = relationship(
        "RunLog", back_populates="student", cascade="all, delete-orphan"
    )
    submissions = relationship(
        "Submission", back_populates="student", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Student reg={self.registration_number} name={self.name}>"
