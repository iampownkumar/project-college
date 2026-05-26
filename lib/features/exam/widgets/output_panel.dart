// ============================================================
// File: lib/features/exam/widgets/output_panel.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: VS Code-style unified output panel with two tabs:
//   Tab 0 — Console: InlineTerminal widget for interactive runs.
//   Tab 1 — Test Cases: TestCasesTab widget for pass/fail results.
//   Sub-widgets have been extracted to inline_terminal.dart and
//   test_cases_tab.dart for maintainability.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../exam_provider.dart';
import 'inline_terminal.dart';
import 'test_cases_tab.dart';

class OutputPanel extends StatefulWidget {
  const OutputPanel({super.key});

  @override
  State<OutputPanel> createState() => _OutputPanelState();
}

class _OutputPanelState extends State<OutputPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor =
        isDark ? AppColors.darkConsoleBg : AppColors.lightBg;
    final consoleBg =
        isDark ? const Color(0xFF0D0D14) : AppColors.lightConsoleBg;
    final textColor =
        isDark ? AppColors.darkText : AppColors.lightText;

    final tests = exam.testCaseResults;
    final passCount = tests.where((t) => t.passed).length;
    final failCount = tests.length - passCount;

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header with TabBar ─────────────────────────────
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkStatusBar
                  : AppColors.lightStatusBar,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.terminal_rounded, size: 14),
                const SizedBox(width: 6),
                TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorColor: theme.colorScheme.primary,
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  tabs: [
                    // Console tab
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Console'),
                          if (exam.isInteractiveRunning) ...[
                            const SizedBox(width: 6),
                            const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Test Cases tab
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Test Cases'),
                          if (exam.isTestingCases) ...[
                            const SizedBox(width: 6),
                            const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5),
                            ),
                          ] else if (tests.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _TcBadge(passCount, failCount),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Status badges on right side of header
                if (exam.isInteractiveRunning) ...[
                  _MetaBadge(
                      label: 'RUNNING', color: AppColors.brand),
                  const SizedBox(width: 8),
                ] else if (exam.lastResult != null &&
                    exam.consoleLines.isEmpty) ...[
                  _MetaBadge(
                    label: 'Exit: ${exam.lastResult!.exitCode}',
                    color: exam.lastResult!.isSuccess
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  _MetaBadge(
                    label: '${exam.lastResult!.durationMs} ms',
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          // ── Tab Views ──────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab 0: VS Code-style inline terminal
                InlineTerminal(
                  exam: exam,
                  textColor: textColor,
                  consoleBg: consoleBg,
                  isDark: isDark,
                ),
                // Tab 1: Automated test cases
                TestCasesTab(
                  exam: exam,
                  textColor: textColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────────────────

class _TcBadge extends StatelessWidget {
  final int pass;
  final int fail;

  const _TcBadge(this.pass, this.fail);

  @override
  Widget build(BuildContext context) {
    final allPass = fail == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: allPass
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        allPass ? '✓ $pass/$pass' : '$pass/${pass + fail}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: allPass ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      );
}
