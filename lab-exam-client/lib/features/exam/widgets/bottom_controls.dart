// ============================================================
// File: lib/features/exam/widgets/bottom_controls.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Bottom action bar shown below the editor during an
//              active exam. Contains Run Console, Stop, Run Tests,
//              and Submit buttons with state-driven disable/lock logic.
//              Hidden entirely after exam submission (examLocked).
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../exam_provider.dart';

class BottomControls extends StatefulWidget {
  const BottomControls({super.key});

  @override
  State<BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<BottomControls> {
  Future<void> _confirmSubmit(ExamProvider exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Final Code?'),
        content: const Text(
          'Once submitted, you cannot edit or re-submit.\n'
          'The exam will be locked and you can only return to login.\n\n'
          'Are you sure you want to submit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.info,
            ),
            child: const Text('Submit Final'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await exam.submitCode();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${exam.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isConsoleRunning = exam.status == ExamStatus.consoleRunning;
    final isTestRunning = exam.status == ExamStatus.testRunning;
    final isAnyRunning = isConsoleRunning || isTestRunning;
    final isSubmitting = exam.status == ExamStatus.submitting;
    final isLocked = exam.focusLocked; // malpractice lock

    // Post-submit: hide all controls entirely — exam is done.
    if (exam.examLocked) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkStatusBar : Colors.white,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),

          // ── Run Console ───────────────────────────────────
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: (isAnyRunning || isLocked || exam.isInteractiveRunning)
                  ? null
                  : exam.startInteractiveRun,
              icon: exam.isInteractiveRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 1.5),
                    )
                  : Icon(
                      isLocked ? Icons.lock_rounded : Icons.terminal_rounded,
                      size: 18,
                    ),
              label: Text(
                exam.isInteractiveRunning
                    ? 'Running…'
                    : isLocked
                        ? 'Locked'
                        : 'Run Console',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLocked ? AppColors.locked : AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ),

          // ── Stop (only while interactive is running) ──────
          if (exam.isInteractiveRunning) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: exam.stopInteractiveRun,
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text('Stop',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),

          // ── Run Tests ─────────────────────────────────────
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: (isAnyRunning || isLocked || exam.isInteractiveRunning)
                  ? null
                  : exam.runCode,
              icon: isTestRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 1.5),
                    )
                  : Icon(
                      isLocked
                          ? Icons.lock_rounded
                          : Icons.play_arrow_rounded,
                      size: 18,
                    ),
              label: Text(
                isTestRunning
                    ? 'Testing…'
                    : isLocked
                        ? 'Locked'
                        : 'Run Tests',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLocked ? AppColors.locked : AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Submit ────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: (isSubmitting || isLocked)
                  ? null
                  : () => _confirmSubmit(exam),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 1.5),
                    )
                  : Icon(
                      isLocked ? Icons.lock_rounded : Icons.upload_rounded,
                      size: 18,
                    ),
              label: Text(
                isSubmitting
                    ? 'Submitting…'
                    : isLocked
                        ? 'Locked'
                        : 'Submit',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLocked ? AppColors.locked : AppColors.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
