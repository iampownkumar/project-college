#!/usr/bin/env python3
# ============================================================
# File: seed_python_test_session.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A
# Description: Seeds a Python test session with 5 questions
#              by calling the Admin API directly.
#              Run from the lab-exam-server directory.
# Usage:
#   python seed_python_test_session.py
#   python seed_python_test_session.py --base-url http://localhost:8000 --secret changeme-in-production
# ============================================================

import json
import sys
import argparse
from pathlib import Path

try:
    import requests
except ImportError:
    print("❌  'requests' not installed. Run: pip install requests")
    sys.exit(1)

# ── Config ────────────────────────────────────────────────────
DEFAULT_BASE_URL = "http://localhost:8000/api/v1"
DEFAULT_SECRET   = "changeme-in-production"
QUESTIONS_DIR    = Path("data/seed/questions/python")
QUESTION_FILES   = ["q3.json", "q4.json", "q5.json", "q6.json", "q7.json"]

SESSION_PAYLOAD = {
    "title": "Python Unit Test - Session 1",
    "department": "Computer Science",
    "language": "python",
    "duration_minutes": 90,
}

# ── Helpers ───────────────────────────────────────────────────
def ok(label: str):
    print(f"  ✅  {label}")

def fail(label: str, detail: str = ""):
    print(f"  ❌  {label}")
    if detail:
        print(f"      → {detail}")

def banner(text: str):
    print(f"\n{'─'*55}")
    print(f"  {text}")
    print(f"{'─'*55}")

# ── Main ──────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Seed Python test session + questions")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="Server base URL")
    parser.add_argument("--secret",   default=DEFAULT_SECRET,   help="Admin secret key")
    args = parser.parse_args()

    base_url = args.base_url.rstrip("/")
    headers  = {"X-Admin-Key": args.secret, "Content-Type": "application/json"}

    # ── 1. Health check ───────────────────────────────────────
    banner("Step 1 — Checking server health")
    try:
        r = requests.get(f"{base_url}/health", timeout=5)
        if r.status_code == 200:
            ok(f"Server is UP at {base_url}")
        else:
            fail("Server responded with non-200", r.text)
            sys.exit(1)
    except requests.exceptions.ConnectionError:
        fail(f"Cannot reach server at {base_url}")
        print("      → Make sure the server is running: bash scripts/run_dev.sh")
        sys.exit(1)

    # ── 2. Create session ─────────────────────────────────────
    banner("Step 2 — Creating exam session")
    r = requests.post(
        f"{base_url}/admin/session",
        headers=headers,
        json=SESSION_PAYLOAD,
        timeout=10,
    )
    if r.status_code not in (200, 201):
        fail("Failed to create session", r.text)
        sys.exit(1)

    session = r.json()
    session_id = session["id"]
    ok(f"Created session  id={session_id}  '{session['title']}'")
    print(f"      status={session['status']}  dept={session['department']}  duration={session['duration_minutes']}m")

    # ── 3. Upload questions ───────────────────────────────────
    banner("Step 3 — Uploading 5 Python questions")
    uploaded = []

    for fname in QUESTION_FILES:
        fpath = QUESTIONS_DIR / fname
        if not fpath.exists():
            fail(f"{fname} not found", str(fpath))
            continue

        q = json.loads(fpath.read_text())

        payload = {
            "session_id":       session_id,
            "language":         q.get("language", "python"),
            "title":            q["title"],
            "statement":        q["statement"],
            "starter_code":     q.get("starter_code"),
            "visible_examples": q.get("visible_examples", []),
            "test_cases":       q.get("test_cases", []),
            "constraints":      q.get("constraints", []),
            "metadata":         q.get("metadata", {}),
        }

        r = requests.post(
            f"{base_url}/admin/question",
            headers=headers,
            json=payload,
            timeout=10,
        )
        if r.status_code in (200, 201):
            qdata = r.json()
            ok(f"Q{len(uploaded)+1} [{fname}]  id={qdata['id']}  '{qdata['title']}'")
            uploaded.append(qdata)
        else:
            fail(f"Failed to upload {fname}", r.text[:200])

    # ── 4. Summary ────────────────────────────────────────────
    banner("Done!")
    print(f"  Session ID   : {session_id}")
    print(f"  Title        : {SESSION_PAYLOAD['title']}")
    print(f"  Questions    : {len(uploaded)}/5 uploaded")
    print()
    print("  Next steps:")
    print(f"  1. Activate the session via admin dashboard or:")
    print(f"     curl -X PUT {base_url}/admin/session/{session_id}/status \\")
    print(f"          -H 'X-Admin-Key: {args.secret}' \\")
    print(f"          -H 'Content-Type: application/json' \\")
    print(f"          -d '{{\"status\": \"active\"}}'")
    print(f"  2. Bulk-assign questions to students:")
    print(f"     curl -X POST {base_url}/admin/assignment/bulk \\")
    print(f"          -H 'X-Admin-Key: {args.secret}' \\")
    print(f"          -H 'Content-Type: application/json' \\")
    print(f"          -d '{{\"session_id\": {session_id}}}'")
    print()

if __name__ == "__main__":
    main()
