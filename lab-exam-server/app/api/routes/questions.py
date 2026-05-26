# ============================================================
# File: app/api/routes/questions.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-26
# Location: Tamil Nadu, India
# Description: Question query routes.
#              GET /api/v1/question/assigned/{registration_number}
#              GET /api/v1/question/{id}/files           — list attached files
#              GET /api/v1/question/{id}/files/{filename} — download a file
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.services.question_service import QuestionService
from app.services.file_service import FileService
from app.schemas.question import QuestionOut, AttachedFileOut

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


@router.get(
    "/{question_id}/files",
    response_model=List[AttachedFileOut],
    summary="List sandbox files for a question",
    description=(
        "Return metadata for all files attached to a question. "
        "Called by the client after question load to populate the Files tab."
    ),
)
def list_question_files(
    question_id: int,
    db: Session = Depends(get_db),
) -> List[AttachedFileOut]:
    """GET /api/v1/question/{question_id}/files"""
    service = FileService(db)
    return service.list_files(question_id)


@router.get(
    "/{question_id}/files/{filename}",
    summary="Download a sandbox file",
    description=(
        "Return the raw bytes of a specific file attached to a question. "
        "The client saves this to the local sandbox directory."
    ),
)
def download_question_file(
    question_id: int,
    filename: str,
    db: Session = Depends(get_db),
) -> Response:
    """GET /api/v1/question/{question_id}/files/{filename}"""
    service = FileService(db)
    data, mime_type = service.get_file_bytes(question_id, filename)
    return Response(
        content=data,
        media_type=mime_type,
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
