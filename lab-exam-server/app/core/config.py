# ============================================================
# File: app/core/config.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Changelog: Added ADMIN_SECRET_KEY for admin route protection (Phase 4)
# Location: Tamil Nadu, India
# Description: Application configuration using pydantic-settings.
#              Reads from .env file automatically.
# ============================================================

from pydantic_settings import BaseSettings
from pydantic import Field
import os


class Settings(BaseSettings):
    """
    Central application configuration.
    All values are read from environment variables or .env file.
    """

    # Application
    app_name: str = Field(default="Lab Exam Server", alias="APP_NAME")
    app_version: str = Field(default="1.0.0", alias="APP_VERSION")
    debug: bool = Field(default=False, alias="DEBUG")

    # Server
    host: str = Field(default="0.0.0.0", alias="HOST")
    port: int = Field(default=8000, alias="PORT")

    # Database
    database_url: str = Field(
        default="sqlite:///./data/lab_exam.db", alias="DATABASE_URL"
    )

    # Security
    admin_secret_key: str = Field(
        default="changeme-in-production",
        alias="ADMIN_SECRET_KEY",
    )

    # Paths
    seed_data_dir: str = Field(default="./data/seed", alias="SEED_DATA_DIR")

    # Logging
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")
    log_file: str = Field(default="./logs/server.log", alias="LOG_FILE")

    model_config = {"env_file": ".env", "populate_by_name": True}


# Singleton instance used across the application
settings = Settings()
