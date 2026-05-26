# ============================================================
# File: app/models/question_file.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-26
# Last Updated: 2026-05-26
# Location: Tamil Nadu, India
# Description: SQLAlchemy ORM model for QuestionFile.
#              Each row represents one file attached to a question
#              by faculty (CSV, image, JSON, text, etc.).
#              Files are stored on disk under:
#                data/uploads/questions/<question_id>/<original_filename>
# ============================================================

from sqlalchemy import Column, Integer, String, BigInteger, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from app.db.base import Base


class QuestionFile(Base):
    __tablename__ = "question_files"

    id = Column(Integer, primary_key=True, index=True)

    # The question this file belongs to
    question_id = Column(
        Integer,
        ForeignKey("questions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Original filename as uploaded by faculty (e.g. "data.csv")
    filename = Column(String(255), nullable=False)

    # MIME type detected at upload time (e.g. "text/csv", "image/png")
    mime_type = Column(String(100), nullable=False, default="application/octet-stream")

    # Size in bytes — stored so the client can show it without downloading
    size_bytes = Column(BigInteger, nullable=False, default=0)

    # Absolute path on the server's filesystem where the file is stored
    file_path = Column(String(500), nullable=False)

    uploaded_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    question = relationship("Question", back_populates="files")

    def __repr__(self) -> str:
        return f"<QuestionFile id={self.id} question_id={self.question_id} filename={self.filename}>"
