// ============================================================
// File: lib/features/exam/widgets/inline_terminal.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: VS Code-style inline terminal widget used inside the
//              Console tab of the OutputPanel. Streams interactive
//              process output line by line and allows direct keyboard
//              input at the bottom — no popup, no separate input box.
// ============================================================

import 'package:flutter/material.dart';
import '../exam_provider.dart';

class InlineTerminal extends StatefulWidget {
  final ExamProvider exam;
  final Color textColor;
  final Color consoleBg;
  final bool isDark;

  const InlineTerminal({
    super.key,
    required this.exam,
    required this.textColor,
    required this.consoleBg,
    required this.isDark,
  });

  @override
  State<InlineTerminal> createState() => _InlineTerminalState();
}

class _InlineTerminalState extends State<InlineTerminal> {
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
                  size: 32, color: textColor.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              Text(
                'Click  Run Console  to run interactively,\nor  Run Tests  to check test cases.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.35),
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
                Text(
                  '(No output)',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.4),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
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
                              ? textColor.withValues(alpha: 0.45)
                              : textColor,
                    ),
                  );
                },
              ),
            ),

            // Input line — blends directly with console output
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

// ── Private helpers (shared only within this file) ─────────────────────────

class _OutputSection extends StatelessWidget {
  final String label;
  final String content;
  final Color color;

  const _OutputSection({
    required this.label,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: color,
              height: 1.5,
            ),
          ),
        ],
      );
}
