# ============================================================
# File: app/api/routes/admin.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-26
# Changelog: Phase 4 — all routes protected by X-Admin-Key header
# Location: Tamil Nadu, India
# Description: Admin/faculty API routes.
#
#   Sessions:
#     POST   /api/v1/admin/session
#     GET    /api/v1/admin/sessions
#     GET    /api/v1/admin/session/{id}
#     PUT    /api/v1/admin/session/{id}/status
#
#   Questions:
#     POST   /api/v1/admin/question
#     GET    /api/v1/admin/session/{id}/questions
#     DELETE /api/v1/admin/question/{id}
#     POST   /api/v1/admin/question/{id}/files        — upload sandbox file
#     DELETE /api/v1/admin/question/{id}/files/{name} — remove sandbox file
#     GET    /api/v1/admin/question/{id}/files        — list sandbox files
#
#   Students:
#     POST   /api/v1/admin/student
#     POST   /api/v1/admin/students/bulk
#     GET    /api/v1/admin/students
#     PUT    /api/v1/admin/student/{reg}/enable
#     PUT    /api/v1/admin/student/{reg}/disable
#     DELETE /api/v1/admin/student/{reg}
#
#   Assignments:
#     POST   /api/v1/admin/assignment
#     POST   /api/v1/admin/assignment/bulk
#     GET    /api/v1/admin/session/{id}/assignments
#
#   Monitor:
#     GET    /api/v1/admin/session/{id}/monitor
#
#   Submissions:
#     GET    /api/v1/admin/session/{id}/submissions
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.services.admin_service import AdminService
from app.services.file_service import FileService
from app.schemas.common import SuccessResponse, ErrorResponse
from app.schemas.question import AttachedFileOut
from app.schemas.admin import (
    SessionCreateRequest,
    SessionStatusUpdateRequest,
    SessionAdminOut,
    QuestionCreateRequest,
    QuestionAdminOut,
    StudentCreateRequest,
    StudentBulkRequest,
    StudentBulkResult,
    StudentAdminOut,
    AssignmentCreateRequest,
    BulkAssignRequest,
    AssignmentAdminOut,
    MonitorResponse,
    SubmissionAdminOut,
    DepartmentCreateRequest,
    DepartmentOut,
)

router = APIRouter(
    prefix="/admin",
    tags=["Admin"],
)


# ── Departments ──────────────────────────────────────────────

@router.post(
    "/department",
    response_model=SuccessResponse,
    summary="Create a new department",
)
def create_department(
    payload: DepartmentCreateRequest,
    db: Session = Depends(get_db),
):
    service = AdminService(db)
    return service.create_department(payload)

@router.get(
    "/departments",
    response_model=List[DepartmentOut],
    summary="List all departments",
)
def get_departments(
    db: Session = Depends(get_db),
):
    service = AdminService(db)
    return service.get_all_departments()

@router.delete(
    "/department/{dept_id}",
    response_model=SuccessResponse,
    summary="Delete a department",
)
def delete_department(
    dept_id: int,
    db: Session = Depends(get_db),
):
    service = AdminService(db)
    return service.delete_department(dept_id)

# ── Sessions ─────────────────────────────────────────────────

@router.post(
    "/session",
    response_model=SessionAdminOut,
    summary="Create exam session",
    description="Create a new exam session in draft status.",
)
def create_session(
    payload: SessionCreateRequest,
    db: Session = Depends(get_db),
) -> SessionAdminOut:
    """POST /api/v1/admin/session"""
    service = AdminService(db)
    return service.create_session(payload)


@router.get(
    "/sessions",
    response_model=List[SessionAdminOut],
    summary="List all sessions",
    description="Return all exam sessions with question and student counts.",
)
def list_sessions(db: Session = Depends(get_db)) -> List[SessionAdminOut]:
    """GET /api/v1/admin/sessions"""
    service = AdminService(db)
    return service.list_sessions()


@router.get(
    "/session/{session_id}",
    response_model=SessionAdminOut,
    summary="Get session details",
    description="Return details of one session by ID.",
)
def get_session(
    session_id: int,
    db: Session = Depends(get_db),
) -> SessionAdminOut:
    """GET /api/v1/admin/session/{session_id}"""
    service = AdminService(db)
    result = service.get_session(session_id)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Session id={session_id} not found.",
        )
    return result


@router.put(
    "/session/{session_id}/status",
    summary="Update session status",
    description=(
        "Change session status. Valid values: draft, active, closed. "
        "Activating a session will auto-close any currently active session."
    ),
)
def update_session_status(
    session_id: int,
    payload: SessionStatusUpdateRequest,
    db: Session = Depends(get_db),
):
    """PUT /api/v1/admin/session/{session_id}/status"""
    service = AdminService(db)
    return service.update_session_status(session_id, payload.status)


