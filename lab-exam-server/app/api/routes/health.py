# ============================================================
# File: app/api/routes/health.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Health check endpoint.
#              Returns server status, time, and version.
# ============================================================

from fastapi import APIRouter
from datetime import datetime, timezone
from app.schemas.common import HealthResponse
from app.core.config import settings

router = APIRouter(tags=["Health"])


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health check",
    description="Returns current server status, UTC timestamp, and application version.",
)
def health_check() -> HealthResponse:
    """
    GET /api/v1/health

    Returns:
        status: "ok"
        server_time: current UTC ISO timestamp
        version: application version string
    """
    return HealthResponse(
        status="ok",
        server_time=datetime.now(timezone.utc).isoformat(),
        version=settings.app_version,
    )
