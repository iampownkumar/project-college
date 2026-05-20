# ============================================================
# File: app/api/routes/questions.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Question query routes.
#              GET /api/v1/question/assigned/{registration_number}
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.question_service import QuestionService
from app.schemas.question import QuestionOut

router = APIRouter(prefix="/question", tags=["Questions"])


@router.get(
    "/assigned/{registration_number}",
    response_model=QuestionOut,
    summary="Get assigned question for student",
    description="Return the full question assigned to this student in the active session.",
)
def get_assigned_question(
    registration_number: str,
    db: Session = Depends(get_db),
) -> QuestionOut:
    """
    GET /api/v1/question/assigned/{registration_number}

    Returns the full question data including statement, starter_code,
    visible examples, and constraints.
    Raises 404 if student has no assigned question or no active session.
    """
    service = QuestionService(db)
    question = service.get_assigned_question(registration_number)
    if not question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No assigned question found for this student.",
        )
    return QuestionOut.model_validate(question)
