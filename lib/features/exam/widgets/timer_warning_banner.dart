// ============================================================
// File: lib/features/exam/widgets/timer_warning_banner.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-16
// Last Updated: 2026-05-16
// Location: Tamil Nadu, India
// Description: Warning banner at the top of the exam screen.
//              Shows timer warnings (30/10/5 min), alt-tab strike
//              counter, and LOCKED state after 3 violations.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../exam_provider.dart';

class TimerWarningBanner extends StatelessWidget {
  const TimerWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();

    // ── Locked banner (3 strikes hit) ────────────────────────
    if (exam.focusLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: const Color(0xFF7C3AED),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '🔒  EXAM LOCKED — You switched windows 3 times. Code auto-submitted.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Let student return to login for a new session
            TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                '/', (route) => false,
              ),
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 14),
              label: const Text(
                'Return to Login',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Strike counter (always visible after 1st violation) ──
    final strikes = exam.focusLostCount;
    final warning = exam.timerWarning;

    // Show strike warning if any strikes OR if timer warning active
    if (strikes == 0 && warning == TimerWarning.none) {
      return const SizedBox.shrink();
    }

    // Strike colour: 1=amber, 2=orange, 3=red
    Color strikeColor = strikes == 0
        ? Colors.transparent
        : strikes == 1
            ? const Color(0xFFF59E0B)
            : strikes == 2
                ? const Color(0xFFEA580C)
                : const Color(0xFFDC2626);

    // Timer banner colour overrides if more urgent
    final (timerColor, timerIcon, timerMsg) = switch (warning) {
      TimerWarning.thirtyMin => (
          const Color(0xFFF59E0B),
          Icons.access_time_rounded,
          '⚠️  30 minutes remaining',
        ),
      TimerWarning.tenMin => (
          const Color(0xFFEF4444),
          Icons.timer_rounded,
          '🔴  10 minutes remaining — prepare to submit!',
        ),
      TimerWarning.fiveMin => (
          const Color(0xFFDC2626),
          Icons.warning_amber_rounded,
          '🚨  FINAL 5 MINUTES — submit now!',
        ),
      TimerWarning.expired => (
          const Color(0xFF7C3AED),
          Icons.cloud_done_rounded,
          '⏰  Time is up! Code auto-submitted.',
        ),
      TimerWarning.none => (Colors.transparent, Icons.info, ''),
    };

    final bannerColor = warning != TimerWarning.none ? timerColor : strikeColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: bannerColor.withValues(alpha: 0.92),
      child: Row(
        children: [
          if (warning != TimerWarning.none) ...[
            Icon(timerIcon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              timerMsg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          const Spacer(),
          // Strike counter badge
          if (strikes > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tab_unselected_rounded,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'Tab switches: $strikes / 3',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
