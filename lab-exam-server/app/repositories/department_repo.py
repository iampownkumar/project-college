# ============================================================
# File: app/repositories/department_repo.py
# Project: Local Lab Exam System - Coordinator Server
# Description: Data-access layer for Department model.
# ============================================================

from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.department import Department

class DepartmentRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, name: str, code: str) -> Department:
        dept = Department(name=name, code=code)
        self.db.add(dept)
        self.db.commit()
        self.db.refresh(dept)
        return dept

    def get_all(self) -> List[Department]:
        return self.db.query(Department).all()

    def get_by_id(self, dept_id: int) -> Optional[Department]:
        return self.db.query(Department).filter(Department.id == dept_id).first()

    def get_by_code(self, code: str) -> Optional[Department]:
        return self.db.query(Department).filter(Department.code == code).first()

    def delete(self, dept: Department):
        self.db.delete(dept)
        self.db.commit()
