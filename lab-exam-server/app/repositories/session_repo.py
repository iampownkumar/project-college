# ============================================================
# File: app/repositories/session_repo.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Data-access layer for ExamSession model.
# ============================================================

from sqlalchemy.orm import Session as DBSession
from typing import Optional, List
from app.models.session import ExamSession, SessionStatus


class SessionRepository:
    """Repository for ExamSession CRUD and status queries."""

    def __init__(self, db: DBSession):
        self.db = db

    def get_by_id(self, session_id: int) -> Optional[ExamSession]:
        return self.db.query(ExamSession).filter(ExamSession.id == session_id).first()

    def get_active(self) -> Optional[ExamSession]:
        """Return the first active session (MVP assumes at most one active).
        If the session's end_time has passed it is automatically closed here
        so callers never see a stale 'active' session."""
        from datetime import datetime, timezone, timedelta
        IST = timezone(timedelta(hours=5, minutes=30))
        session = (
            self.db.query(ExamSession)
            .filter(ExamSession.status == SessionStatus.active)
            .first()
        )
        if session and session.end_time:
            now = datetime.now(IST)
            # Normalise to IST if end_time is naive (stored without tz)
            end = session.end_time
            if end.tzinfo is None:
                end = end.replace(tzinfo=IST)
            if now >= end:
                session.status = SessionStatus.closed
                self.db.commit()
                self.db.refresh(session)
                return None   # Caller sees no active session
        return session

    def get_all(self) -> List[ExamSession]:
        return self.db.query(ExamSession).all()

    def create(self, session: ExamSession) -> ExamSession:
        self.db.add(session)
        self.db.commit()
        self.db.refresh(session)
        return session

    def update(self, session: ExamSession) -> ExamSession:
        self.db.commit()
        self.db.refresh(session)
        return session
