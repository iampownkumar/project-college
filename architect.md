# Local Lab Exam System - Full Architecture Specification
# Target: Linux-first build
# Current priority: Build the coordinator server first
# Important: Do NOT design around macOS-specific paths, commands, or assumptions.
# The system must be portable, but the first real deployment target is Linux (Arch Linux local server).

---

## 1. Project goal

Build a local-network programming lab exam system for colleges.

The system architecture must support:
- one local Linux coordinator server,
- many student client machines in the same LAN,
- centralized login verification, question assignment, exam timing, logging, and submission storage,
- local execution of student code on each client machine,
- future Flutter desktop client for Windows and Linux,
- future multi-language support,
- but for MVP: Python only.

The first deliverable is the **Linux coordinator server only**.

---

## 2. Core architecture

### 2.1 Coordinator server
Runs on a Linux machine in the lab network.

Responsibilities:
- verify student registration number,
- manage active exam sessions,
- assign a question to each student,
- serve question content to the client,
- receive heartbeats from clients,
- receive run logs from clients,
- receive final submissions,
- store all data persistently,
- support future faculty/admin dashboard.

The coordinator server does NOT execute student code in MVP.
Student code execution happens locally on each client machine later.

### 2.2 Student client (future)
The student client will be built later as a Flutter desktop app.

Responsibilities:
- registration number login,
- fetch assigned question,
- show fullscreen exam UI,
- local code editor,
- local Python execution using bundled Python runtime,
- send run logs and final submission to the server,
- heartbeat to server.

### 2.3 Local execution strategy
For MVP planning, assume:
- Python code runs on each student machine locally,
- server is only for coordination and storage,
- this avoids overloading one central machine.

---

## 3. Immediate scope

Build the server first.

Required in this phase:
- Linux-first FastAPI backend,
- SQLite database,
- registration verification API,
- active session lookup API,
- assigned question API,
- heartbeat API,
- run-log API,
- final submission API,
- clean project structure,
- seed data support,
- Linux-friendly development and deployment.

Do NOT generate client code yet.

---

## 4. Python-only MVP

Only Python is supported in the first working version.

Future client machines will use a bundled Python environment with these required packages:
- pandas
- numpy
- matplotlib
- seaborn

These packages are mandatory for the Python client runtime design because faculty may assign problems requiring them.

The architecture must preserve:
- pinned dependency versions,
- requirements.txt support,
- offline packaging support,
- identical environment across all student machines.

For now, the server only needs to know that the assigned language is Python.

---

## 5. Deployment target

### Current real deployment target
- Linux server
- Arch Linux
- KDE Plasma desktop environment may exist, but backend must remain desktop-environment agnostic
- Local LAN deployment
- Linux-native file paths, environment config, and service model

### Important
- Do not use macOS-specific file paths like /Users/...
- Do not assume macOS shell behavior
- Do not include Apple-specific tooling
- Design for Linux runtime first

### Portability goal
The architecture should remain portable so the future Flutter client can work on:
- Windows
- Linux

---

## 6. Design principles

- Linux-first backend
- server-first implementation
- clear separation of coordinator and client
- REST API first
- SQLite first, PostgreSQL-ready later
- modular structure
- typed validation and clean schemas
- easy local deployment
- no cloud requirement
- no internet requirement for exam operation
- maintainable and AI-friendly code structure

---

## 7. Recommended backend stack

Use:
- Python 3.12+
- FastAPI
- Uvicorn
- SQLAlchemy
- Pydantic
- SQLite
- python-dotenv

Optional later:
- Alembic
- PostgreSQL
- WebSockets
- auth token layer
- admin auth

---

## 8. Functional requirements

### 8.1 Student verification
The client sends:
- registration_number
- machine_name
- machine_ip
- client_version

The server verifies:
- student exists,
- student is enabled,
- student belongs to active session,
- student has assigned question,
- submission policy allows login.

The server returns:
- success or failure,
- student details,
- session details,
- assigned question summary.

### 8.2 Session management
A session contains:
- id
- title
- department
- batch or section
- language
- start time
- end time
- duration
- status (draft, active, closed)

For MVP, assume one active Python session at a time is enough.

### 8.3 Question assignment
For MVP, use direct mapping:
- registration_number -> assigned question

Each question contains:
- id
- language
- title
- statement
- starter_code
- visible_examples
- optional constraints
- metadata JSON

### 8.4 Heartbeat
Each client periodically sends:
- registration_number
- session_id
- machine_name
- machine_ip
- client_state
- timestamp

Purpose:
- live monitoring
- attendance/tracking
- session visibility

### 8.5 Run logs
Each time the student clicks Run on the future client:
- the client executes code locally,
- the client sends run details to server.

Log payload includes:
- registration_number
- session_id
- question_id
- source_code
- stdout
- stderr
- exit_code
- duration_ms
- timestamp

### 8.6 Final submission
When the student submits:
- server stores final code
- stores latest output metadata
- stores submit time
- stores final state

---

## 9. Data model

Use SQLite with SQLAlchemy models.

### 9.1 Student
Fields:
- id
- registration_number (unique)
- name
- department
- batch
- section
- enabled
- created_at
- updated_at

### 9.2 Session
Fields:
- id
- title
- department
- language
- start_time
- end_time
- duration_minutes
- status
- created_at
- updated_at

### 9.3 Question
Fields:
- id
- session_id
- language
- title
- statement
- starter_code
- visible_examples_json
- constraints_json
- metadata_json
- created_at
- updated_at

### 9.4 QuestionAssignment
Fields:
- id
- session_id
- student_id
- question_id
- assigned_at

