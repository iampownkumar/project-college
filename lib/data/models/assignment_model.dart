// ============================================================
// File: lib/data/models/assignment_model.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Dart model representing a student's question assignment,
//              mapped from the POST /auth/login JSON response `assignment` object.
// ============================================================

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
