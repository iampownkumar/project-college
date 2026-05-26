# ============================================================
# File: app/api/routes/run_logs.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Run log recording route.
#              POST /api/v1/run-log
# ============================================================

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.run_log_service import RunLogService
from app.schemas.run_log import RunLogRequest

router = APIRouter(prefix="/run-log", tags=["Run Logs"])


@router.post(
    "",
    summary="Record a code run log",
    description="Store code execution results sent by the student client after each run.",
)
def record_run_log(
    payload: RunLogRequest,
    db: Session = Depends(get_db),
):
    """
    POST /api/v1/run-log

    Stores one code execution log entry. Multiple logs per student per session
    are expected — each run creates a new record.
    """
    service = RunLogService(db)
    return service.record(payload)
