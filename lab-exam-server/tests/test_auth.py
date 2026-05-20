#!/usr/bin/env python3
# ============================================================
# File: tests/test_auth.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Integration tests for the auth/login endpoint.
#              Uses a shared SQLite connection for in-memory isolation.
# ============================================================

import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# pyrefly: ignore [missing-import]
from fastapi.testclient import TestClient
# pyrefly: ignore [missing-import]
from sqlalchemy import create_engine, event
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.core.database import get_db
from app.db.base import Base
from app.models.student import Student
from app.models.session import ExamSession, SessionStatus
from app.models.question import Question
from app.models.question_assignment import QuestionAssignment

# ── Use a named in-memory SQLite so all connections share the DB ──
# file::memory:?cache=shared lets multiple connections see same DB
TEST_DATABASE_URL = "sqlite:///./data/test_lab_exam.db"
test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
)

TestSessionLocal = sessionmaker(
    bind=test_engine, autocommit=False, autoflush=False, expire_on_commit=False
)


def override_get_db():
    db = TestSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

# ── Create tables fresh ──────────────────────────────────────
Base.metadata.drop_all(bind=test_engine)
Base.metadata.create_all(bind=test_engine)

# ── Seed test data ───────────────────────────────────────────
_db = TestSessionLocal()
try:
    _student = Student(
        registration_number="TEST001",
        name="Test Student",
        department="CS",
        batch="2024",
        section="A",
        enabled=True,
    )
    _db.add(_student)
    _db.commit()
    _db.refresh(_student)

    _session = ExamSession(
        title="Test Session",
        department="CS",
        language="python",
        duration_minutes=60,
        status=SessionStatus.active,
    )
    _db.add(_session)
    _db.commit()
    _db.refresh(_session)

    _question = Question(
        session_id=_session.id,
        language="python",
        title="Test Question",
        statement="Write Hello World",
        starter_code="print('Hello')",
    )
    _db.add(_question)
    _db.commit()
    _db.refresh(_question)

    _assignment = QuestionAssignment(
        session_id=_session.id,
        student_id=_student.id,
        question_id=_question.id,
    )
    _db.add(_assignment)
    _db.commit()
finally:
    _db.close()

# ── TestClient ───────────────────────────────────────────────
client = TestClient(app, raise_server_exceptions=True)


def test_login_success():
    """Valid student with active session returns success."""
    response = client.post(
        "/api/v1/auth/login",
        json={
            "registration_number": "TEST001",
            "machine_name": "LAB-PC-01",
            "machine_ip": "192.168.1.10",
            "client_version": "0.1.0",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["student"]["registration_number"] == "TEST001"
    assert data["session"]["status"] == "active"
    assert data["assignment"]["question_id"] is not None
    print("[test] Login success test passed.")


def test_login_unknown_student():
    """Unknown registration number returns failure response (not HTTP error)."""
    response = client.post(
        "/api/v1/auth/login",
        json={
            "registration_number": "NOTEXIST",
            "machine_name": "LAB-PC-01",
            "machine_ip": "192.168.1.10",
            "client_version": "0.1.0",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is False
    print("[test] Unknown student test passed.")


if __name__ == "__main__":
    test_login_success()
    test_login_unknown_student()
    print("[test] Auth tests passed.")
