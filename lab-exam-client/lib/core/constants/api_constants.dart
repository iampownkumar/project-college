// ============================================================
// File: lib/core/constants/api_constants.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: All server API endpoint path segments in one place.
//              Concatenated with base_url from app_config.json.
// ============================================================

class ApiConstants {
  ApiConstants._();

  static const String health = '/health';
  static const String login = '/auth/login';
  static const String currentSession = '/session/current';
  static const String assignedQuestion = '/question/assigned';
  static const String heartbeat = '/heartbeat';
  static const String runLog = '/run-log';
  static const String submission = '/submission';
}
