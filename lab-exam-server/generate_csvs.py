import csv
import os

downloads_dir = "/Users/pownkumar/Downloads"

# Students CSV
students_csv_path = os.path.join(downloads_dir, "students_bulk_template.csv")
with open(students_csv_path, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["department", "section", "register number", "name", "year"])
    writer.writerow(["CSE", "A", "REG2026101", "Alice Johnson", "1st"])
    writer.writerow(["CSE", "A", "REG2026102", "Bob Smith", "1st"])
    writer.writerow(["CSE", "B", "REG2026201", "Charlie Davis", "2nd"])
    writer.writerow(["ECE", "A", "REG2026301", "Diana Prince", "3rd"])
    writer.writerow(["MECH", "B", "REG2026401", "Evan Wright", "4th"])

# Questions CSV
questions_csv_path = os.path.join(downloads_dir, "questions_bulk_template.csv")
with open(questions_csv_path, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow([
        "title", "statement", "starter_code", 
        "ex1_input", "ex1_output", 
        "test1_input", "test1_output", "test1_marks",
        "test2_input", "test2_output", "test2_marks"
    ])
    writer.writerow([
        "Sum of Two Numbers", 
        "Read two integers A and B from separate lines. Print their sum.", 
        "a = int(input())\nb = int(input())\n# write your solution\n",
        "3\n5", "8",
        "10\n20", "30", "50",
        "-4\n7", "3", "50"
    ])
    writer.writerow([
        "Print N Even Numbers", 
        "Read an integer N. Print the first N even numbers (starting from 2), each on a new line.", 
        "n = int(input())\n# write your solution\n",
        "3", "2\n4\n6",
        "5", "2\n4\n6\n8\n10", "40",
        "1", "2", "60"
    ])

print("CSVs generated successfully at", downloads_dir)
