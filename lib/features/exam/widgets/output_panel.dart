// ============================================================
// File: lib/features/exam/widgets/output_panel.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Terminal-style output panel showing STDOUT/STDERR with
//              exit code badge, duration badge, and selectable text.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../exam_provider.dart';

class OutputPanel extends StatefulWidget {
  const OutputPanel({super.key});

  @override
  State<OutputPanel> createState() => _OutputPanelState();
}

class _OutputPanelState extends State<OutputPanel> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
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

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                const Icon(Icons.terminal_rounded, size: 14),
                const SizedBox(width: 6),
                const Text('Output', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (result != null) ...[
                  _MetaBadge(
                    label: 'Exit: ${result.exitCode}',
                    color: result.isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _MetaBadge(
                    label: '${result.durationMs} ms',
                    color: const Color(0xFF3B82F6),
                  ),
                ],
                if (isRunning)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: isRunning
                ? const Center(child: Text('Running…', style: TextStyle(fontFamily: 'monospace')))
                : result == null
                    ? Center(
                        child: Text(
                          'Press Run ▶ to execute your code.',
                          style: TextStyle(
                            color: textColor.withOpacity(0.4),
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (result.stdout.isNotEmpty) ...[
                              _OutputSection(
                                label: 'STDOUT',
                                content: result.stdout,
                                color: textColor,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (result.stderr.isNotEmpty)
                              _OutputSection(
                                label: 'STDERR',
                                content: result.stderr,
                                color: const Color(0xFFEF4444),
                              ),
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
                      ),
          ),
        ],
      ),
    );
  }
}

class _OutputSection extends StatelessWidget {
  final String label;
  final String content;
  final Color color;

  const _OutputSection({required this.label, required this.content, required this.color});

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
            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: color, height: 1.5),
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
                fontSize: 11, fontWeight: FontWeight.w600, color: color, fontFamily: 'monospace')),
      );
}
