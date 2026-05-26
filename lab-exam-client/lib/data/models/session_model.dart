// ============================================================
// File: lib/data/models/session_model.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Dart model representing an exam session, mapped
//              from the POST /auth/login JSON response `session` object.
// ============================================================

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
        startTime: j['start_time'] != null
            ? DateTime.tryParse(j['start_time'] as String)
            : null,
        endTime: j['end_time'] != null
            ? DateTime.tryParse(j['end_time'] as String)
            : null,
      );
}
