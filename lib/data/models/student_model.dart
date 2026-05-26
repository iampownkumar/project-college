// ============================================================
// File: lib/data/models/student_model.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Dart model representing a student, mapped from the
//              POST /auth/login JSON response `student` object.
// ============================================================

class StudentModel {
  final int id;
  final String registrationNumber;
  final String name;
  final String department;
  final String batch;
  final String year;
  final String section;

  const StudentModel({
    required this.id,
    required this.registrationNumber,
    required this.name,
    required this.department,
    required this.batch,
    required this.year,
    required this.section,
  });

  factory StudentModel.fromJson(Map<String, dynamic> j) => StudentModel(
        id: j['id'] as int,
        registrationNumber: j['registration_number'] as String,
        name: j['name'] as String,
        department: j['department'] as String,
        batch: j['batch'] as String,
        year: j['year'] as String? ?? '1st',
        section: j['section'] as String,
      );
}
