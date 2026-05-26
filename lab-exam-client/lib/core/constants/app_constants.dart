// ============================================================
// File: lib/core/constants/app_constants.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: App-wide constant values — app name, version,
//              SharedPreferences keys, default exam duration.
// ============================================================

class AppConstants {
  AppConstants._();

  static const String appName = 'Koreliurm Labs — Exam Client';
  static const String appVersion = '1.0.0';
  static const String clientVersion = '1.0.0';

  /// Autosave key prefix for SharedPreferences.
  static const String autosaveKeyPrefix = 'autosave_code_';

  /// Default timer duration when server does not specify end_time.
  static const int defaultExamDurationMinutes = 120;

  static const double minPanelWidth = 220.0;
}
