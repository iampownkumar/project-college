// ============================================================
// File: lib/features/exam/widgets/top_bar.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Exam top bar — student ID/name, countdown timer with
//              colour coding, connectivity dot, autosave indicator,
//              and dark/light theme toggle.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../exam_provider.dart';

class ExamTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ExamTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();
    final theme = Theme.of(context);
    final tp = context.watch<ThemeProvider>();

    final r = exam.remaining;
    final hh = r.inHours.toString().padLeft(2, '0');
    final mm = (r.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (r.inSeconds % 60).toString().padLeft(2, '0');
    final timerStr = '$hh:$mm:$ss';
    final timerColor = r.inMinutes < 10
        ? const Color(0xFFEF4444)
        : r.inMinutes < 30
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Brand
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Koreliurm',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 10),

          // Student ID
          Text(exam.student.registrationNumber,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(' · ${exam.student.name}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              )),

          const Spacer(),

          // Autosave status
          if (exam.lastSavedAt != null)
            Row(children: [
              Icon(Icons.save_outlined, size: 13, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(width: 4),
              Text('Saved', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
              const SizedBox(width: 16),
            ]),

          // Connectivity dot
          _ConnDot(online: exam.serverOnline),
          const SizedBox(width: 20),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: timerColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: timerColor.withOpacity(0.35)),
            ),
            child: Row(children: [
              Icon(Icons.timer_outlined, size: 15, color: timerColor),
              const SizedBox(width: 6),
              Text(timerStr,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: timerColor,
                  )),
            ]),
          ),
          const SizedBox(width: 12),

          // Theme toggle
          IconButton(
            icon: Icon(tp.isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 18),
            tooltip: tp.isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: tp.toggle,
          ),
        ],
      ),
    );
  }
}

class _ConnDot extends StatelessWidget {
  final bool online;
  const _ConnDot({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(online ? 'Online' : 'Offline',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}
