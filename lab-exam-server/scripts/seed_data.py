#!/usr/bin/env python3
# ============================================================
# File: scripts/seed_data.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Seed script to populate the database with:
#              - Students from students.csv
#              - Sessions from sessions.json
#              - Questions from questions/python/*.json
#              - Auto-assigns questions to students (round-robin)
#
# Usage (from lab-exam-server/ root):
#   python scripts/seed_data.py
# ============================================================

import sys
import os
import csv
import json
import glob

# Ensure the project root is on the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.config import settings
from app.core.database import engine
from app.db.base import Base
import app.models  # noqa – registers all models

from sqlalchemy.orm import Session as DBSession
from sqlalchemy.orm import sessionmaker

from app.models.student import Student
from app.models.session import ExamSession, SessionStatus
from app.models.question import Question
from app.models.question_assignment import QuestionAssignment

SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


def create_tables():
    print("[seed] Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("[seed] Tables ready.")


def load_students(db: DBSession, seed_dir: str) -> list[Student]:
    csv_path = os.path.join(seed_dir, "students.csv")
    if not os.path.exists(csv_path):
        print(f"[seed] WARNING: {csv_path} not found. Skipping students.")
        return []

    students = []
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            reg = row["registration_number"].strip()
            existing = (
                db.query(Student)
                .filter(Student.registration_number == reg)
                .first()
            )
            if existing:
                print(f"[seed]   SKIP student already exists: {reg}")
                students.append(existing)
                continue

            enabled_val = row.get("enabled", "true").strip().lower()
            student = Student(
                registration_number=reg,
                name=row["name"].strip(),
                department=row["department"].strip(),
                batch=row["batch"].strip(),
                section=row["section"].strip(),
                enabled=(enabled_val == "true"),
            )
            db.add(student)
            students.append(student)
            print(f"[seed]   + student: {reg} ({row['name'].strip()})")

    db.commit()
    # Refresh all to get IDs
    for s in students:
        db.refresh(s)
    print(f"[seed] Students loaded: {len(students)} total.")
    return students


def load_sessions(db: DBSession, seed_dir: str) -> list[ExamSession]:
    json_path = os.path.join(seed_dir, "sessions.json")
    if not os.path.exists(json_path):
        print(f"[seed] WARNING: {json_path} not found. Skipping sessions.")
        return []

    with open(json_path, encoding="utf-8") as f:
        data = json.load(f)

    sessions_data = data.get("sessions", [])
    sessions = []
    for s in sessions_data:
        existing = (
            db.query(ExamSession)
            .filter(ExamSession.title == s["title"])
            .first()
        )
        if existing:
            print(f"[seed]   SKIP session already exists: {s['title']}")
            sessions.append(existing)
            continue

        status_val = s.get("status", "draft")
        try:
            status_enum = SessionStatus(status_val)
        except ValueError:
            status_enum = SessionStatus.draft

        session = ExamSession(
            title=s["title"],
            department=s["department"],
            language=s.get("language", "python"),
            duration_minutes=s.get("duration_minutes", 60),
            status=status_enum,
        )
        db.add(session)
        sessions.append(session)
        print(f"[seed]   + session: {s['title']} (status={status_val})")

    db.commit()
    for s in sessions:
        db.refresh(s)
    print(f"[seed] Sessions loaded: {len(sessions)} total.")
    return sessions


def load_questions(
    db: DBSession, seed_dir: str, session: ExamSession
) -> list[Question]:
    q_dir = os.path.join(seed_dir, "questions", "python")
    if not os.path.exists(q_dir):
        print(f"[seed] WARNING: {q_dir} not found. Skipping questions.")
        return []

    pattern = os.path.join(q_dir, "*.json")
    question_files = sorted(glob.glob(pattern))

    questions = []
    for path in question_files:
        with open(path, encoding="utf-8") as f:
            q_data = json.load(f)

        title = q_data.get("title", "")
        existing = (
            db.query(Question)
            .filter(
                Question.session_id == session.id,
                Question.title == title,
            )
            .first()
        )
        if existing:
            print(f"[seed]   SKIP question already exists: {title}")
            questions.append(existing)
            continue

        question = Question(
            session_id=session.id,
            language=q_data.get("language", "python"),
            title=title,
            statement=q_data.get("statement", ""),
            starter_code=q_data.get("starter_code"),
            visible_examples_json=json.dumps(q_data.get("visible_examples", [])),
            constraints_json=json.dumps(q_data.get("constraints", [])),
            metadata_json=json.dumps(q_data.get("metadata", {})),
        )
        db.add(question)
        questions.append(question)
        print(f"[seed]   + question: {title}")

    db.commit()
    for q in questions:
        db.refresh(q)
    print(f"[seed] Questions loaded: {len(questions)} total.")
    return questions


def assign_questions(
    db: DBSession,
    session: ExamSession,
    students: list[Student],
    questions: list[Question],
) -> None:
    if not questions:
        print("[seed] No questions available, skipping assignments.")
        return

    assigned_count = 0
    for i, student in enumerate(students):
        existing = (
            db.query(QuestionAssignment)
            .filter(
                QuestionAssignment.session_id == session.id,
                QuestionAssignment.student_id == student.id,
            )
            .first()
        )
        if existing:
            print(
                f"[seed]   SKIP assignment already exists: "
                f"{student.registration_number} -> question {existing.question_id}"
            )
            continue

        # Round-robin assignment
        question = questions[i % len(questions)]
        assignment = QuestionAssignment(
            session_id=session.id,
            student_id=student.id,
            question_id=question.id,
        )
        db.add(assignment)
        print(
            f"[seed]   + assign: {student.registration_number} -> {question.title}"
        )
        assigned_count += 1

    db.commit()
    print(f"[seed] Assignments created: {assigned_count} new.")


def main():
    print("=" * 60)
    print(" Lab Exam Server - Seed Data Loader")
    print(" Author: Pownkumar A (Founder of Koreliurm)")
    print("=" * 60)

    seed_dir = os.path.abspath(settings.seed_data_dir)
    print(f"[seed] Seed directory: {seed_dir}")

    create_tables()

    db = SessionLocal()
    try:
        students = load_students(db, seed_dir)
        sessions = load_sessions(db, seed_dir)

        if not sessions:
            print("[seed] No sessions loaded. Cannot assign questions.")
            return

        # Use first active session, or first session as fallback
        active_sessions = [s for s in sessions if s.status == SessionStatus.active]
        target_session = active_sessions[0] if active_sessions else sessions[0]
        print(f"[seed] Using session: '{target_session.title}' (id={target_session.id})")

        questions = load_questions(db, seed_dir, target_session)
        assign_questions(db, target_session, students, questions)

    finally:
        db.close()

    print("=" * 60)
    print("[seed] Seed complete.")
    print("=" * 60)


if __name__ == "__main__":
    main()
