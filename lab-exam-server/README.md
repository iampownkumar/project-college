# Lab Exam Server

**Author:** Pownkumar A (Founder of Korelium)  
**Created:** 2026-05-15  
**Last Updated:** 2026-05-15  
**Location:** Tamil Nadu, India  

---

## Overview

**Lab Exam Server** is the coordinator server for a local-network programming lab exam system built for colleges. It manages students, exam sessions, question assignments, live monitoring via heartbeats, run logs, and final submissions.

- **Target platform:** Linux (Arch Linux primary, any Linux supported)
- **Language:** Python 3.12+
- **Framework:** FastAPI + SQLAlchemy + SQLite
- **Deployment:** LAN-only, no internet required
- **Client:** Flutter desktop client (future, not in this scope)

---

## Project Structure

```
lab-exam-server/
├── app/
│   ├── main.py                  # FastAPI application factory
│   ├── api/
│   │   └── routes/
│   │       ├── health.py        # GET  /api/v1/health
│   │       ├── auth.py          # POST /api/v1/auth/login
│   │       ├── sessions.py      # GET  /api/v1/session/current/{reg}
│   │       ├── questions.py     # GET  /api/v1/question/assigned/{reg}
│   │       ├── heartbeat.py     # POST /api/v1/heartbeat
│   │       ├── run_logs.py      # POST /api/v1/run-log
│   │       └── submissions.py   # POST /api/v1/submission
│   │                            # GET  /api/v1/student/status/{reg}
│   ├── core/
│   │   ├── config.py            # App settings from .env
│   │   ├── database.py          # SQLAlchemy engine + session
│   │   └── logging.py           # Logging configuration
│   ├── db/
│   │   ├── base.py              # Declarative Base
│   │   └── session.py           # Session re-exports
│   ├── models/                  # SQLAlchemy ORM models
│   ├── schemas/                 # Pydantic request/response schemas
│   ├── services/                # Business logic layer
│   └── repositories/            # Data access layer
├── data/
│   └── seed/
│       ├── students.csv         # Student roster
│       ├── sessions.json        # Exam session definitions
│       └── questions/python/    # Python question JSON files
├── scripts/
│   ├── seed_data.py             # Database seeder script
│   └── run_dev.sh               # Dev server startup script
├── tests/
│   ├── test_health.py
│   └── test_auth.py
├── .env                         # Active config (do not commit)
├── .env.example                 # Config template
├── requirements.txt
└── README.md
```

---

## Linux Setup (Arch Linux)

### 1. Install Python 3.12+

```bash
sudo pacman -S python python-pip
```

Verify:

```bash
python3 --version
# Python 3.12.x or newer required
```

### 2. Clone or copy the project

Place the project anywhere. Example:

```bash
cd /opt
sudo mkdir lab-exam-server
sudo chown $USER:$USER lab-exam-server
cp -r /path/to/lab-exam-server /opt/lab-exam-server
cd /opt/lab-exam-server
```

### 3. Create virtual environment and install dependencies

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 4. Configure environment

```bash
cp .env.example .env
```

Edit `.env` if needed. Defaults work out-of-the-box:

```env
HOST=0.0.0.0
PORT=8000
DATABASE_URL=sqlite:///./data/lab_exam.db
```

### 5. Seed the database

This loads sample students, sessions, questions, and assigns questions to students:

```bash
python scripts/seed_data.py
```

### 6. Start the server

```bash
bash scripts/run_dev.sh
```

Or manually:

```bash
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 7. Access

- API Docs (Swagger): [http://localhost:8000/docs](http://localhost:8000/docs)
- ReDoc: [http://localhost:8000/redoc](http://localhost:8000/redoc)
- Health check: [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health)

From student machines on the same LAN, replace `localhost` with the server's LAN IP address (e.g., `192.168.1.100`).

---

## Running Tests

```bash
source venv/bin/activate
pip install pytest httpx
pytest tests/ -v
```

---

## API Reference

### Base URL

```
http://<server-ip>:8000/api/v1
```

| Method | Endpoint                                | Description                          |
|--------|-----------------------------------------|--------------------------------------|
| GET    | `/health`                               | Server health check                  |
| POST   | `/auth/login`                           | Student login and verification       |
| GET    | `/session/current/{registration_number}`| Get active session for student       |
| GET    | `/question/assigned/{registration_number}` | Get assigned question             |
| POST   | `/heartbeat`                            | Record client heartbeat              |
| POST   | `/run-log`                              | Record code run log                  |
| POST   | `/submission`                           | Final code submission                |
| GET    | `/student/status/{registration_number}` | Get full student exam status         |

---

## Converting to systemd Service (Optional)

Create `/etc/systemd/system/lab-exam-server.service`:

```ini
[Unit]
Description=Lab Exam Server
After=network.target

[Service]
Type=simple
User=your_user
WorkingDirectory=/opt/lab-exam-server
ExecStart=/opt/lab-exam-server/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable lab-exam-server
sudo systemctl start lab-exam-server
sudo systemctl status lab-exam-server
```

---

## Adding Custom Questions

1. Create a new JSON file in `data/seed/questions/python/`:

```json
{
  "id": "py_q3",
  "language": "python",
  "title": "Your Question Title",
  "statement": "Problem description here.",
  "starter_code": "# Starter code here\n",
  "visible_examples": [
    {"input": "5", "output": "25"}
  ],
  "constraints": ["Use Python only"],
  "metadata": {"difficulty": "medium", "marks": 20}
}
```

2. Run seed again — it skips existing records:

```bash
python scripts/seed_data.py
```

---

## Adding Students

Edit `data/seed/students.csv` and add rows, then run `python scripts/seed_data.py`.

---

## Design Notes

- SQLite is the default database. To switch to PostgreSQL, update `DATABASE_URL` in `.env`.
- One active session at a time is supported in MVP.
- Question assignment is round-robin by default in the seed script.
- No authentication tokens for the coordinator server in MVP — LAN isolation is assumed.
- Future Flutter client will use the same REST API without any changes.

---

## Future Roadmap (Not Implemented)

- Flutter desktop client (Windows + Linux)
- Local Python execution sandbox
- Hidden test case evaluation
- Faculty admin dashboard
- WebSocket-based live monitoring
- Token-based auth layer
- PostgreSQL migration
