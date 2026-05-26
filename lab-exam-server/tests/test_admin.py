#!/usr/bin/env python3
# ============================================================
# File: tests/test_admin.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Changelog: Phase 4 — all requests now include X-Admin-Key header.
#             Added 3 security rejection tests (401/403).
# Location: Tamil Nadu, India
# Description: Integration tests for all admin API endpoints.
#              Uses a file-based SQLite test DB for isolation.
# ============================================================

import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.core.database import get_db
from app.db.base import Base

# ── Isolated test DB ─────────────────────────────────────────
TEST_DB = "./data/test_admin.db"
test_engine = create_engine(TEST_DB.replace("./", "sqlite:///./"), connect_args={"check_same_thread": False})
TestSessionLocal = sessionmaker(bind=test_engine, autocommit=False, autoflush=False, expire_on_commit=False)


def override_get_db():
    db = TestSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

# Fresh DB for admin tests
Base.metadata.drop_all(bind=test_engine)
Base.metadata.create_all(bind=test_engine)

client = TestClient(app, raise_server_exceptions=True)

# ── Admin key header used by all tests ───────────────────────
VALID_KEY = {"X-Admin-Key": "exam@lab2026"}
WRONG_KEY  = {"X-Admin-Key": "wrong-key"}


# ═══════════════════════════════════════════════════════════════
# Phase 4 — Security Rejection Tests (must come first)
# ═══════════════════════════════════════════════════════════════

def test_admin_missing_key_returns_401():
    """Admin endpoint without key should return 401 Unauthorized."""
    response = client.get("/api/v1/admin/sessions")
    assert response.status_code == 401, f"Expected 401, got {response.status_code}"
    data = response.json()
    assert "X-Admin-Key" in data["detail"]
    print("[test] ✅ Missing key → 401")


def test_admin_wrong_key_returns_403():
    """Admin endpoint with wrong key should return 403 Forbidden."""
    response = client.get("/api/v1/admin/sessions", headers=WRONG_KEY)
    assert response.status_code == 403, f"Expected 403, got {response.status_code}"
    data = response.json()
    assert "denied" in data["detail"].lower()
    print("[test] ✅ Wrong key → 403")


def test_admin_valid_key_passes():
    """Admin endpoint with correct key should not be blocked."""
    response = client.get("/api/v1/admin/sessions", headers=VALID_KEY)
    # Empty list is fine — just confirming auth passes
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    print("[test] ✅ Valid key → 200")


# ═══════════════════════════════════════════════════════════════
# Session Tests
# ═══════════════════════════════════════════════════════════════

