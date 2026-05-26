// ============================================================
// File: lib/core/constants/app_colors.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Centralized color palette for the entire app.
//              All UI code must import from here — never hardcode
//              hex values inline. Change a brand color here once
//              and it propagates everywhere.
// ============================================================

import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────
  /// Primary brand purple — used for buttons, badges, accents.
  static const Color brand = Color(0xFF8B5CF6);

  // ── Semantic ──────────────────────────────────────────────
  /// Success green — pass badges, submit overlay, server-online dot.
  static const Color success = Color(0xFF10B981);

  /// Danger red — fail badges, error states, server-offline dot.
  static const Color danger = Color(0xFFEF4444);

  /// Warning amber — timer 10–30 min, non-fatal warnings.
  static const Color warning = Color(0xFFF59E0B);

  /// Info blue — submission button, duration badges.
  static const Color info = Color(0xFF3B82F6);

  // ── Dark-mode surfaces ────────────────────────────────────
  static const Color darkBg = Color(0xFF0D0D14);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF1E1E2E);
  static const Color darkBorder = Color(0xFF313244);
  static const Color darkConsoleBg = Color(0xFF11111B);
  static const Color darkStatusBar = Color(0xFF181825);

  // ── Light-mode surfaces ───────────────────────────────────
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightConsoleBg = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightStatusBar = Color(0xFFE2E8F0);

  // ── Text ─────────────────────────────────────────────────
  static const Color darkText = Color(0xFFCDD6F4);
  static const Color mutedText = Color(0xFF94A3B8);
  static const Color lightText = Color(0xFF1E293B);

  // ── Locked / disabled ────────────────────────────────────
  static const Color locked = Color(0xFF6B7280);
}
