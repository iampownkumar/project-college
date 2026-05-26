# ============================================================
# File: app/services/file_service.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Koreliurm)
# Created: 2026-05-26
# Last Updated: 2026-05-26
# Location: Tamil Nadu, India
# Description: Business logic for question sandbox file management.
#              Handles upload, list, download, and delete operations.
#
#  Storage layout on disk:
#    data/uploads/questions/<question_id>/<safe_filename>
#
#  Rules enforced:
#    - Max 5 files per question
#    - Max 10 MB per file
#    - Allowed extensions: csv, json, txt, png, jpg, jpeg, xlsx, dat
#    - Filenames are sanitised (path traversal prevention)
# ============================================================

import os
import re
import mimetypes
from typing import List, Optional

from fastapi import UploadFile, HTTPException, status
from sqlalchemy.orm import Session

from app.models.question import Question
from app.models.question_file import QuestionFile
from app.core.logging import get_logger

logger = get_logger(__name__)

# ── Constants ────────────────────────────────────────────────────────────────

UPLOADS_ROOT = "./data/uploads/questions"
MAX_FILES_PER_QUESTION = 5
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB

ALLOWED_EXTENSIONS = {
    ".csv", ".json", ".txt", ".png", ".jpg", ".jpeg", ".xlsx", ".dat",
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _safe_filename(name: str) -> str:
    """
    Strip directory components and any character that isn't alphanumeric,
    a dot, hyphen, or underscore. Returns the sanitised filename.
    Raises ValueError if the result is empty or has a disallowed extension.
    """
    # Take only the basename (prevents path traversal like ../../etc/passwd)
    name = os.path.basename(name)
    # Replace spaces with underscores
    name = name.replace(" ", "_")
    # Keep only safe characters
    name = re.sub(r"[^\w.\-]", "", name)
    if not name:
        raise ValueError("Filename is empty after sanitisation.")
    ext = os.path.splitext(name)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError(
            f"File type '{ext}' is not allowed. "
            f"Permitted: {', '.join(sorted(ALLOWED_EXTENSIONS))}"
        )
    return name


def _question_upload_dir(question_id: int) -> str:
    """Return (and create if needed) the upload directory for a question."""
    path = os.path.join(UPLOADS_ROOT, str(question_id))
    os.makedirs(path, exist_ok=True)
    return path


def ensure_uploads_root() -> None:
    """
    Create the root uploads directory on server startup.
    Safe to call multiple times.
    """
    os.makedirs(UPLOADS_ROOT, exist_ok=True)
    logger.info(f"Uploads directory ready: {os.path.abspath(UPLOADS_ROOT)}")


# ── Service class ─────────────────────────────────────────────────────────────

class FileService:
    """Handles sandbox file upload, listing, download, and deletion."""

    def __init__(self, db: Session):
        self.db = db

    # ── Internal helpers ──────────────────────────────────────────────────────

    def _get_question_or_404(self, question_id: int) -> Question:
        q = self.db.query(Question).filter(Question.id == question_id).first()
        if not q:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Question id={question_id} not found.",
            )
        return q

    def _get_file_record(
        self, question_id: int, filename: str
    ) -> Optional[QuestionFile]:
        return (
            self.db.query(QuestionFile)
            .filter(
                QuestionFile.question_id == question_id,
                QuestionFile.filename == filename,
            )
            .first()
        )

    # ── Upload ────────────────────────────────────────────────────────────────

    async def upload_file(
        self, question_id: int, upload: UploadFile
    ) -> QuestionFile:
        """
        Save an uploaded file to disk and record it in the database.
        Raises HTTP 400/404/409 on validation errors.
        """
        self._get_question_or_404(question_id)

        # Check file count limit
        current_count = (
            self.db.query(QuestionFile)
            .filter(QuestionFile.question_id == question_id)
            .count()
        )
        if current_count >= MAX_FILES_PER_QUESTION:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Question already has {current_count} file(s). "
                    f"Maximum allowed is {MAX_FILES_PER_QUESTION}."
                ),
            )

        # Sanitise filename
        try:
            safe_name = _safe_filename(upload.filename or "upload")
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)
            )

        # Prevent duplicate filename for this question
        if self._get_file_record(question_id, safe_name):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"A file named '{safe_name}' is already attached to this question.",
            )

        # Read content with size limit
        content = await upload.read(MAX_FILE_SIZE_BYTES + 1)
        if len(content) > MAX_FILE_SIZE_BYTES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"File exceeds maximum size of "
                    f"{MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB."
                ),
            )

        # Write to disk
        upload_dir = _question_upload_dir(question_id)
        file_path = os.path.join(upload_dir, safe_name)
        with open(file_path, "wb") as f:
            f.write(content)

        # Detect MIME type
        mime_type, _ = mimetypes.guess_type(safe_name)
        mime_type = mime_type or "application/octet-stream"

        # Persist DB record
        record = QuestionFile(
            question_id=question_id,
            filename=safe_name,
            mime_type=mime_type,
            size_bytes=len(content),
            file_path=os.path.abspath(file_path),
        )
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)

        logger.info(
            f"File uploaded: question_id={question_id} "
            f"filename={safe_name} size={len(content)}"
        )
        return record

    # ── List ──────────────────────────────────────────────────────────────────

    def list_files(self, question_id: int) -> List[QuestionFile]:
        """Return all file records for a question, sorted by filename."""
        self._get_question_or_404(question_id)
        return (
            self.db.query(QuestionFile)
            .filter(QuestionFile.question_id == question_id)
            .order_by(QuestionFile.filename)
            .all()
        )

    # ── Download (bytes) ──────────────────────────────────────────────────────

    def get_file_bytes(self, question_id: int, filename: str) -> tuple[bytes, str]:
        """
        Return (file_bytes, mime_type) for the requested file.
        Raises HTTP 404 if the record or the disk file is missing.
        """
        record = self._get_file_record(question_id, filename)
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"File '{filename}' not found for question id={question_id}.",
            )
        if not os.path.isfile(record.file_path):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"File '{filename}' exists in DB but is missing on disk.",
            )
        with open(record.file_path, "rb") as f:
            data = f.read()
        return data, record.mime_type

    # ── Delete ────────────────────────────────────────────────────────────────

    def delete_file(self, question_id: int, filename: str) -> dict:
        """
        Delete a file from disk and remove its DB record.
        Raises HTTP 404 if not found.
        """
        record = self._get_file_record(question_id, filename)
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"File '{filename}' not found for question id={question_id}.",
            )

        # Remove from disk (best-effort: log but don't crash if already gone)
        if os.path.isfile(record.file_path):
            try:
                os.remove(record.file_path)
            except OSError as e:
                logger.warning(
                    f"Could not delete file on disk: {record.file_path} — {e}"
                )

        self.db.delete(record)
        self.db.commit()

        logger.info(
            f"File deleted: question_id={question_id} filename={filename}"
        )
        return {"message": f"File '{filename}' deleted successfully."}
