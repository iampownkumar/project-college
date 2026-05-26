// ============================================================
// File: lib/app/theme.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Dark (Catppuccin-inspired) and Light themes with a
//              custom ExamColors ThemeExtension for panel-level colors.
// ============================================================

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Brand palette ─────────────────────────────────────────
  static const Color _brandBlue = Color(0xFF3B82F6);
  static const Color _brandGreen = Color(0xFF10B981);
  static const Color _brandAmber = Color(0xFFF59E0B);
  static const Color _brandRed = Color(0xFFEF4444);

  // ── Dark theme ────────────────────────────────────────────
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _brandBlue,
      secondary: _brandGreen,
      error: _brandRed,
      surface: Color(0xFF1E1E2E),
      onSurface: Color(0xFFCDD6F4),
    ),
    scaffoldBackgroundColor: const Color(0xFF1E1E2E),
    cardColor: const Color(0xFF313244),
    fontFamily: 'monospace',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181825),
      foregroundColor: Color(0xFFCDD6F4),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF313244),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _brandBlue, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF89B4FA)),
    ),
    extensions: const [ExamColors(
      panelBg: Color(0xFF181825),
      editorBg: Color(0xFF1E1E2E),
      outputBg: Color(0xFF11111B),
      topBarBg: Color(0xFF181825),
      divider: Color(0xFF45475A),
      success: _brandGreen,
      warning: _brandAmber,
      error: _brandRed,
    )],
  );

  // ── Light theme ───────────────────────────────────────────
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _brandBlue,
      secondary: _brandGreen,
      error: _brandRed,
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    cardColor: Colors.white,
    fontFamily: 'monospace',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E293B),
      elevation: 0,
      shadowColor: Color(0x10000000),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _brandBlue, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
    ),
    extensions: const [ExamColors(
      panelBg: Colors.white,
      editorBg: Color(0xFFFAFAFA),
      outputBg: Color(0xFFF1F5F9),
      topBarBg: Colors.white,
      divider: Color(0xFFE2E8F0),
      success: _brandGreen,
      warning: _brandAmber,
      error: _brandRed,
    )],
  );
}

/// Custom theme extension for exam-specific colors.
@immutable
class ExamColors extends ThemeExtension<ExamColors> {
  final Color panelBg;
  final Color editorBg;
  final Color outputBg;
  final Color topBarBg;
  final Color divider;
  final Color success;
  final Color warning;
  final Color error;

  const ExamColors({
    required this.panelBg,
    required this.editorBg,
    required this.outputBg,
    required this.topBarBg,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
  });

  @override
  ExamColors copyWith({
    Color? panelBg, Color? editorBg, Color? outputBg,
    Color? topBarBg, Color? divider,
    Color? success, Color? warning, Color? error,
  }) => ExamColors(
    panelBg: panelBg ?? this.panelBg,
    editorBg: editorBg ?? this.editorBg,
    outputBg: outputBg ?? this.outputBg,
    topBarBg: topBarBg ?? this.topBarBg,
    divider: divider ?? this.divider,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
  );

  @override
  ExamColors lerp(ExamColors? other, double t) => this;

  static ExamColors of(BuildContext context) =>
      Theme.of(context).extension<ExamColors>()!;
}