@router.delete(
    "/session/{session_id}",
    summary="Delete a session",
    description="Permanently delete an exam session and all its related questions and data.",
)
def delete_session(
    session_id: int,
    db: Session = Depends(get_db),
):
    """DELETE /api/v1/admin/session/{session_id}"""
    service = AdminService(db)
    try:
        return service.delete_session(session_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


# ── Questions ─────────────────────────────────────────────────

from app.schemas.admin import QuestionBulkRequest, QuestionBulkResult

@router.post(
    "/questions/bulk",
    response_model=QuestionBulkResult,
    summary="Bulk upload questions",
    description="Upload a list of questions for a session from JSON.",
)
def bulk_upload_questions(
    payload: QuestionBulkRequest,
    db: Session = Depends(get_db),
) -> QuestionBulkResult:
    """POST /api/v1/admin/questions/bulk"""
    service = AdminService(db)
    return service.bulk_upload_questions(payload)

@router.post(
    "/question",
    response_model=QuestionAdminOut,
    summary="Create question",
    description="Add a new question to an exam session.",
)
def create_question(
    payload: QuestionCreateRequest,
    db: Session = Depends(get_db),
) -> QuestionAdminOut:
    """POST /api/v1/admin/question"""
    service = AdminService(db)
    try:
        return service.create_question(payload)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get(
    "/session/{session_id}/questions",
    response_model=List[QuestionAdminOut],
    summary="List questions for session",
    description="Return all questions assigned to a session.",
)
def list_questions(
    session_id: int,
    db: Session = Depends(get_db),
) -> List[QuestionAdminOut]:
    """GET /api/v1/admin/session/{session_id}/questions"""
    service = AdminService(db)
    return service.list_questions(session_id)


@router.delete(
    "/question/{question_id}",
    summary="Delete a question",
    description="Permanently delete a question.",
)
def delete_question(
    question_id: int,
    db: Session = Depends(get_db),
):
    """DELETE /api/v1/admin/question/{question_id}"""
    service = AdminService(db)
    try:
        return service.delete_question(question_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


# ── Question Sandbox Files ────────────────────────────────────

@router.post(
    "/question/{question_id}/files",
    response_model=AttachedFileOut,
    summary="Upload a sandbox file to a question",
    description=(
        "Attach a file (CSV, image, JSON, etc.) to a question so students "
        "can access it inside the exam client without alt-tabbing. "
        f"Max 5 files per question, 10 MB each."
    ),
)
async def upload_question_file(
    question_id: int,
    file: UploadFile = File(..., description="File to attach to the question"),
    db: Session = Depends(get_db),
) -> AttachedFileOut:
    """POST /api/v1/admin/question/{question_id}/files"""
    service = FileService(db)
    record = await service.upload_file(question_id, file)
    return AttachedFileOut.model_validate(record)


@router.delete(
    "/question/{question_id}/files/{filename}",
    response_model=SuccessResponse,
    summary="Remove a sandbox file from a question",
    description="Delete a file from both disk and the database.",
)
def delete_question_file(
    question_id: int,
    filename: str,
    db: Session = Depends(get_db),
) -> SuccessResponse:
    """DELETE /api/v1/admin/question/{question_id}/files/{filename}"""
    service = FileService(db)
    result = service.delete_file(question_id, filename)
    return SuccessResponse(message=result["message"])


@router.get(
    "/question/{question_id}/files",
    response_model=List[AttachedFileOut],
    summary="List sandbox files for a question (admin view)",
    description="Return all files attached to a question, sorted by filename.",
)
def list_question_files_admin(
    question_id: int,
    db: Session = Depends(get_db),
) -> List[AttachedFileOut]:
    """GET /api/v1/admin/question/{question_id}/files"""
    service = FileService(db)
    return service.list_files(question_id)


# ── Students ──────────────────────────────────────────────────

@router.post(
    "/student",
    summary="Add single student",
    description="Add one student to the system.",
)
def create_student(
    payload: StudentCreateRequest,
    db: Session = Depends(get_db),
):
    """POST /api/v1/admin/student"""
    service = AdminService(db)
    return service.create_student(payload)


@router.post(
    "/students/bulk",
    response_model=StudentBulkResult,
    summary="Bulk upload students",
    description=(
        "Upload a list of students. Existing registration numbers are skipped. "
        "Returns a summary with created/skipped counts and any errors."
    ),
)
def bulk_upload_students(
    payload: StudentBulkRequest,
    db: Session = Depends(get_db),
) -> StudentBulkResult:
    """POST /api/v1/admin/students/bulk"""
    service = AdminService(db)
    return service.bulk_upload_students(payload)


@router.get(
    "/students",
    response_model=List[StudentAdminOut],
    summary="List all students",
    description="Return all registered students (no pagination cap).",
)
def list_students(
    db: Session = Depends(get_db),
) -> List[StudentAdminOut]:
    """GET /api/v1/admin/students"""
    service = AdminService(db)
    return service.list_students_all()


@router.put(
    "/student/{registration_number}/enable",
    summary="Enable student",
    description="Enable a disabled student account.",
)
def enable_student(
    registration_number: str,
    db: Session = Depends(get_db),
):
    """PUT /api/v1/admin/student/{registration_number}/enable"""
    service = AdminService(db)
    return service.toggle_student(registration_number, enabled=True)


@router.put(
    "/student/{registration_number}/disable",
    summary="Disable student",
    description="Disable a student account so they cannot log in.",
)
def disable_student(
    registration_number: str,
    db: Session = Depends(get_db),
):
    """PUT /api/v1/admin/student/{registration_number}/disable"""
    service = AdminService(db)
    return service.toggle_student(registration_number, enabled=False)

@router.delete(
    "/student/{registration_number}",
    summary="Delete student",
    description="Permanently delete a student and all their data.",
)
def delete_student(
    registration_number: str,
    db: Session = Depends(get_db),
):
    """DELETE /api/v1/admin/student/{registration_number}"""
    service = AdminService(db)
    return service.delete_student(registration_number)


@router.delete(
    "/students/all",
    response_model=SuccessResponse,
    summary="Delete ALL students",
    description="Permanently delete every student record. Use with caution.",
)
def delete_all_students(
    db: Session = Depends(get_db),
):
    """DELETE /api/v1/admin/students/all"""
    service = AdminService(db)
    return service.delete_all_students()


# ── Assignments ───────────────────────────────────────────────

@router.post(
    "/assignment",
    summary="Assign question to student",
    description=(
        "Manually assign a specific question to a student in a session. "
        "Replaces any existing assignment for that student in this session."
    ),
)
def assign_question(
    payload: AssignmentCreateRequest,
    db: Session = Depends(get_db),
):
    """POST /api/v1/admin/assignment"""
    service = AdminService(db)
    return service.assign_question(payload)


@router.post(
    "/assignment/bulk",
    summary="Bulk assign questions (round-robin)",
    description=(
        "Automatically assign questions to all unassigned students in a session "
        "using round-robin distribution. Already-assigned students are skipped."
    ),
)
def bulk_assign(
    payload: BulkAssignRequest,
    db: Session = Depends(get_db),
):
    """POST /api/v1/admin/assignment/bulk"""
    service = AdminService(db)
    return service.bulk_assign_questions(payload)


@router.get(
    "/session/{session_id}/assignments",
    response_model=List[AssignmentAdminOut],
    summary="List assignments for session",
    description="Return all question assignments for a session with student and question details.",
)
def list_assignments(
    session_id: int,
    db: Session = Depends(get_db),
) -> List[AssignmentAdminOut]:
    """GET /api/v1/admin/session/{session_id}/assignments"""
    service = AdminService(db)
    return service.list_assignments(session_id)


# ── Live Monitor ──────────────────────────────────────────────

@router.get(
    "/session/{session_id}/monitor",
    response_model=MonitorResponse,
    summary="Live session monitor",
    description=(
        "Real-time snapshot of all students in a session. "
        "Shows online status (heartbeat within 90s), run count, and submission state."
    ),
)
def live_monitor(
    session_id: int,
    db: Session = Depends(get_db),
) -> MonitorResponse:
    """GET /api/v1/admin/session/{session_id}/monitor"""
    service = AdminService(db)
    result = service.get_live_monitor(session_id)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Session id={session_id} not found.",
        )
    return result


# ── Submissions ───────────────────────────────────────────────

@router.get(
    "/session/{session_id}/submissions",
    response_model=List[SubmissionAdminOut],
    summary="List submissions for session",
    description="Return all final submissions for a session with student and question details.",
)
def list_submissions(
    session_id: int,
    db: Session = Depends(get_db),
) -> List[SubmissionAdminOut]:
    """GET /api/v1/admin/session/{session_id}/submissions"""
    service = AdminService(db)
    return service.list_submissions(session_id)
