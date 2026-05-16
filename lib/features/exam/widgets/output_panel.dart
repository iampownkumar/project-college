// ============================================================
// File: lib/features/exam/widgets/output_panel.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-16
// Location: Tamil Nadu, India
// Description: Terminal-style output panel with two tabs:
//              1. Output — STDOUT/STDERR from manual run
//              2. Test Cases — pass/fail for each visible_example
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../exam_provider.dart';

class OutputPanel extends StatefulWidget {
  const OutputPanel({super.key});

  @override
  State<OutputPanel> createState() => _OutputPanelState();
}

class _OutputPanelState extends State<OutputPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final result = exam.lastResult;
    final isRunning = exam.status == ExamStatus.running;
    final bgColor = isDark ? const Color(0xFF11111B) : const Color(0xFFF1F5F9);
    final textColor = isDark ? const Color(0xFFCDD6F4) : const Color(0xFF1E293B);

    // Test case summary for tab badge
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
              color: isDark ? const Color(0xFF181825) : const Color(0xFFE2E8F0),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
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
                  unselectedLabelStyle:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  tabs: [
                    const Tab(text: 'Output'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Test Cases'),
                          if (exam.isTestingCases) ...[
                            const SizedBox(width: 6),
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
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
                // Runtime badges (shown on Output tab only)
                if (result != null) ...[
                  _MetaBadge(
                    label: 'Exit: ${result.exitCode}',
                    color: result.isSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _MetaBadge(
                    label: '${result.durationMs} ms',
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isRunning)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ),
              ],
            ),
          ),

          // ── Tab views ──────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab 0: Manual Run Output
                _OutputTab(
                  result: result,
                  isRunning: isRunning,
                  textColor: textColor,
                  scrollCtrl: _scrollCtrl,
                ),
                // Tab 1: Test Cases
                _TestCasesTab(
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

// ── Output Tab ────────────────────────────────────────────────────────────────

class _OutputTab extends StatelessWidget {
  final dynamic result;
  final bool isRunning;
  final Color textColor;
  final ScrollController scrollCtrl;

  const _OutputTab({
    required this.result,
    required this.isRunning,
    required this.textColor,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    if (isRunning) {
      return const Center(
          child: Text('Running…', style: TextStyle(fontFamily: 'monospace')));
    }
    if (result == null) {
      return Center(
        child: Text(
          'Press Run ▶ or Ctrl+Enter to execute your code.',
          style: TextStyle(
            color: textColor.withOpacity(0.4),
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.stdout.isNotEmpty) ...[
            _OutputSection(
                label: 'STDOUT', content: result.stdout, color: textColor),
            const SizedBox(height: 12),
          ],
          if (result.stderr.isNotEmpty)
            _OutputSection(
                label: 'STDERR',
                content: result.stderr,
                color: const Color(0xFFEF4444)),
          if (result.stdout.isEmpty && result.stderr.isEmpty)
            Text(
              '(No output)',
              style: TextStyle(
                  color: textColor.withOpacity(0.4),
                  fontFamily: 'monospace',
                  fontSize: 13),
            ),
        ],
      ),
    );
  }
}

// ── Test Cases Tab ────────────────────────────────────────────────────────────

class _TestCasesTab extends StatelessWidget {
  final ExamProvider exam;
  final Color textColor;
  final bool isDark;

  const _TestCasesTab({
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
      // Check if the question even has examples
      final hasExamples =
          exam.question != null && exam.question!.visibleExamples.isNotEmpty;
      return Center(
        child: Text(
          hasExamples
              ? 'Run your code ▶ to evaluate test cases.'
              : 'No test cases defined for this question.',
          style: TextStyle(
            color: textColor.withOpacity(0.45),
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
        // Summary row
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: passCount == tests.length
                ? const Color(0xFF10B981).withOpacity(0.12)
                : const Color(0xFFEF4444).withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: passCount == tests.length
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFFEF4444).withOpacity(0.25),
            ),
          ),
          child: Row(children: [
            Icon(
              passCount == tests.length
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              size: 18,
              color: passCount == tests.length
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            Text(
              '$passCount / ${tests.length} test cases passed',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: passCount == tests.length
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ]),
        ),
        // Individual test cases
        ...tests.map((t) => _TestCaseCard(t: t, isDark: isDark)),
      ],
    );
  }
}

class _TestCaseCard extends StatelessWidget {
  final TestCaseResult t;
  final bool isDark;
  const _TestCaseCard({required this.t, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final passColor = const Color(0xFF10B981);
    final failColor = const Color(0xFFEF4444);
    final cardColor = t.passed
        ? passColor.withOpacity(0.06)
        : failColor.withOpacity(0.06);
    final borderColor = t.passed
        ? passColor.withOpacity(0.25)
        : failColor.withOpacity(0.25);
    final mono = const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding:
            const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                ? passColor.withOpacity(0.7)
                : failColor.withOpacity(0.7),
          ),
        ),
        initiallyExpanded: !t.passed, // auto-expand failed cases
        children: [
          _TcRow('Input', t.input, mono),
          const SizedBox(height: 6),
          _TcRow('Expected', t.expected, mono.copyWith(color: passColor)),
          if (!t.passed) ...[
            const SizedBox(height: 6),
            _TcRow('Your Output', t.actual, mono.copyWith(color: failColor)),
          ],
          if (t.stderr.isNotEmpty) ...[
            const SizedBox(height: 6),
            _TcRow('stderr', t.stderr, mono.copyWith(color: const Color(0xFFEF4444))),
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
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: style.color?.withOpacity(0.65) ?? Colors.grey,
              )),
          const SizedBox(height: 3),
          SelectableText(
            value.isEmpty ? '(empty)' : value,
            style: style,
          ),
        ],
      );
}

// ── Shared widgets ────────────────────────────────────────────────────────────

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
            ? const Color(0xFF10B981).withOpacity(0.15)
            : const Color(0xFFEF4444).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        allPass ? '✓ $pass/$pass' : '$pass/${pass + fail}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: allPass ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      ),
    );
  }
}

class _OutputSection extends StatelessWidget {
  final String label;
  final String content;
  final Color color;

  const _OutputSection(
      {required this.label, required this.content, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color.withOpacity(0.6),
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          SelectableText(
            content,
            style: TextStyle(
                fontFamily: 'monospace', fontSize: 13, color: color, height: 1.5),
          ),
        ],
      );
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MetaBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'monospace')),
      );
}
