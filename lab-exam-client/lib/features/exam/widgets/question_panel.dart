// ============================================================
// File: lib/features/exam/widgets/question_panel.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Left panel showing the full question statement,
//              constraints, and visible I/O examples.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../exam_provider.dart';
import '../../../data/models/question_model.dart';

class QuestionPanel extends StatelessWidget {
  const QuestionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();
    final theme = Theme.of(context);
    final q = exam.question;

    if (exam.status == ExamStatus.loading || q == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (exam.status == ExamStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 36),
            const SizedBox(height: 12),
            Text(exam.error, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      );
    }

    return Container(
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(q.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),

            // Language badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(q.language.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Statement
            _SectionLabel('Problem Statement'),
            const SizedBox(height: 8),
            Text(q.statement, style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),

            // Constraints
            if (q.constraints.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionLabel('Constraints'),
              const SizedBox(height: 8),
              ...q.constraints.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(child: Text(c, style: theme.textTheme.bodySmall?.copyWith(height: 1.5))),
                      ],
                    ),
                  )),
            ],

            // Examples
            if (q.visibleExamples.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionLabel('Examples'),
              const SizedBox(height: 8),
              ...q.visibleExamples.asMap().entries.map(
                    (e) => _ExampleBlock(index: e.key + 1, example: e.value),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      );
}

class _ExampleBlock extends StatelessWidget {
  final int index;
  final ExampleItem example;
  const _ExampleBlock({required this.index, required this.example});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? const Color(0xFF11111B)
        : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Example $index',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 8),
          if (example.input.isNotEmpty) ...[
            Text('Input:', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(example.input,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            const SizedBox(height: 6),
          ],
          Text('Output:', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(example.output,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        ],
      ),
    );
  }
}
