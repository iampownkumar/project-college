// ============================================================
// File: lib/data/models/login_response_model.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Dart models mapping POST /auth/login JSON response
//              to StudentModel, SessionModel, AssignmentModel, LoginResponseModel.
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

class SessionModel {
  final int id;
  final String title;
  final String department;
  final String language;
  final int durationMinutes;
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;

  const SessionModel({
    required this.id,
    required this.title,
    required this.department,
    required this.language,
    required this.durationMinutes,
    required this.status,
    this.startTime,
    this.endTime,
  });

  factory SessionModel.fromJson(Map<String, dynamic> j) => SessionModel(
        id: j['id'] as int,
        title: j['title'] as String,
        department: j['department'] as String,
        language: j['language'] as String,
        durationMinutes: j['duration_minutes'] as int,
        status: j['status'] as String,
        startTime: j['start_time'] != null ? DateTime.tryParse(j['start_time'] as String) : null,
        endTime: j['end_time'] != null ? DateTime.tryParse(j['end_time'] as String) : null,
      );
}

class AssignmentModel {
  final int questionId;
  final String questionTitle;
  final String language;

  const AssignmentModel({
    required this.questionId,
    required this.questionTitle,
    required this.language,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> j) => AssignmentModel(
        questionId: j['question_id'] as int,
        questionTitle: j['question_title'] as String,
        language: j['language'] as String,
      );
}

class LoginResponseModel {
  final bool success;
  final String message;
  final StudentModel? student;
  final SessionModel? session;
  final AssignmentModel? assignment;

  const LoginResponseModel({
    required this.success,
    required this.message,
    this.student,
    this.session,
    this.assignment,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> j) => LoginResponseModel(
        success: j['success'] as bool,
        message: j['message'] as String,
        student: j['student'] != null
            ? StudentModel.fromJson(j['student'] as Map<String, dynamic>)
            : null,
        session: j['session'] != null
            ? SessionModel.fromJson(j['session'] as Map<String, dynamic>)
            : null,
        assignment: j['assignment'] != null
            ? AssignmentModel.fromJson(j['assignment'] as Map<String, dynamic>)
            : null,
      );
}
