#!/usr/bin/env python3
# ============================================================
# File: tests/test_health.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Basic health check test using FastAPI TestClient.
#              Validates the /api/v1/health endpoint.
# ============================================================

import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_check():
    """GET /api/v1/health should return status=ok."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "server_time" in data
    assert "version" in data
    print("[test] Health check passed.")


def test_docs_available():
    """GET /docs should return 200 (Swagger UI)."""
    response = client.get("/docs")
    assert response.status_code == 200
    print("[test] Docs endpoint accessible.")


if __name__ == "__main__":
    test_health_check()
    test_docs_available()
    print("[test] All basic tests passed.")
