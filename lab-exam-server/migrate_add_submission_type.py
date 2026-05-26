#!/usr/bin/env python3
"""
migrate_add_submission_type.py
Adds new columns to existing SQLite database without full drop-recreate.
Run once: python migrate_add_submission_type.py
"""
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "data", "lab_exam.db")

def migrate():
    if not os.path.exists(DB_PATH):
        print(f"DB not found at {DB_PATH} — will be created fresh on next server start.")
        return

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Get existing columns
    cur.execute("PRAGMA table_info(submissions)")
    existing = {row[1] for row in cur.fetchall()}

    added = []
    if "submission_type" not in existing:
        cur.execute("ALTER TABLE submissions ADD COLUMN submission_type TEXT DEFAULT 'normal'")
        added.append("submission_type")
    if "submit_count" not in existing:
        cur.execute("ALTER TABLE submissions ADD COLUMN submit_count INTEGER NOT NULL DEFAULT 1")
        added.append("submit_count")
    if "updated_at" not in existing:
        cur.execute("ALTER TABLE submissions ADD COLUMN updated_at DATETIME")
        added.append("updated_at")

    conn.commit()
    conn.close()

    if added:
        print(f"✅ Migration done. Added columns: {', '.join(added)}")
    else:
        print("ℹ️  All columns already exist. No migration needed.")

if __name__ == "__main__":
    migrate()
