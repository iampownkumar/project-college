# ============================================================
# File: app/repositories/submission_repo.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Data-access layer for Submission model.
#              Supports upsert-style so re-submission replaces existing.
# ============================================================

from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime, timezone, timedelta
IST = timezone(timedelta(hours=5, minutes=30))
from app.models.submission import Submission


class SubmissionRepository:
    """Repository for Submission upsert and queries."""

    def __init__(self, db: Session):
        self.db = db

    def get_by_student_and_session(
        self, student_id: int, session_id: int
    ) -> Optional[Submission]:
        return (
            self.db.query(Submission)
            .filter(
                Submission.student_id == student_id,
                Submission.session_id == session_id,
            )
            .first()
        )

    def upsert(
        self,
        student_id: int,
        session_id: int,
        question_id: int,
        source_code: Optional[str],
        stdout: Optional[str],
        stderr: Optional[str],
        exit_code: Optional[int],
        submitted_at: Optional[datetime],
        submission_type: str = "normal",
    ) -> Submission:
        """
        Create or replace a submission for this student/session pair.
        On resubmission: increments submit_count and marks type='resubmission'.
        """
        existing = self.get_by_student_and_session(student_id, session_id)
        ts = submitted_at or datetime.now(IST)

        if existing:
            existing.question_id = question_id
            existing.source_code = source_code
            existing.stdout = stdout
            existing.stderr = stderr
            existing.exit_code = exit_code
            existing.submitted_at = ts
            existing.final_status = "submitted"
            existing.submit_count = (existing.submit_count or 1) + 1
            # If student manually re-submits after any auto-submit, mark resubmission
            existing.submission_type = "resubmission" if submission_type == "normal" else submission_type
            self.db.commit()
            self.db.refresh(existing)
            return existing
        else:
            sub = Submission(
                student_id=student_id,
                session_id=session_id,
                question_id=question_id,
                source_code=source_code,
                stdout=stdout,
                stderr=stderr,
                exit_code=exit_code,
                submitted_at=ts,
                final_status="submitted",
                submission_type=submission_type,
                submit_count=1,
            )
            self.db.add(sub)
            self.db.commit()
            self.db.refresh(sub)
            return sub
