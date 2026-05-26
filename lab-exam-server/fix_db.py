import sqlite3
import json

conn = sqlite3.connect('data/lab_exam.db')
c = conn.cursor()

# Sum of two numbers
test_cases_1 = [
    {"input": "10\n20", "output": "30", "marks": 50},
    {"input": "-4\n7", "output": "3", "marks": 50}
]
visible_examples_1 = [
    {"input": "3\n5", "output": "8"}
]

c.execute("UPDATE questions SET test_cases_json=?, visible_examples_json=? WHERE id=1", (json.dumps(test_cases_1), json.dumps(visible_examples_1)))

# Print N Even Numbers
test_cases_2 = [
    {"input": "1", "output": "2", "marks": 50},
    {"input": "5", "output": "2 4 6 8 10", "marks": 50}
]
visible_examples_2 = [
    {"input": "3", "output": "2 4 6"}
]

c.execute("UPDATE questions SET test_cases_json=?, visible_examples_json=? WHERE id=2", (json.dumps(test_cases_2), json.dumps(visible_examples_2)))

conn.commit()
conn.close()
