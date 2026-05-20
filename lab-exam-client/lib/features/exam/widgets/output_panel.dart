// ============================================================
// File: lib/features/exam/widgets/output_panel.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-20
// Location: Tamil Nadu, India
// Description: VS Code-style unified output panel.
//   Tab 0: Console — _InlineTerminal widget.
//           When running interactively, output streams line by line
//           and the cursor appears inline — you type directly in the
//           console just like VS Code. No separate input box.
//   Tab 1: Test Cases — automated pass/fail cards.
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

    final bgColor = isDark ? const Color(0xFF11111B) : const Color(0xFFF8FAFC);
    final consoleBg = isDark ? const Color(0xFF0D0D14) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFCDD6F4) : const Color(0xFF1E293B);

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
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Console'),
                          if (exam.isInteractiveRunning) ...[
                            const SizedBox(width: 6),
                            const SizedBox(
                              width: 8, height: 8,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Test Cases'),
                          if (exam.isTestingCases) ...[
                            const SizedBox(width: 6),
                            const SizedBox(
                              width: 8, height: 8,
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
                if (exam.isInteractiveRunning) ...[
                  _MetaBadge(label: 'RUNNING', color: const Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                ] else if (exam.lastResult != null && exam.consoleLines.isEmpty) ...[
                  _MetaBadge(
                    label: 'Exit: ${exam.lastResult!.exitCode}',
                    color: exam.lastResult!.isSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _MetaBadge(
                    label: '${exam.lastResult!.durationMs} ms',
                    color: const Color(0xFF3B82F6),
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
                _InlineTerminal(
                  exam: exam,
                  textColor: textColor,
                  consoleBg: consoleBg,
                  isDark: isDark,
                ),
                // Tab 1: Automated test cases
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

// ── Inline Terminal ────────────────────────────────────────────────────────────
// VS Code-style: output streams into the console, and when input() is called,
// the cursor simply appears at the bottom. You type there and press Enter.
// No popup, no separate text field — pure terminal experience.

class _InlineTerminal extends StatefulWidget {
  final ExamProvider exam;
  final Color textColor;
  final Color consoleBg;
  final bool isDark;

  const _InlineTerminal({
    required this.exam,
    required this.textColor,
    required this.consoleBg,
    required this.isDark,
  });

  @override
  State<_InlineTerminal> createState() => _InlineTerminalState();
}

class _InlineTerminalState extends State<_InlineTerminal> {
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients &&
          _scrollCtrl.position.hasContentDimensions &&
          _scrollCtrl.position.maxScrollExtent > 0) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submit() {
    final text = _textCtrl.text;
    widget.exam.sendConsoleInput(text);
    _textCtrl.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final textColor = widget.textColor;
    final isRunning = exam.isInteractiveRunning;
    final lines = exam.consoleLines;

    if (lines.isNotEmpty) _scrollToBottom();

    // ── Empty state ────────────────────────────────────────
    if (!isRunning && lines.isEmpty && exam.lastResult == null) {
      return Container(
        color: widget.consoleBg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal_rounded,
                  size: 32, color: textColor.withOpacity(0.2)),
              const SizedBox(height: 12),
              Text(
                'Click  Run Console  to run interactively,\nor  Run Tests  to check test cases.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(0.35),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Static result from Run Tests ───────────────────────
    if (!isRunning && lines.isEmpty && exam.lastResult != null) {
      final result = exam.lastResult!;
      return Container(
        color: widget.consoleBg,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SingleChildScrollView(
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
                Text('(No output)',
                    style: TextStyle(
                        color: textColor.withOpacity(0.4),
                        fontFamily: 'monospace',
                        fontSize: 13)),
            ],
          ),
        ),
      );
    }

    // ── Interactive terminal ───────────────────────────────
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        color: widget.consoleBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                itemCount: lines.length,
                itemBuilder: (context, index) {
                  final line = lines[index];
                  final isStderr = line.startsWith('STDERR:');
                  final isExit = line.startsWith('\n[Process');
                  return SelectableText(
                    line,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                      color: isStderr
                          ? const Color(0xFFEF4444)
                          : isExit
                              ? textColor.withOpacity(0.45)
                              : textColor,
                    ),
                  );
                },
              ),
            ),

            // Input line — blends directly with console output, no box border
            if (isRunning)
              Container(
                color: widget.consoleBg,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _textCtrl,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: textColor,
                    height: 1.5,
                  ),
                  cursorColor: const Color(0xFF8B5CF6),
                  cursorWidth: 2,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
          ],
        ),
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
      final hasExamples =
          exam.question != null && exam.question!.visibleExamples.isNotEmpty;
      return Center(
        child: Text(
          hasExamples
              ? 'Click  Run Tests  to evaluate your code.'
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
    const passColor = Color(0xFF10B981);
    const failColor = Color(0xFFEF4444);
    final cardColor = t.passed
        ? passColor.withOpacity(0.06)
        : failColor.withOpacity(0.06);
    final borderColor = t.passed
        ? passColor.withOpacity(0.25)
        : failColor.withOpacity(0.25);
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                ? passColor.withOpacity(0.7)
                : failColor.withOpacity(0.7),
          ),
        ),
        initiallyExpanded: !t.passed,
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
            _TcRow('stderr', t.stderr, mono.copyWith(color: failColor)),
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

// ── Shared widgets ─────────────────────────────────────────────────────────────

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
