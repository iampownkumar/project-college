// ============================================================
// File: lib/data/models/login_response_model.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Dart model for the full POST /auth/login response.
//              Imports StudentModel, SessionModel, and AssignmentModel
//              from their own dedicated files and wraps them into the
//              top-level LoginResponseModel.
// ============================================================

export 'student_model.dart';
export 'session_model.dart';
export 'assignment_model.dart';

import 'student_model.dart';
import 'session_model.dart';
import 'assignment_model.dart';

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

  factory LoginResponseModel.fromJson(Map<String, dynamic> j) =>
      LoginResponseModel(
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
