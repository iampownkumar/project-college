// ============================================================
// File: lib/features/exam/widgets/timer_warning_banner.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-16
// Last Updated: 2026-05-16
// Location: Tamil Nadu, India
// Description: Animated warning banner displayed at the top of the
//              exam screen when the countdown timer reaches 30, 10,
//              or 5 minutes remaining. Auto-submits at 0:00.
//              Standard college exam client safety feature.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../exam_provider.dart';

class TimerWarningBanner extends StatelessWidget {
  const TimerWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();
    final warning = exam.timerWarning;

    if (warning == TimerWarning.none) return const SizedBox.shrink();

    final (color, icon, message) = switch (warning) {
      TimerWarning.thirtyMin => (
          const Color(0xFFF59E0B), // amber
          Icons.access_time_rounded,
          '⚠️  30 minutes remaining — save and review your solution.',
        ),
      TimerWarning.tenMin => (
          const Color(0xFFEF4444), // red
          Icons.timer_rounded,
          '🔴  10 minutes remaining — prepare to submit!',
        ),
      TimerWarning.fiveMin => (
          const Color(0xFFDC2626), // dark red
          Icons.warning_amber_rounded,
          '🚨  FINAL 5 MINUTES — submit now!',
        ),
      TimerWarning.expired => (
          const Color(0xFF7C3AED), // purple
          Icons.cloud_done_rounded,
          '⏰  Time is up! Your code has been auto-submitted.',
        ),
      TimerWarning.none => (Colors.transparent, Icons.info, ''),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.92),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          // Show focus-lost count as anti-cheat indicator
          if (exam.focusLostCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tab switches: ${exam.focusLostCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
