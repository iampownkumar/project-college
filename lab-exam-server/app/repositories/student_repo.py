# ============================================================
# File: app/repositories/student_repo.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-15
# Location: Tamil Nadu, India
# Description: Data-access layer for Student model.
#              All direct DB queries for students live here.
# ============================================================

from sqlalchemy.orm import Session
from typing import Optional, List
from app.models.student import Student


class StudentRepository:
    """Repository for Student CRUD and queries."""

    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, student_id: int) -> Optional[Student]:
        return self.db.query(Student).filter(Student.id == student_id).first()

    def get_by_registration(self, registration_number: str) -> Optional[Student]:
        return (
            self.db.query(Student)
            .filter(Student.registration_number == registration_number)
            .first()
        )

    def get_all(self, skip: int = 0, limit: int = 200) -> List[Student]:
        return self.db.query(Student).offset(skip).limit(limit).all()

    def create(self, student: Student) -> Student:
        self.db.add(student)
        self.db.commit()
        self.db.refresh(student)
        return student

    def create_many(self, students: List[Student]) -> List[Student]:
        self.db.add_all(students)
        self.db.commit()
        return students

    def update(self, student: Student) -> Student:
        self.db.commit()
        self.db.refresh(student)
        return student

    def delete(self, student: Student) -> None:
        self.db.delete(student)
        self.db.commit()

    def exists(self, registration_number: str) -> bool:
        return (
            self.db.query(Student)
            .filter(Student.registration_number == registration_number)
            .count()
            > 0
        )