### 9.5 Heartbeat
Fields:
- id
- session_id
- student_id
- machine_name
- machine_ip
- client_state
- last_seen_at

### 9.6 RunLog
Fields:
- id
- session_id
- student_id
- question_id
- source_code
- stdout
- stderr
- exit_code
- duration_ms
- created_at

### 9.7 Submission
Fields:
- id
- session_id
- student_id
- question_id
- source_code
- stdout
- stderr
- exit_code
- submitted_at
- final_status
- score_json

---

## 10. API contract

Base prefix:
`/api/v1`

### GET /api/v1/health
Return:
- status
- server_time
- version

### POST /api/v1/auth/login
Request:
```json
{
  "registration_number": "1234567890",
  "machine_name": "LAB-PC-01",
  "machine_ip": "192.168.1.21",
  "client_version": "0.1.0"
}
```

Response:
```json
{
  "success": true,
  "message": "Login successful",
  "student": {},
  "session": {},
  "assignment": {}
}
```

### GET /api/v1/session/current/{registration_number}
Return active session for that student.

### GET /api/v1/question/assigned/{registration_number}
Return assigned question for that student.

### POST /api/v1/heartbeat
Request:
```json
{
  "registration_number": "1234567890",
  "session_id": 1,
  "machine_name": "LAB-PC-01",
  "machine_ip": "192.168.1.21",
  "client_state": "editing",
  "timestamp": "2026-05-15T11:00:00Z"
}
```

### POST /api/v1/run-log
Request:
```json
{
  "registration_number": "1234567890",
  "session_id": 1,
  "question_id": 1,
  "source_code": "print('Hello')",
  "stdout": "Hello\n",
  "stderr": "",
  "exit_code": 0,
  "duration_ms": 52,
  "timestamp": "2026-05-15T11:02:00Z"
}
```

### POST /api/v1/submission
Request:
```json
{
  "registration_number": "1234567890",
  "session_id": 1,
  "question_id": 1,
  "source_code": "print('Hello')",
  "stdout": "Hello\n",
  "stderr": "",
  "exit_code": 0,
  "submitted_at": "2026-05-15T11:10:00Z"
}
```

### GET /api/v1/student/status/{registration_number}
Return:
- active session state
- latest heartbeat
- latest run
- submission state

---

## 11. Recommended project structure

```text
lab-exam-server/
  app/
    main.py
    api/
      routes/
        health.py
        auth.py
        sessions.py
        questions.py
        heartbeat.py
        run_logs.py
        submissions.py
    core/
      config.py
      database.py
      logging.py
    db/
      base.py
      session.py
    models/
      student.py
      session.py
      question.py
      question_assignment.py
      heartbeat.py
      run_log.py
      submission.py
    schemas/
      common.py
      auth.py
      session.py
      question.py
      heartbeat.py
      run_log.py
      submission.py
    services/
      auth_service.py
      session_service.py
      question_service.py
      heartbeat_service.py
      run_log_service.py
      submission_service.py
    repositories/
      student_repo.py
      session_repo.py
      question_repo.py
      assignment_repo.py
      heartbeat_repo.py
      run_log_repo.py
      submission_repo.py
  data/
    seed/
      students.csv
      sessions.json
      questions/
        python/
          q1.json
          q2.json
  scripts/
    seed_data.py
    run_dev.sh
  tests/
  .env
  requirements.txt
  README.md
```

---

## 12. Seed data design

Provide seed data support.

### students.csv
Columns:
- registration_number
- name
- department
- batch
- section
- enabled

### sessions.json
Contains sample active Python session.

### question JSON example
```json
{
  "id": "py_q1",
  "language": "python",
  "title": "Print Hello Lab",
  "statement": "Write a Python program to print Hello Lab.",
  "starter_code": "print('Hello Lab')",
  "visible_examples": [
    {
      "input": "",
      "output": "Hello Lab"
    }
  ],
  "constraints": [
    "Use Python only"
  ],
  "metadata": {
    "difficulty": "easy"
  }
}
```

---

## 13. Linux-specific implementation requirements

- Must run cleanly on Arch Linux
- Must use Linux-friendly relative/configurable paths
- Must support `.env` config
- Must support local dev with uvicorn
- Must be easy to convert into systemd service later
- Must not depend on macOS-only shell commands
- Must not hardcode Apple paths or tools
- Must be suitable for LAN-only deployment

---

## 14. Non-goals for this phase

Do NOT build:
- Flutter client
- code editor
- local Python execution wrapper
- C/C++/Java support
- SSH-based communication
- anti-cheat enforcement
- fullscreen or kiosk mode
- hidden test case evaluation on server
- production remote updater
- cloud deployment

This phase is server only.

---

## 15. Required output

Generate a complete Linux-first FastAPI backend codebase with:
- modular folder structure,
- config management,
- SQLAlchemy models,
- Pydantic schemas,
- route registration,
- repositories/services,
- SQLite integration,
- seed-data loading,
- all listed endpoints,
- ready-to-run local development setup,
- clean readable code,
- no macOS assumptions.

Also generate:
- requirements.txt
- .env.example
- README with Linux setup instructions only
- simple seed script
- sample data files

---

## 16. Future roadmap note

Do not implement now, but keep architecture compatible with future Flutter client:
- login screen
- question fetch
- fullscreen exam UI
- local Python runtime
- required Python packages:
  - pandas
  - numpy
  - matplotlib
  - seaborn

These packages are part of the future bundled Python environment for student machines.

---

## 17. Final instruction

Generate only the server project now.
Do not generate client code.
Do not use macOS-specific instructions.
Design the system for Linux-first deployment and future portability.