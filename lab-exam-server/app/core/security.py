# ============================================================
# File: app/core/security.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Security dependencies for admin route protection.
#
#   Usage (in any admin route):
#       from app.core.security import verify_admin_key
#
#       @router.get("/...", dependencies=[Depends(verify_admin_key)])
#       def my_route(...): ...
#
#   Header required on every admin request:
#       X-Admin-Key: <value of ADMIN_SECRET_KEY in .env>
#
#   Responses:
#       401  — header missing
#       403  — header present but wrong key
# ============================================================

import secrets
from fastapi import Depends, HTTPException, Security, status
from fastapi.security.api_key import APIKeyHeader

from app.core.config import settings

# FastAPI reads this header from every request automatically
_api_key_header = APIKeyHeader(name="X-Admin-Key", auto_error=False)


def verify_admin_key(api_key: str | None = Security(_api_key_header)) -> str:
    """
    FastAPI dependency — validates the X-Admin-Key header.

    Raises:
        401  if the header is missing entirely.
        403  if the key is present but does not match ADMIN_SECRET_KEY.

    Returns:
        The valid API key string (useful if callers need it).
    """
    if api_key is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="X-Admin-Key header is required for admin endpoints.",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    # Use constant-time comparison to prevent timing attacks
    if not secrets.compare_digest(api_key, settings.admin_secret_key):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid admin key. Access denied.",
        )

    return api_key
