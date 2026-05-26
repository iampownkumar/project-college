import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "data", "lab_exam.db")

def migrate():
    print(f"Migrating database at {DB_PATH}...")
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    cur.execute("PRAGMA table_info(students)")
    columns = [col[1] for col in cur.fetchall()]
    
    if "year" not in columns:
        print("Adding year column to students table...")
        cur.execute("ALTER TABLE students ADD COLUMN year TEXT NOT NULL DEFAULT '1st'")
        print("Migration successful.")
    else:
        print("Column year already exists.")
        
    conn.commit()
    conn.close()

if __name__ == "__main__":
    migrate()
