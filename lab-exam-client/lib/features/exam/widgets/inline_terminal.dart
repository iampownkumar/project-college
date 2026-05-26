// ============================================================
// File: lib/features/exam/widgets/inline_terminal.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Terminal-style console panel.
//
//  Visual design:
//   - All stdout/stderr output is rendered as a single continuous
//     monospace text block (no bullet-point list, no coloured sections).
//   - When the process is running and waiting for input, an inline
//     cursor appears at the very end of the output — the student types
//     there and the typed text is appended to the same visual line.
//   - On Enter, the typed text is sent to stdin and appended to the
//     output buffer so the student can see what they typed.
//   - The effect is indistinguishable from a real terminal.
//
//  Technical approach (no PTY needed):
//   - Python runs with -u (unbuffered) so input() prompts flush before
//     blocking, making the prompt appear before the cursor.
//   - stdout/stderr are captured as streams from Process.
//   - Input is written to Process.stdin via sendConsoleInput().
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
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();

  late AnimationController _blink;

  static const _monoStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13.5,
    height: 1.6,
  );

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _focus.dispose();
    _blink.dispose();
    super.dispose();
  }

  // ── Scroll to bottom ──────────────────────────────────────
  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Submit a line of input ─────────────────────────────────
  void _send() {
    final text = _input.text;
    _input.clear();
    widget.exam.sendConsoleInput(text);
    _focus.requestFocus();
    _toBottom();
  }

  // ── Build the raw text block from consoleLines ─────────────
  // We join all lines into one string so it renders as a continuous
  // terminal output — no per-line containers, no padding gaps.
  String _buildBuffer(List<String> lines) => lines.join('');

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final isRunning = exam.isInteractiveRunning;
    final lines = exam.consoleLines;
    final theme = Theme.of(context);
    final textColor = widget.textColor;

    // Scroll whenever content changes
    if (lines.isNotEmpty || isRunning) _toBottom();
    if (isRunning) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focus.requestFocus());
    }

    // ── Empty idle state ─────────────────────────────────────
    if (!isRunning && lines.isEmpty && exam.lastResult == null) {
      return _IdleHint(textColor: textColor, consoleBg: widget.consoleBg);
    }

    // ── Batch run result (Run Tests) ─────────────────────────
    if (!isRunning && lines.isEmpty && exam.lastResult != null) {
      return _BatchResult(
        result: exam.lastResult!,
        textColor: textColor,
        consoleBg: widget.consoleBg,
      );
    }

    // ── Live / finished terminal ──────────────────────────────
    final buffer = _buildBuffer(lines);

    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: widget.consoleBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top status chip ────────────────────────────────
            _StatusBar(
              isRunning: isRunning,
              textColor: textColor,
              isDark: widget.isDark,
              onStop: exam.stopInteractiveRun,
              blink: _blink,
            ),

            // ── Output + inline input ──────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // All output as a single text block
                    if (buffer.isNotEmpty)
                      SelectableText(
                        buffer,
                        style: _monoStyle.copyWith(color: textColor),
                      ),

                    // ── Inline input row ───────────────────────
                    // Appears right below the last output line when
                    // process is running, indistinguishable from a
                    // real terminal prompt line.
                    if (isRunning)
                      _InlineInput(
                        controller: _input,
                        focus: _focus,
                        textColor: textColor,
                        isDark: widget.isDark,
                        onSend: _send,
                        blink: _blink,
                      ),

                    // A tiny spacer so content isn't clipped
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status bar ─────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final bool isRunning;
  final Color textColor;
  final bool isDark;
  final VoidCallback onStop;
  final AnimationController blink;

  const _StatusBar({
    required this.isRunning,
    required this.textColor,
    required this.isDark,
    required this.onStop,
    required this.blink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: isDark ? const Color(0xFF13111F) : const Color(0xFFE2E8F0),
      child: Row(
        children: [
          if (isRunning) ...[
            AnimatedBuilder(
              animation: blink,
              builder: (_, __) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    Colors.greenAccent,
                    Colors.green.shade800,
                    blink.value,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: 0.5),
                      blurRadius: 5,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'RUNNING',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 0.8,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
          ] else ...[
            Icon(Icons.check_circle_outline,
                size: 12, color: textColor.withValues(alpha: 0.35)),
            const SizedBox(width: 6),
            Text(
              'FINISHED',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 0.8,
                color: textColor.withValues(alpha: 0.35),
              ),
            ),
          ],
          const Spacer(),
          if (isRunning)
            InkWell(
              onTap: onStop,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
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
    );
  }
}

// ── Inline input (appears at end of output, no visible box) ────────────────

class _InlineInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final Color textColor;
  final bool isDark;
  final VoidCallback onSend;
  final AnimationController blink;

  const _InlineInput({
    required this.controller,
    required this.focus,
    required this.textColor,
    required this.isDark,
    required this.onSend,
    required this.blink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Blinking block cursor — signals "waiting for input"
        AnimatedBuilder(
          animation: blink,
          builder: (_, __) => Container(
            width: 8,
            height: 15,
            color: const Color(0xFF818CF8).withValues(alpha: blink.value),
          ),
        ),
        const SizedBox(width: 2),
        // Completely borderless text field — same font as output
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focus,
            autofocus: true,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13.5,
              height: 1.6,
            ),
            cursorColor: const Color(0xFF818CF8),
            cursorWidth: 2,
            decoration: const InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
        // Enter key hint — subtle, doesn't break terminal feel
        GestureDetector(
          onTap: onSend,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '↵',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                color: const Color(0xFF818CF8).withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Idle hint ───────────────────────────────────────────────────────────────

class _IdleHint extends StatelessWidget {
  final Color textColor;
  final Color consoleBg;
  const _IdleHint({required this.textColor, required this.consoleBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: consoleBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal_rounded,
                size: 32, color: textColor.withValues(alpha: 0.18)),
            const SizedBox(height: 12),
            Text(
              'Click  Run Console  to run your code interactively.\n'
              'Type inputs directly here when prompted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.32),
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Batch result (used after Run Tests / runCode) ───────────────────────────

class _BatchResult extends StatelessWidget {
  final dynamic result; // RunnerResult
  final Color textColor;
  final Color consoleBg;

  const _BatchResult({
    required this.result,
    required this.textColor,
    required this.consoleBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: consoleBg,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((result.stdout as String).isNotEmpty) ...[
              _label('STDOUT', textColor),
              const SizedBox(height: 4),
              SelectableText(
                result.stdout as String,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13.5,
                  height: 1.6,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if ((result.stderr as String).isNotEmpty) ...[
              _label('STDERR', const Color(0xFFEF4444)),
              const SizedBox(height: 4),
              SelectableText(
                result.stderr as String,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13.5,
                  height: 1.6,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
            if ((result.stdout as String).isEmpty &&
                (result.stderr as String).isEmpty)
              Text(
                '(No output)',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: textColor.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.55),
          letterSpacing: 1.2,
        ),
      );
}
