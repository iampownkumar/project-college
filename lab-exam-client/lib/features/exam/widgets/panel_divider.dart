// ============================================================
// File: lib/features/exam/widgets/panel_divider.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Resizable drag-handle divider used between the
//              Question, Editor, and Output panels. Changes colour
//              while dragging and shows the correct resize cursor.
// ============================================================

import 'package:flutter/material.dart';

class PanelDivider extends StatelessWidget {
  final Axis axis;
  final bool dragging;

  const PanelDivider({
    super.key,
    required this.axis,
    required this.dragging,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = dragging
        ? Theme.of(context).colorScheme.primary
        : isDark
            ? const Color(0xFF313244)
            : const Color(0xFFE2E8F0);

    return MouseRegion(
      cursor: axis == Axis.horizontal
          ? SystemMouseCursors.resizeLeftRight
          : SystemMouseCursors.resizeUpDown,
      child: Container(
        width: axis == Axis.horizontal ? 4 : double.infinity,
        height: axis == Axis.vertical ? 4 : double.infinity,
        color: color,
      ),
    );
  }
}
