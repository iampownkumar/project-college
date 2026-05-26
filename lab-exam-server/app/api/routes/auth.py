# ============================================================
# File: app/api/routes/auth.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Student authentication routes.
#              POST /api/v1/auth/login
# ============================================================

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.auth_service import AuthService
from app.schemas.auth import LoginRequest, LoginResponse

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post(
    "/login",
    response_model=LoginResponse,
    summary="Student login",
    description=(
        "Verify a student by registration number. "
        "Returns session and question assignment details if valid."
    ),
)
def student_login(
    payload: LoginRequest,
    db: Session = Depends(get_db),
) -> LoginResponse:
    """
    POST /api/v1/auth/login

    Validates:
    - Student exists and is enabled
    - There is an active exam session
    - Student has a question assigned for that session

    Returns student, session, and assignment details on success.
    """
    service = AuthService(db)
    return service.login(payload)


# ── Admin / Staff Login ──────────────────────────────────────

from pydantic import BaseModel

class AdminLoginRequest(BaseModel):
    staff_code: str
    password: str

class AdminLoginResponse(BaseModel):
    success: bool
    message: str
    admin_key: str = ""
    staff_code: str = ""

# Hardcoded staff credentials for now (CSL42 / CSL42)
# Will be replaced with DB-backed role management later.
_STAFF_CREDENTIALS = {
    "CSL42": "CSL42",
}

@router.post(
    "/admin/login",
    response_model=AdminLoginResponse,
    summary="Staff/Admin login",
    description="Authenticate faculty with staff code and password. Returns admin key on success.",
)
def admin_login(payload: AdminLoginRequest):
    """POST /api/v1/auth/admin/login"""
    code = payload.staff_code.strip().upper()
    expected_pwd = _STAFF_CREDENTIALS.get(code)
    if not expected_pwd or payload.password.strip() != expected_pwd:
        return AdminLoginResponse(
            success=False,
            message="Invalid staff code or password.",
        )
    # Return the admin key from config so the dashboard can use it
    from app.core.config import settings
    return AdminLoginResponse(
        success=True,
        message=f"Welcome, {code}! Session valid for 4 hours.",
        admin_key=settings.admin_secret_key,
        staff_code=code,
    )