def test_create_session():
    """POST /admin/session should create a session in draft status."""
    response = client.post(
        "/api/v1/admin/session",
        headers=VALID_KEY,
        json={
            "title": "Admin Test Session",
            "department": "CS",
            "language": "python",
            "duration_minutes": 90,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Admin Test Session"
    assert data["status"] == "draft"
    assert data["id"] is not None
    print(f"[test] Session created id={data['id']}")


def test_list_sessions():
    """GET /admin/sessions should return all sessions."""
    response = client.get("/api/v1/admin/sessions", headers=VALID_KEY)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    print(f"[test] Sessions listed: {len(data)}")


def test_update_session_status():
    """PUT /admin/session/1/status should set status to active."""
    response = client.put(
        "/api/v1/admin/session/1/status",
        headers=VALID_KEY,
        json={"status": "active"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["status"] == "active"
    print("[test] Session status → active")


def test_update_session_status_invalid():
    """PUT with invalid status should return error."""
    response = client.put(
        "/api/v1/admin/session/1/status",
        headers=VALID_KEY,
        json={"status": "invalid_status"},
    )
    assert response.status_code == 422  # Pydantic validation error
    print("[test] Invalid status correctly rejected")


# ═══════════════════════════════════════════════════════════════
# Question Tests
# ═══════════════════════════════════════════════════════════════

def test_create_question():
    """POST /admin/question should add a question to session 1."""
    response = client.post(
        "/api/v1/admin/question",
        headers=VALID_KEY,
        json={
            "session_id": 1,
            "language": "python",
            "title": "Test Question Alpha",
            "statement": "Write a Python program to print Hello World.",
            "starter_code": "print('Hello World')",
            "visible_examples": [{"input": "", "output": "Hello World"}],
            "constraints": ["Use Python only"],
            "metadata": {"difficulty": "easy"},
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Test Question Alpha"
    assert data["session_id"] == 1
    print(f"[test] Question created id={data['id']}")


def test_list_questions():
    """GET /admin/session/1/questions should return questions."""
    response = client.get("/api/v1/admin/session/1/questions", headers=VALID_KEY)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    print(f"[test] Questions listed: {len(data)}")


# ═══════════════════════════════════════════════════════════════
# Student Tests
# ═══════════════════════════════════════════════════════════════

def test_create_student():
    """POST /admin/student should add a student."""
    response = client.post(
        "/api/v1/admin/student",
        headers=VALID_KEY,
        json={
            "registration_number": "ADM001",
            "name": "Admin Test Student",
            "department": "CS",
            "batch": "2024",
            "section": "A",
            "enabled": True,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["registration_number"] == "ADM001"
    print("[test] Student ADM001 created")


def test_create_duplicate_student():
    """Duplicate registration number should return error response."""
    response = client.post(
        "/api/v1/admin/student",
        headers=VALID_KEY,
        json={
            "registration_number": "ADM001",
            "name": "Duplicate",
            "department": "CS",
            "batch": "2024",
            "section": "A",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is False
    print("[test] Duplicate student correctly rejected")


def test_bulk_upload_students():
    """POST /admin/students/bulk should add multiple students."""
    response = client.post(
        "/api/v1/admin/students/bulk",
        headers=VALID_KEY,
        json={
            "students": [
                {"registration_number": "ADM002", "name": "Student Two", "department": "CS", "batch": "2024", "section": "A"},
                {"registration_number": "ADM003", "name": "Student Three", "department": "IT", "batch": "2024", "section": "B"},
                {"registration_number": "ADM001", "name": "Duplicate Skip", "department": "CS", "batch": "2024", "section": "A"},
            ]
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["created"] == 2
    assert data["skipped"] == 1
    assert data["total"] == 3
    print(f"[test] Bulk upload: created={data['created']} skipped={data['skipped']}")


def test_list_students():
    """GET /admin/students should return all students."""
    response = client.get("/api/v1/admin/students", headers=VALID_KEY)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 3
    print(f"[test] Students listed: {len(data)}")


def test_disable_enable_student():
    """PUT /admin/student/{reg}/disable and enable."""
    # Disable
    r1 = client.put("/api/v1/admin/student/ADM001/disable", headers=VALID_KEY)
    assert r1.status_code == 200
    assert r1.json()["data"]["enabled"] is False

    # Enable
    r2 = client.put("/api/v1/admin/student/ADM001/enable", headers=VALID_KEY)
    assert r2.status_code == 200
    assert r2.json()["data"]["enabled"] is True
    print("[test] Student disable/enable toggle works")


# ═══════════════════════════════════════════════════════════════
# Assignment Tests
# ═══════════════════════════════════════════════════════════════

def test_assign_question():
    """POST /admin/assignment should assign question to student."""
    response = client.post(
        "/api/v1/admin/assignment",
        headers=VALID_KEY,
        json={
            "session_id": 1,
            "registration_number": "ADM001",
            "question_id": 1,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["student_registration"] == "ADM001"
    print("[test] Manual assignment created")


def test_bulk_assign():
    """POST /admin/assignment/bulk should assign remaining students."""
    response = client.post(
        "/api/v1/admin/assignment/bulk",
        headers=VALID_KEY,
        json={"session_id": 1},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    print(f"[test] Bulk assign: {data['message']}")


def test_list_assignments():
    """GET /admin/session/1/assignments should return all assignments."""
    response = client.get("/api/v1/admin/session/1/assignments", headers=VALID_KEY)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    print(f"[test] Assignments listed: {len(data)}")


# ═══════════════════════════════════════════════════════════════
# Monitor Tests
# ═══════════════════════════════════════════════════════════════

def test_live_monitor():
    """GET /admin/session/1/monitor should return monitor snapshot."""
    response = client.get("/api/v1/admin/session/1/monitor", headers=VALID_KEY)
    assert response.status_code == 200
    data = response.json()
    assert data["session_id"] == 1
    assert "total_students" in data
    assert "online_count" in data
    assert "submitted_count" in data
    assert isinstance(data["students"], list)
    print(f"[test] Monitor: total={data['total_students']} online={data['online_count']}")


def test_monitor_not_found():
    """Monitor for nonexistent session should return 404."""
    response = client.get("/api/v1/admin/session/9999/monitor", headers=VALID_KEY)
    assert response.status_code == 404
    print("[test] Monitor 404 for unknown session works")


# ═══════════════════════════════════════════════════════════════
# Submission Tests
# ═══════════════════════════════════════════════════════════════

def test_list_submissions():
    """GET /admin/session/1/submissions should return list."""
    response = client.get("/api/v1/admin/session/1/submissions", headers=VALID_KEY)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    print(f"[test] Submissions listed: {len(data)}")


if __name__ == "__main__":
    # Security tests first
    test_admin_missing_key_returns_401()
    test_admin_wrong_key_returns_403()
    test_admin_valid_key_passes()
    # Functional tests
    test_create_session()
    test_list_sessions()
    test_update_session_status()
    test_update_session_status_invalid()
    test_create_question()
    test_list_questions()
    test_create_student()
    test_create_duplicate_student()
    test_bulk_upload_students()
    test_list_students()
    test_disable_enable_student()
    test_assign_question()
    test_bulk_assign()
    test_list_assignments()
    test_live_monitor()
    test_monitor_not_found()
    test_list_submissions()
    print("\n✅ All 24 admin tests passed.")
