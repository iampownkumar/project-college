// ============================================================
// File: lib/features/exam/widgets/test_cases_tab.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Test Cases tab content for the OutputPanel. Renders
//              pass/fail summary and an expandable card per test case.
//              Extracted from output_panel.dart for clarity.
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/test_case_result.dart';
import '../exam_provider.dart';

class TestCasesTab extends StatelessWidget {
  final ExamProvider exam;
  final Color textColor;
  final bool isDark;

  const TestCasesTab({
    super.key,
    required this.exam,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (exam.isTestingCases) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Running test cases…',
                style: TextStyle(fontFamily: 'monospace')),
          ],
        ),
      );
    }

    final tests = exam.testCaseResults;
    if (tests.isEmpty) {
      final hasExamples =
          exam.question != null && exam.question!.visibleExamples.isNotEmpty;
      return Center(
        child: Text(
          hasExamples
              ? 'Click  Run Tests  to evaluate your code.'
              : 'No test cases defined for this question.',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.45),
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      );
    }

    final passCount = tests.where((t) => t.passed).length;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: passCount == tests.length
                ? AppColors.success.withValues(alpha: 0.12)
                : AppColors.danger.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: passCount == tests.length
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.danger.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                passCount == tests.length
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 18,
                color: passCount == tests.length
                    ? AppColors.success
                    : AppColors.danger,
              ),
              const SizedBox(width: 8),
              Text(
                '$passCount / ${tests.length} test cases passed',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: passCount == tests.length
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
            ],
          ),
        ),
        ...tests.map((t) => _TestCaseCard(t: t, isDark: isDark)),
      ],
    );
  }
}

// ── Test case card ─────────────────────────────────────────────────────────

class _TestCaseCard extends StatelessWidget {
  final TestCaseResult t;
  final bool isDark;

  const _TestCaseCard({required this.t, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const passColor = AppColors.success;
    const failColor = AppColors.danger;
    final cardColor = t.passed
        ? passColor.withValues(alpha: 0.06)
        : failColor.withValues(alpha: 0.06);
    final borderColor = t.passed
        ? passColor.withValues(alpha: 0.25)
        : failColor.withValues(alpha: 0.25);
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(
          t.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: t.passed ? passColor : failColor,
          size: 20,
        ),
        title: Text(
          'Test Case ${t.index + 1}  •  ${t.durationMs} ms',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.passed ? passColor : failColor,
          ),
        ),
        subtitle: Text(
          t.passed ? 'Passed' : 'Failed',
          style: TextStyle(
            fontSize: 11,
            color: t.passed
                ? passColor.withValues(alpha: 0.7)
                : failColor.withValues(alpha: 0.7),
          ),
        ),
        initiallyExpanded: !t.passed,
        children: [
          _TcRow('Input', t.input, mono),
          const SizedBox(height: 6),
          _TcRow('Expected', t.expected,
              mono.copyWith(color: passColor)),
          if (!t.passed) ...[
            const SizedBox(height: 6),
            _TcRow('Your Output', t.actual,
                mono.copyWith(color: failColor)),
          ],
          if (t.stderr.isNotEmpty) ...[
            const SizedBox(height: 6),
            _TcRow('stderr', t.stderr,
                mono.copyWith(color: failColor)),
          ],
        ],
      ),
    );
  }
}

class _TcRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle style;

  const _TcRow(this.label, this.value, this.style);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: style.color?.withValues(alpha: 0.65) ?? Colors.grey,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value.isEmpty ? '(empty)' : value,
            style: style,
          ),
        ],
      );
}
