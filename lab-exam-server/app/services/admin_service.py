# ============================================================
# File: app/services/admin_service.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-15
# Last Updated: 2026-05-26
# Location: Tamil Nadu, India
# Description: Business logic for all admin operations.
#              Session management, question creation, student
#              bulk-upload, question assignment, live monitor,
#              and submission retrieval.
# ============================================================

import json
from datetime import timedelta
from typing import Optional, List, Tuple
from app.core.timezone import IST, to_ist, now_ist

from sqlalchemy.orm import Session as DBSession

from app.core.logging import get_logger
from app.models.session import ExamSession, SessionStatus
from app.models.question import Question
from app.models.student import Student
from app.models.question_assignment import QuestionAssignment
from app.models.heartbeat import Heartbeat
from app.models.run_log import RunLog
from app.models.submission import Submission
from app.repositories.session_repo import SessionRepository
from app.repositories.question_repo import QuestionRepository
from app.repositories.student_repo import StudentRepository
from app.repositories.assignment_repo import AssignmentRepository
from app.repositories.heartbeat_repo import HeartbeatRepository
from app.repositories.run_log_repo import RunLogRepository
from app.repositories.submission_repo import SubmissionRepository
from app.repositories.department_repo import DepartmentRepository
from app.schemas.admin import (
    SessionCreateRequest,
    SessionAdminOut,
    QuestionCreateRequest,
    QuestionAdminOut,
    QuestionBulkRequest,
    QuestionBulkResult,
    StudentCreateRequest,
    StudentBulkRequest,
    StudentBulkResult,
    StudentAdminOut,
    AssignmentCreateRequest,
    BulkAssignRequest,
    AssignmentAdminOut,
    MonitorResponse,
    StudentLiveStatus,
    SubmissionAdminOut,
    DepartmentCreateRequest,
    DepartmentOut,
)
from app.schemas.common import SuccessResponse, ErrorResponse

logger = get_logger(__name__)


