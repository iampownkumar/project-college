# ============================================================
# File: app/repositories/question_repo.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Data-access layer for Question model.
# ============================================================

from sqlalchemy.orm import Session
from typing import Optional, List
from app.models.question import Question


class QuestionRepository:
    """Repository for Question CRUD and queries."""

    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, question_id: int) -> Optional[Question]:
        return self.db.query(Question).filter(Question.id == question_id).first()

    def get_by_session(self, session_id: int) -> List[Question]:
        return (
            self.db.query(Question)
            .filter(Question.session_id == session_id)
            .all()
        )

    def create(self, question: Question) -> Question:
        self.db.add(question)
        self.db.commit()
        self.db.refresh(question)
        return question

    def create_many(self, questions: List[Question]) -> List[Question]:
        self.db.add_all(questions)
        self.db.commit()
        return questions
