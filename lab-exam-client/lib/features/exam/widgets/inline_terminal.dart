// ============================================================
// File: lib/features/exam/widgets/inline_terminal.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: True interactive terminal inside the Console tab.
//              Renders all output (stdout + stderr) in a scrollable
//              monospace buffer. When the process is running, a blinking
//              cursor input line appears at the bottom — exactly like
//              a real terminal. The student types and presses Enter to
//              send each line to the Python process stdin.
//
//  Key behaviours:
//   - No separate "Custom Input" field needed.
//   - input("prompt") text appears in the output buffer because Python
//     writes it to stdout (unbuffered -u flag).
//   - After Enter, the typed line is echoed into the buffer with "> "
//     prefix so the student sees a natural conversation flow.
//   - Auto-scrolls to bottom on new output.
//   - Ctrl+C sends SIGTERM to stop the running process.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _InlineTerminalState extends State<InlineTerminal>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  // Blinking cursor animation
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_blinkCtrl);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients &&
          _scrollCtrl.position.hasContentDimensions &&
          _scrollCtrl.position.maxScrollExtent > 0) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitLine() {
    final text = _textCtrl.text;
    widget.exam.sendConsoleInput(text);
    _textCtrl.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _stopProcess() {
    widget.exam.stopInteractiveRun();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final textColor = widget.textColor;
    final isRunning = exam.isInteractiveRunning;
    final lines = exam.consoleLines;

    if (lines.isNotEmpty) _scrollToBottom();

    // ── Empty state ──────────────────────────────────────────
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
                'Click  Run Console  to run interactively.\n'
                'Your code runs live — type inputs directly here.',
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

    // ── Static result (after Run Tests / batch run) ──────────
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

    // ── Live interactive terminal ─────────────────────────────
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        color: widget.consoleBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Running indicator bar ──────────────────────────
            if (isRunning)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                color: const Color(0xFF1E1B2E),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.6),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RUNNING  —  type below and press Enter to send input',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.5),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _stopProcess,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          '■ Stop',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Output buffer ──────────────────────────────────
            Expanded(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  // Ctrl+C → stop process
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.keyC &&
                      HardwareKeyboard.instance.isControlPressed) {
                    _stopProcess();
                  }
                },
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final isStderr = line.startsWith('STDERR:');
                    final isInput = line.startsWith('> ');
                    final isExit = line.startsWith('\n[Process');
                    Color lineColor;
                    if (isStderr) {
                      lineColor = const Color(0xFFEF4444);
                    } else if (isInput) {
                      lineColor = const Color(0xFF818CF8); // violet for typed input
                    } else if (isExit) {
                      lineColor = textColor.withValues(alpha: 0.38);
                    } else {
                      lineColor = textColor;
                    }
                    return SelectableText(
                      line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.55,
                        color: lineColor,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Input line ─────────────────────────────────────
            if (isRunning)
              Container(
                color: widget.isDark
                    ? const Color(0xFF0F0E1A)
                    : const Color(0xFFF1F5F9),
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Blinking ">" cursor prompt
                    AnimatedBuilder(
                      animation: _blinkAnim,
                      builder: (_, __) => Text(
                        '❯',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: const Color(0xFF818CF8)
                              .withValues(alpha: _blinkAnim.value),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
                        cursorColor: const Color(0xFF818CF8),
                        cursorWidth: 2,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Type your input here…',
                          hintStyle: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0x44FFFFFF),
                          ),
                        ),
                        onSubmitted: (_) => _submitLine(),
                      ),
                    ),
                    // Enter button as a visual cue
                    InkWell(
                      onTap: _submitLine,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF818CF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                const Color(0xFF818CF8).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'Enter ↵',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF818CF8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (lines.isNotEmpty)
              // Process ended — show restart hint
              Container(
                color: widget.consoleBg,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                child: Text(
                  'Process finished. Click  Run Console  to run again.',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

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