class AdminService:
    """
    Central service for all admin/faculty operations.
    All methods receive an open DB session and return
    either a schema object or a SuccessResponse/ErrorResponse.
    """

    def __init__(self, db: DBSession):
        self.db = db
        self.session_repo = SessionRepository(db)
        self.question_repo = QuestionRepository(db)
        self.student_repo = StudentRepository(db)
        self.assignment_repo = AssignmentRepository(db)
        self.heartbeat_repo = HeartbeatRepository(db)
        self.run_log_repo = RunLogRepository(db)
        self.submission_repo = SubmissionRepository(db)
        self.department_repo = DepartmentRepository(db)

    # ── Departments ──────────────────────────────────────────
    
    def create_department(self, payload: DepartmentCreateRequest):
        dept = self.department_repo.create(name=payload.name, code=payload.code)
        return SuccessResponse(message="Department created.", data=DepartmentOut.model_validate(dept))

    def get_all_departments(self):
        depts = self.department_repo.get_all()
        return [DepartmentOut.model_validate(d) for d in depts]

    def delete_department(self, dept_id: int):
        dept = self.department_repo.get_by_id(dept_id)
        if not dept:
            from fastapi import HTTPException
            raise HTTPException(status_code=404, detail="Department not found.")
        self.department_repo.delete(dept)
        return SuccessResponse(message="Department deleted.")

    # ── Sessions ─────────────────────────────────────────────

    def create_session(self, payload: SessionCreateRequest) -> SessionAdminOut:
        """Create a new exam session in draft state."""
        session = ExamSession(
            title=payload.title,
            department=payload.department,
            language=payload.language,
            duration_minutes=payload.duration_minutes,
            start_time=payload.start_time,
            end_time=payload.end_time,
            status=SessionStatus.draft,
        )
        saved = self.session_repo.create(session)
        logger.info(f"Admin: created session id={saved.id} title='{saved.title}'")
        return self._session_to_out(saved)

    def list_sessions(self) -> List[SessionAdminOut]:
        """Return all sessions with question and student counts."""
        sessions = self.session_repo.get_all()
        return [self._session_to_out(s) for s in sessions]

    def get_session(self, session_id: int) -> Optional[SessionAdminOut]:
        """Return one session by ID."""
        s = self.session_repo.get_by_id(session_id)
        if not s:
            return None
        return self._session_to_out(s)

    def update_session_status(
        self, session_id: int, new_status: str
    ):
        """
        Change session status.
        Only one session can be 'active' at a time.
        """
        session = self.session_repo.get_by_id(session_id)
        if not session:
            return ErrorResponse(message=f"Session id={session_id} not found.")

        # Enforce: deactivate any existing active session before activating new one
        if new_status == "active":
            current_active = self.session_repo.get_active()
            if current_active and current_active.id != session_id:
                current_active.status = SessionStatus.closed
                self.session_repo.update(current_active)
                logger.warning(
                    f"Admin: auto-closed previous active session id={current_active.id}"
                )
            # Set exact start and end time based on activation
            session.start_time = now_ist()
            session.end_time = session.start_time + timedelta(minutes=session.duration_minutes)

        try:
            session.status = SessionStatus(new_status)
        except ValueError:
            return ErrorResponse(message=f"Invalid status '{new_status}'. Use: draft, active, closed.")

        self.session_repo.update(session)
        logger.info(f"Admin: session id={session_id} status → {new_status}")
        return SuccessResponse(
            message=f"Session status updated to '{new_status}'.",
            data=self._session_to_out(session),
        )

    def _session_to_out(self, s: ExamSession) -> SessionAdminOut:
        """Convert ExamSession ORM → SessionAdminOut with counts."""
        q_count = len(s.questions) if s.questions else 0
        a_count = len(s.assignments) if s.assignments else 0
        return SessionAdminOut(
            id=s.id,
            title=s.title,
            department=s.department,
            language=s.language,
            duration_minutes=s.duration_minutes,
            status=s.status.value if hasattr(s.status, "value") else str(s.status),
            start_time=to_ist(s.start_time),
            end_time=to_ist(s.end_time),
            created_at=to_ist(s.created_at),
            question_count=q_count,
            student_count=a_count,
        )

    def delete_session(self, session_id: int) -> SuccessResponse:
        """Delete an exam session and all its data."""
        session = self.session_repo.get_by_id(session_id)
        if not session:
            raise ValueError(f"Session id={session_id} not found.")
        self.session_repo.delete(session_id)
        logger.info(f"Admin: deleted session id={session_id}")
        return SuccessResponse(message=f"Session {session_id} deleted successfully.")

    # ── Questions ─────────────────────────────────────────────

    def create_question(self, payload: QuestionCreateRequest) -> QuestionAdminOut:
        """Add a new question to a session."""
        session = self.session_repo.get_by_id(payload.session_id)
        if not session:
            raise ValueError(f"Session id={payload.session_id} not found.")

        question = Question(
            session_id=payload.session_id,
            language=payload.language,
            title=payload.title,
            statement=payload.statement,
            starter_code=payload.starter_code,
            visible_examples_json=json.dumps(payload.visible_examples or []),
            test_cases_json=json.dumps(payload.test_cases or []),
            constraints_json=json.dumps(payload.constraints or []),
            metadata_json=json.dumps(payload.metadata or {}),
        )
        saved = self.question_repo.create(question)
        logger.info(
            f"Admin: created question id={saved.id} title='{saved.title}' "
            f"for session={payload.session_id}"
        )
        return QuestionAdminOut.model_validate(saved)

    def list_questions(self, session_id: int) -> List[QuestionAdminOut]:
        """List all questions for a session."""
        questions = self.question_repo.get_by_session(session_id)
        return [QuestionAdminOut.model_validate(q) for q in questions]

    def bulk_upload_questions(self, payload: QuestionBulkRequest) -> QuestionBulkResult:
        """Bulk upload questions for a session."""
        created = 0
        skipped = 0
        errors: List[str] = []

        session = self.session_repo.get_by_id(payload.session_id)
        if not session:
            errors.append(f"Session id={payload.session_id} not found.")
            return QuestionBulkResult(total=len(payload.questions), created=0, skipped=0, errors=errors)

        for idx, row in enumerate(payload.questions):
            try:
                question = Question(
                    session_id=payload.session_id,
                    language=row.language,
                    title=row.title,
                    statement=row.statement,
                    starter_code=row.starter_code,
                    visible_examples_json=json.dumps(row.visible_examples or []),
                    test_cases_json=json.dumps(row.test_cases or []),
                    constraints_json=json.dumps(row.constraints or []),
                    metadata_json=json.dumps(row.metadata or {}),
                )
                self.db.add(question)
                created += 1
            except Exception as e:
                errors.append(f"Row {idx+1}: {str(e)}")
                skipped += 1

        if created > 0:
            self.db.commit()

        return QuestionBulkResult(
            total=len(payload.questions),
            created=created,
            skipped=skipped,
            errors=errors
        )

    def delete_question(self, question_id: int) -> SuccessResponse:
        """Delete a single question."""
        question = self.question_repo.get_by_id(question_id)
        if not question:
            raise ValueError(f"Question id={question_id} not found.")
        self.question_repo.delete(question_id)
        logger.info(f"Admin: deleted question id={question_id}")
        return SuccessResponse(message=f"Question {question_id} deleted successfully.")

    # ── Students ──────────────────────────────────────────────

    def create_student(self, payload: StudentCreateRequest):
        """Add a single student."""
        if self.student_repo.exists(payload.registration_number):
            return ErrorResponse(
                message=f"Student '{payload.registration_number}' already exists."
            )
        student = Student(
            registration_number=payload.registration_number,
            name=payload.name,
            department=payload.department,
            batch=payload.batch,
            year=payload.year,
            section=payload.section,
            enabled=payload.enabled,
        )
        saved = self.student_repo.create(student)
        logger.info(f"Admin: created student reg={saved.registration_number}")
        return SuccessResponse(
            message="Student created.",
            data=StudentAdminOut.model_validate(saved),
        )

    def bulk_upload_students(self, payload: StudentBulkRequest) -> StudentBulkResult:
        """
        Bulk upload students from a list.
        Skips duplicates, reports errors per row.
        """
        created = 0
        skipped = 0
        errors: List[str] = []

        for row in payload.students:
            try:
                if self.student_repo.exists(row.registration_number):
                    skipped += 1
                    continue
                student = Student(
                    registration_number=row.registration_number,
                    name=row.name,
                    department=row.department,
                    batch=row.batch,
                    year=row.year,
                    section=row.section,
                    enabled=row.enabled,
                )
                self.db.add(student)
                created += 1
            except Exception as e:
                errors.append(f"{row.registration_number}: {str(e)}")

        self.db.commit()
        logger.info(
            f"Admin: bulk upload — created={created} skipped={skipped} errors={len(errors)}"
        )
        return StudentBulkResult(
            total=len(payload.students),
            created=created,
            skipped=skipped,
            errors=errors,
        )

    def list_students(
        self, skip: int = 0, limit: int = 200
    ) -> List[StudentAdminOut]:
        """List all students."""
        students = self.student_repo.get_all(skip=skip, limit=limit)
        return [StudentAdminOut.model_validate(s) for s in students]

    def toggle_student(self, registration_number: str, enabled: bool):
        """Enable or disable a student account."""
        student = self.student_repo.get_by_registration(registration_number)
        if not student:
            return ErrorResponse(message=f"Student '{registration_number}' not found.")
        student.enabled = enabled
        self.student_repo.update(student)
        action = "enabled" if enabled else "disabled"
        logger.info(f"Admin: student {registration_number} {action}")
        return SuccessResponse(
            message=f"Student {registration_number} has been {action}.",
            data=StudentAdminOut.model_validate(student),
        )

    def delete_student(self, registration_number: str):
        """Permanently delete a student and their data."""
        student = self.student_repo.get_by_registration(registration_number)
        if not student:
            from fastapi import HTTPException, status
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Student '{registration_number}' not found.",
            )
        name = student.name
        self.student_repo.delete(student)
        logger.info(f"Admin: deleted student {registration_number} ({name})")
        return SuccessResponse(
            message=f"Student {registration_number} ({name}) permanently deleted.",
        )

    def delete_all_students(self) -> SuccessResponse:
        """Wipe every student row from the database."""
        count = self.db.query(Student).count()
        self.db.query(Student).delete(synchronize_session=False)
        self.db.commit()
        logger.warning(f"Admin: DELETED ALL {count} students from the database.")
        return SuccessResponse(message=f"All {count} students deleted.")

    def list_students_all(self) -> List[StudentAdminOut]:
        """Return every student with no pagination cap (for dashboard stats)."""
        students = self.db.query(Student).order_by(Student.year, Student.section, Student.name).all()
        return [StudentAdminOut.model_validate(s) for s in students]

    # ── Assignments ───────────────────────────────────────────

    def assign_question(self, payload: AssignmentCreateRequest):
        """Manually assign a specific question to a student."""
        student = self.student_repo.get_by_registration(payload.registration_number)
        if not student:
            return ErrorResponse(message=f"Student '{payload.registration_number}' not found.")

        session = self.session_repo.get_by_id(payload.session_id)
        if not session:
            return ErrorResponse(message=f"Session id={payload.session_id} not found.")

        question = self.question_repo.get_by_id(payload.question_id)
        if not question:
            return ErrorResponse(message=f"Question id={payload.question_id} not found.")

        if question.session_id != session.id:
            return ErrorResponse(
                message=f"Question id={payload.question_id} does not belong to session id={payload.session_id}."
            )

        # Remove existing assignment for this student/session if any
        existing = self.assignment_repo.get_by_student_and_session(
            student.id, session.id
        )
        if existing:
            self.db.delete(existing)
            self.db.commit()

        assignment = QuestionAssignment(
            session_id=session.id,
            student_id=student.id,
            question_id=question.id,
        )
        saved = self.assignment_repo.create(assignment)
        logger.info(
            f"Admin: assigned question={question.id} to student={student.registration_number}"
        )
        return SuccessResponse(
            message=f"Question '{question.title}' assigned to {student.registration_number}.",
            data=AssignmentAdminOut(
                id=saved.id,
                session_id=saved.session_id,
                student_id=saved.student_id,
                question_id=saved.question_id,
                assigned_at=saved.assigned_at,
                student_registration=student.registration_number,
                student_name=student.name,
                student_year=student.year,
                student_section=student.section,
                question_title=question.title,
            ),
        )

    def bulk_assign_questions(self, payload: BulkAssignRequest):
        """
        Round-robin assign all questions in a session to all students
        who have no assignment yet.
        """
        session = self.session_repo.get_by_id(payload.session_id)
        if not session:
            return ErrorResponse(message=f"Session id={payload.session_id} not found.")

        questions = self.question_repo.get_by_session(session.id)
        if not questions:
            return ErrorResponse(
                message=f"No questions found for session id={session.id}. Add questions first."
            )

        students = self.student_repo.get_all(limit=10000)
        if not students:
            return ErrorResponse(message="No students found in the system.")

        # Apply filters
        if payload.year and payload.year != "all":
            students = [s for s in students if s.year == payload.year]
        if payload.section and payload.section != "all":
            students = [s for s in students if s.section == payload.section]

        if not students:
            return ErrorResponse(message="No students match the specified filters.")

        assigned_count = 0
        skipped_count = 0

        for i, student in enumerate(students):
            existing = self.assignment_repo.get_by_student_and_session(
                student.id, session.id
            )
            if existing:
                skipped_count += 1
                continue
                
            if payload.question_id:
                # Assign specific question
                target_q_id = payload.question_id
            else:
                # Round-robin
                target_q_id = questions[i % len(questions)].id
                
            self.db.add(
                QuestionAssignment(
                    session_id=session.id,
                    student_id=student.id,
                    question_id=target_q_id,
                )
            )
            assigned_count += 1

        self.db.commit()
        logger.info(
            f"Admin: bulk assign session={session.id} — "
            f"assigned={assigned_count} skipped={skipped_count}"
        )
        return SuccessResponse(
            message=f"Bulk assignment complete. Assigned: {assigned_count}, Skipped (already assigned): {skipped_count}.",
            data={"assigned": assigned_count, "skipped": skipped_count},
        )

    def list_assignments(self, session_id: int) -> List[AssignmentAdminOut]:
        """List all question assignments for a session with student/question names."""
        assignments = self.assignment_repo.get_all_for_session(session_id)
        result = []
        for a in assignments:
            result.append(
                AssignmentAdminOut(
                    id=a.id,
                    session_id=a.session_id,
                    student_id=a.student_id,
                    question_id=a.question_id,
                    assigned_at=a.assigned_at,
                    student_registration=a.student.registration_number if a.student else None,
                    student_name=a.student.name if a.student else None,
                    student_department=a.student.department if a.student else None,
                    student_year=a.student.year if a.student else None,
                    student_section=a.student.section if a.student else None,
                    question_title=a.question.title if a.question else None,
                )
            )
        return result

    # ── Live Monitor ──────────────────────────────────────────

    def get_live_monitor(self, session_id: int) -> Optional[MonitorResponse]:
        """
        Return a full live snapshot of all students in a session:
        heartbeat state, run count, submission status.
        """
        session = self.session_repo.get_by_id(session_id)
        if not session:
            return None

        assignments = self.assignment_repo.get_all_for_session(session_id)
        # Consider online = last heartbeat within 90 seconds
        online_threshold = now_ist() - timedelta(seconds=90)

        student_statuses: List[StudentLiveStatus] = []
        online_count = 0
        submitted_count = 0

        for a in assignments:
            student = a.student
            if not student:
                continue

            hb = self.heartbeat_repo.get_by_student_and_session(
                student.id, session_id
            )
            sub = self.submission_repo.get_by_student_and_session(
                student.id, session_id
            )
            latest_run = self.run_log_repo.get_latest_for_student_session(
                student.id, session_id
            )

            # Run count
            run_logs = self.run_log_repo.get_all_for_student_session(
                student.id, session_id
            )
            run_count = len(run_logs)

            is_online = False
            last_seen_at = None
            machine_name = None
            machine_ip = None
            client_state = None

            if hb:
                last_seen_at = hb.last_seen_at
                machine_name = hb.machine_name
                machine_ip = hb.machine_ip
                client_state = hb.client_state
                # Compare timezone-aware datetimes
                if hb.last_seen_at:
                    hb_time = hb.last_seen_at
                    if hb_time.tzinfo is None:
                        hb_time = hb_time.replace(tzinfo=IST)
                    is_online = hb_time >= online_threshold

            if is_online:
                online_count += 1
            if sub:
                submitted_count += 1

            question_title = a.question.title if a.question else None

            student_statuses.append(
                StudentLiveStatus(
                    registration_number=student.registration_number,
                    name=student.name,
                    year=student.year,
                    section=student.section,
                    machine_name=machine_name,
                    machine_ip=machine_ip,
                    client_state=client_state,
                    last_seen_at=last_seen_at,
                    question_title=question_title,
                    run_count=run_count,
                    submitted=sub is not None,
                    has_submitted=sub is not None,   # dashboard JS uses this
                    is_online=is_online,              # dashboard JS uses this
                    last_exit_code=latest_run.exit_code if latest_run else None,
                )
            )

        status_val = session.status.value if hasattr(session.status, "value") else str(session.status)
        return MonitorResponse(
            session_id=session.id,
            session_title=session.title,
            session_status=status_val,
            total_students=len(student_statuses),
            online_count=online_count,
            submitted_count=submitted_count,
            students=student_statuses,
        )

    # ── Submissions ───────────────────────────────────────────

    def list_submissions(self, session_id: int) -> List[SubmissionAdminOut]:
        """List all final submissions for a session with student/question details."""
        submissions = (
            self.db.query(Submission)
            .filter(Submission.session_id == session_id)
            .all()
        )
        result = []
        for sub in submissions:
            student = self.student_repo.get_by_id(sub.student_id)
            question = self.question_repo.get_by_id(sub.question_id)
            result.append(
                SubmissionAdminOut(
                    id=sub.id,
                    session_id=sub.session_id,
                    student_id=sub.student_id,
                    registration_number=student.registration_number if student else None,
                    student_name=student.name if student else None,
                    student_department=student.department if student else None,
                    student_year=student.year if student else None,
                    student_section=student.section if student else None,
                    question_id=sub.question_id,
                    question_title=question.title if question else None,
                    source_code=sub.source_code,
                    exit_code=sub.exit_code,
                    final_status=sub.final_status,
                    submitted_at=sub.submitted_at,
                    submission_type=sub.submission_type or "normal",
                    submit_count=sub.submit_count or 1,
                )
            )
        return result
