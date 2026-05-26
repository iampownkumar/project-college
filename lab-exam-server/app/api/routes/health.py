# ============================================================
# File: app/api/routes/health.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Health check endpoint.
#              Returns server status, time, and version.
# ============================================================

from fastapi import APIRouter
from datetime import datetime, timezone, timedelta
from app.schemas.common import HealthResponse
from app.core.config import settings

IST = timezone(timedelta(hours=5, minutes=30))

router = APIRouter(tags=["Health"])


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health check",
    description="Returns current server status, IST timestamp, and application version.",
)
def health_check() -> HealthResponse:
    """
    GET /api/v1/health

    Returns:
        status: "ok"
        server_time: current IST ISO timestamp
        version: application version string
    """
    return HealthResponse(
        status="ok",
        server_time=datetime.now(IST).isoformat(),
        version=settings.app_version,
    )
