# ============================================================
# File: app/schemas/common.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Shared Pydantic response schemas used across routes.
# ============================================================

from pydantic import BaseModel
from typing import Any, Optional


class SuccessResponse(BaseModel):
    """Generic success response wrapper."""
    success: bool = True
    message: str = "OK"
    data: Optional[Any] = None


class ErrorResponse(BaseModel):
    """Generic error response wrapper."""
    success: bool = False
    message: str
    detail: Optional[Any] = None


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    server_time: str
    version: str
