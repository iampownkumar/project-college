#!/usr/bin/env python3
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "data", "lab_exam.db")

def migrate():
    if not os.path.exists(DB_PATH):
        return

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(100) UNIQUE NOT NULL,
        code VARCHAR(20) UNIQUE NOT NULL
    )
    """)
    
    # Extract existing unique departments from students and sessions
    cur.execute("SELECT DISTINCT department FROM students WHERE department IS NOT NULL")
    existing_depts = {row[0] for row in cur.fetchall()}
    cur.execute("SELECT DISTINCT department FROM exam_sessions WHERE department IS NOT NULL")
    existing_depts.update(row[0] for row in cur.fetchall())

    for dept in existing_depts:
        try:
            code = dept.strip().upper()
            cur.execute("INSERT OR IGNORE INTO departments (name, code) VALUES (?, ?)", (dept, code))
        except Exception:
            pass

    conn.commit()
    conn.close()
    print("✅ Departments table created and populated.")

if __name__ == "__main__":
    migrate()
