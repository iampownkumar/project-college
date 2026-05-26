// ============================================================
// File: lib/core/utils/time_utils.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Utility functions for formatting time values used
//              across the app (countdown timer display, etc.).
// ============================================================

abstract final class TimeUtils {
  TimeUtils._();

  /// Formats a [Duration] as `HH:MM:SS` with zero-padded fields.
  ///
  /// Example: `Duration(minutes: 75, seconds: 9)` → `"01:15:09"`
  static String formatCountdown(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}
