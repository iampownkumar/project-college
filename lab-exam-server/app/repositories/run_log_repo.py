# ============================================================
# File: app/repositories/run_log_repo.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Data-access layer for RunLog model.
# ============================================================

from sqlalchemy.orm import Session
from typing import Optional, List
from app.models.run_log import RunLog


class RunLogRepository:
    """Repository for RunLog creation and queries."""

    def __init__(self, db: Session):
        self.db = db

    def create(self, run_log: RunLog) -> RunLog:
        self.db.add(run_log)
        self.db.commit()
        self.db.refresh(run_log)
        return run_log

    def get_latest_for_student_session(
        self, student_id: int, session_id: int
    ) -> Optional[RunLog]:
        return (
            self.db.query(RunLog)
            .filter(
                RunLog.student_id == student_id,
                RunLog.session_id == session_id,
            )
            .order_by(RunLog.created_at.desc())
            .first()
        )

    def get_all_for_student_session(
        self, student_id: int, session_id: int
    ) -> List[RunLog]:
        return (
            self.db.query(RunLog)
            .filter(
                RunLog.student_id == student_id,
                RunLog.session_id == session_id,
            )
            .order_by(RunLog.created_at.desc())
            .all()
        )
