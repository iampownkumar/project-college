# ============================================================
# File: app/api/routes/heartbeat.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Heartbeat recording route.
#              POST /api/v1/heartbeat
# ============================================================

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.heartbeat_service import HeartbeatService
from app.schemas.heartbeat import HeartbeatRequest
from app.schemas.common import SuccessResponse, ErrorResponse

router = APIRouter(prefix="/heartbeat", tags=["Heartbeat"])


@router.post(
    "",
    summary="Record student heartbeat",
    description="Receive a heartbeat ping from a student client to track live status.",
)
def record_heartbeat(
    payload: HeartbeatRequest,
    db: Session = Depends(get_db),
):
    """
    POST /api/v1/heartbeat

    Upserts a heartbeat record for the student in the given session.
    Returns success or error.
    """
    service = HeartbeatService(db)
    return service.record(payload)
