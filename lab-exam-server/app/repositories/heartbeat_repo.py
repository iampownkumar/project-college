# ============================================================
# File: app/repositories/heartbeat_repo.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Data-access layer for Heartbeat model.
#              Supports upsert-style updates for live tracking.
# ============================================================

from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime, timezone, timedelta
IST = timezone(timedelta(hours=5, minutes=30))
from app.models.heartbeat import Heartbeat


class HeartbeatRepository:
    """Repository for Heartbeat upsert and queries."""

    def __init__(self, db: Session):
        self.db = db

    def get_by_student_and_session(
        self, student_id: int, session_id: int
    ) -> Optional[Heartbeat]:
        return (
            self.db.query(Heartbeat)
            .filter(
                Heartbeat.student_id == student_id,
                Heartbeat.session_id == session_id,
            )
            .first()
        )

    def get_all_for_session(self, session_id: int) -> List[Heartbeat]:
        return (
            self.db.query(Heartbeat)
            .filter(Heartbeat.session_id == session_id)
            .all()
        )

    def upsert(
        self,
        student_id: int,
        session_id: int,
        machine_name: str,
        machine_ip: str,
        client_state: str,
    ) -> Heartbeat:
        """
        Create or update a heartbeat record for this student/session pair.
        """
        existing = self.get_by_student_and_session(student_id, session_id)
        if existing:
            existing.machine_name = machine_name
            existing.machine_ip = machine_ip
            existing.client_state = client_state
            existing.last_seen_at = datetime.now(IST)
            self.db.commit()
            self.db.refresh(existing)
            return existing
        else:
            hb = Heartbeat(
                student_id=student_id,
                session_id=session_id,
                machine_name=machine_name,
                machine_ip=machine_ip,
                client_state=client_state,
                last_seen_at=datetime.now(IST),
            )
            self.db.add(hb)
            self.db.commit()
            self.db.refresh(hb)
            return hb
