import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "data", "lab_exam.db")

def migrate():
    print(f"Migrating database at {DB_PATH}...")
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    # Check if test_cases_json exists in questions table
    cur.execute("PRAGMA table_info(questions)")
    columns = [col[1] for col in cur.fetchall()]
    
    if "test_cases_json" not in columns:
        print("Adding test_cases_json column to questions table...")
        cur.execute("ALTER TABLE questions ADD COLUMN test_cases_json TEXT")
        print("Migration successful.")
    else:
        print("Column test_cases_json already exists.")
        
    conn.commit()
    conn.close()

if __name__ == "__main__":
    migrate()
