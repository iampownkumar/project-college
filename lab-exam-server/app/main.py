# ============================================================
# File: app/main.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-26
# Changelog: Added admin API router registration
# Location: Tamil Nadu, India
# Description: FastAPI application factory.
#              Registers all routers under /api/v1.
#              Creates database tables on startup.
#              Configures logging on startup.
# ============================================================

import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os

from app.core.config import settings
from app.core.logging import setup_logging
from app.core.database import engine

# Import all models so SQLAlchemy can see them before table creation
import app.models  # noqa: F401
from app.models.department import Department
from app.db.base import Base
from app.services.file_service import ensure_uploads_root

# Import route modules
from app.api.routes import health, auth, sessions, questions, heartbeat, run_logs, submissions, admin

logger = logging.getLogger(__name__)

API_PREFIX = "/api/v1"


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan handler.
    Runs setup before the server starts accepting requests.
    """
    # Initialize logging first
    setup_logging()

    # Create all database tables if they do not exist
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables verified / created.")

    # Ensure the file upload directory exists
    ensure_uploads_root()

    logger.info(
        f"Lab Exam Server v{settings.app_version} starting on "
        f"{settings.host}:{settings.port}"
    )

    yield  # Server is running

    logger.info("Lab Exam Server shutting down.")


def create_app() -> FastAPI:
    """
    Build and configure the FastAPI application.
    """
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=(
            "Local Lab Exam System – Coordinator Server. "
            "Manages students, sessions, questions, heartbeats, "
            "run logs, and final submissions over LAN. "
            "Admin API available under /api/v1/admin for faculty use."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # Allow all origins for LAN-only deployment
    # Tighten this for production if needed
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Register all routers
    app.include_router(health.router, prefix=API_PREFIX)
    app.include_router(auth.router, prefix=API_PREFIX)
    app.include_router(sessions.router, prefix=API_PREFIX)
    app.include_router(questions.router, prefix=API_PREFIX)
    app.include_router(heartbeat.router, prefix=API_PREFIX)
    app.include_router(run_logs.router, prefix=API_PREFIX)
    app.include_router(submissions.router, prefix=API_PREFIX)
    app.include_router(admin.router, prefix=API_PREFIX)

    # Serve static assets
    static_dir = os.path.join(os.path.dirname(__file__), "static")
    if os.path.isdir(static_dir):
        app.mount("/static", StaticFiles(directory=static_dir), name="static")

    # Admin dashboard route
    @app.get("/dashboard", include_in_schema=False)
    def dashboard():
        return FileResponse(os.path.join(static_dir, "dashboard.html"))

    return app


# Application instance used by uvicorn
app = create_app()
