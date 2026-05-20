// ============================================================
// File: lib/features/exam/exam_screen.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Main exam workspace with resizable 3-panel layout
//              (Question | Editor | Output+Controls) using multi_split_view.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:window_manager/window_manager.dart';
import '../editor/code_editor_widget.dart';
import 'exam_provider.dart';
import 'widgets/top_bar.dart';
import 'widgets/question_panel.dart';
import 'widgets/output_panel.dart';
import 'widgets/timer_warning_banner.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
  // Horizontal split: [Question | Editor+Output]
  late MultiSplitViewController _hSplit;
  // Vertical split inside right side: [Editor | Output+Controls]
  late MultiSplitViewController _vSplit;

  // Keyboard shortcut node
  final FocusNode _keyboardFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hSplit = MultiSplitViewController(areas: [
      Area(id: 'question', size: 300, min: 200),
      Area(id: 'right', min: 400),
    ]);
    _vSplit = MultiSplitViewController(areas: [
      Area(id: 'editor', min: 200),
      Area(id: 'output', size: 240, min: 140),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().initialize();
      _keyboardFocus.requestFocus();
    });
  }

  /// Restore fullscreen if student minimizes window.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      context.read<ExamProvider>().recordFocusLoss();
    }
    // Re-enforce fullscreen after macOS finishes its exit-fullscreen
    // transition. A delay is required — calling setFullScreen(true) during
    // the transition causes an NSException crash on macOS.
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 800), () {
        try {
          // Temporarily disabled for debugging
          // windowManager.setFullScreen(true);
        } catch (_) {
          // Ignore if transition is still in progress.
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardFocus.dispose();
    _hSplit.dispose();
    _vSplit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();

    return KeyboardListener(
      focusNode: _keyboardFocus,
      onKeyEvent: (event) {
        // Ctrl+Enter → Run
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            HardwareKeyboard.instance.isControlPressed) {
          if (exam.status == ExamStatus.ready) exam.runCode();
        }
      },
      child: Scaffold(
        appBar: const ExamTopBar(),
        body: Column(
          children: [
            // Timer warning banner (shown when <= 30 min remaining)
            const TimerWarningBanner(),
            // Main workspace
            Expanded(
              child: Stack(
                children: [
                  MultiSplitView(
                    controller: _hSplit,
                    axis: Axis.horizontal,
                    dividerBuilder: (axis, index, resizable, dragging,
                            highlighted, themeData) =>
                        _PanelDivider(axis: axis, dragging: dragging),
                    builder: (context, area) {
                      if (area.id == 'question') {
                        return const QuestionPanel();
                      }
                      return MultiSplitView(
                        controller: _vSplit,
                        axis: Axis.vertical,
                        dividerBuilder: (axis, index, resizable, dragging,
                                highlighted, themeData) =>
                            _PanelDivider(axis: axis, dragging: dragging),
                        builder: (context, area) {
                          if (area.id == 'editor') {
                            return exam.question != null
                                ? CodeEditorWidget(
                                    key: ValueKey(exam.question!.id),
                                    initialCode:
                                        exam.question!.starterCode ?? '',
                                  )
                                : const Center(
                                    child: CircularProgressIndicator());
                          }
                          return Column(
                            children: [
                              const Expanded(child: OutputPanel()),
                              _BottomControls(),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  // Submitted overlay
                  if (exam.showSubmittedOverlay) const _SubmittedOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Resizable divider ─────────────────────────────────────────────────────────

class _PanelDivider extends StatelessWidget {
  final Axis axis;
  final bool dragging;
  const _PanelDivider({required this.axis, required this.dragging});

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

// ── Bottom controls: stdin + run + submit ────────────────────────────────────

class _BottomControls extends StatefulWidget {
  @override
  State<_BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<_BottomControls> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _confirmSubmit(ExamProvider exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Code?'),
        content: const Text(
          'This will submit your final code to the server.\nYou can re-submit to overwrite, but make sure you\'re ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await exam.submitCode();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${exam.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRunning = exam.status == ExamStatus.running;
    final isSubmitting = exam.status == ExamStatus.submitting;
    final isLocked = exam.focusLocked; // 3 strikes → locked

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181825) : Colors.white,
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),

          // Run Console button
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: (isRunning || isLocked || exam.isInteractiveRunning) ? null : exam.startInteractiveRun,
              icon: exam.isInteractiveRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 1.5))
                  : Icon(
                      isLocked ? Icons.lock_rounded : Icons.terminal_rounded,
                      size: 18),
              label: Text(
                  exam.isInteractiveRunning ? 'Running…' : (isLocked ? 'Locked' : 'Run Console'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF8B5CF6), // Purple for console
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ),
          if (exam.isInteractiveRunning) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: exam.stopInteractiveRun,
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text('Stop', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),

          // Run Tests button
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: (isRunning || isLocked || exam.isInteractiveRunning) ? null : exam.runCode,
              icon: isRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 1.5))
                  : Icon(
                      isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                      size: 18),
              label: Text(
                  isRunning ? 'Testing…' : (isLocked ? 'Locked' : 'Run Tests'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF10B981), // Green for tests
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Submit button
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: (isSubmitting || isLocked)
                  ? null
                  : () => _confirmSubmit(exam),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 1.5))
                  : Icon(
                      isLocked
                          ? Icons.lock_rounded
                          : exam.submitted
                              ? Icons.cloud_done_rounded
                              : Icons.upload_rounded,
                      size: 18),
              label: Text(
                isSubmitting
                    ? 'Submitting…'
                    : isLocked
                        ? 'Locked'
                        : exam.submitted
                            ? 'Re-submit'
                            : 'Submit',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked
                    ? const Color(0xFF6B7280)
                    : exam.submitted
                        ? const Color(0xFF0D9488)
                        : const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submitted full-screen overlay ─────────────────────────────────────────────

class _SubmittedOverlay extends StatelessWidget {
  const _SubmittedOverlay();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // absorb taps
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 40,
                    offset: Offset(0, 12))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 64),
                const SizedBox(height: 16),
                Text('Code Submitted!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981))),
                const SizedBox(height: 8),
                Text(
                  'Your final submission has been recorded.\nYou may continue editing or close the exam.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Dismiss overlay — submitted stays true
                        context.read<ExamProvider>().dismissOverlay();
                      },
                      child: const Text('Continue Editing'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        // Navigate back to login — ExamProvider is
                        // re-created fresh on the next /exam visit.
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Return to Login'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
