# ============================================================
# File: app/api/routes/sessions.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Session query routes.
#              GET /api/v1/session/current/{registration_number}
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.session_service import SessionService
from app.schemas.session import SessionOut

router = APIRouter(prefix="/session", tags=["Sessions"])


@router.get(
    "/current/{registration_number}",
    response_model=SessionOut,
    summary="Get current session for student",
    description="Return the active exam session for a student, if one exists and they have an assignment.",
)
def get_current_session(
    registration_number: str,
    db: Session = Depends(get_db),
) -> SessionOut:
    """
    GET /api/v1/session/current/{registration_number}

    Returns the active session details for the given student.
    Raises 404 if no active session or student not found.
    """
    service = SessionService(db)
    session = service.get_current_session_for_student(registration_number)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active session found for this student.",
        )
    return SessionOut.model_validate(session)
