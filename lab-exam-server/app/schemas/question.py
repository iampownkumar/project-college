# ============================================================
# File: app/schemas/question.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-15
# Last Updated: 2026-05-26
# Location: Tamil Nadu, India
# Description: Pydantic schemas for question data including
#              JSON-encoded examples, constraints, and attached
#              sandbox files (AttachedFileOut).
# ============================================================

from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime
import json


class AttachedFileOut(BaseModel):
    """Metadata for one file attached to a question (no file bytes)."""
    id: int
    filename: str
    mime_type: str
    size_bytes: int

    model_config = {"from_attributes": True}


class ExampleItem(BaseModel):
    input: str = ""
    output: str = ""


class TestCaseItem(BaseModel):
    input: str = ""
    output: str = ""
    marks: int = 0


class QuestionBase(BaseModel):
    language: str = "python"
    title: str
    statement: str
    starter_code: Optional[str] = None
    visible_examples: Optional[List[ExampleItem]] = None
    test_cases: Optional[List[TestCaseItem]] = None
    constraints: Optional[List[str]] = None
    metadata: Optional[dict] = None


class QuestionCreate(QuestionBase):
    session_id: int


class QuestionOut(BaseModel):
    id: int
    session_id: int
    language: str
    title: str
    statement: str
    starter_code: Optional[str] = None
    visible_examples_json: Optional[str] = None
    constraints_json: Optional[str] = None
    test_cases_json: Optional[str] = None
    metadata_json: Optional[str] = None
    created_at: Optional[datetime] = None
    # Sandbox files attached by faculty — empty list when none exist
    attached_files: List[AttachedFileOut] = []

    model_config = {"from_attributes": True}

    def get_visible_examples(self) -> List[dict]:
        if self.visible_examples_json:
            return json.loads(self.visible_examples_json)
        return []

    def get_test_cases(self) -> List[dict]:
        if self.test_cases_json:
            return json.loads(self.test_cases_json)
        return []

    def get_constraints(self) -> List[str]:
        if self.constraints_json:
            return json.loads(self.constraints_json)
        return []

    def get_metadata(self) -> dict:
        if self.metadata_json:
            return json.loads(self.metadata_json)
        return {}
