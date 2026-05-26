// ============================================================
// File: lib/features/exam/exam_screen.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Main exam workspace with resizable 3-panel layout
//              (Question | Editor | Output+Controls) using multi_split_view.
//              All private widget classes have been extracted to widgets/.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../editor/code_editor_widget.dart';
import 'exam_provider.dart';
import 'widgets/top_bar.dart';
import 'widgets/question_panel.dart';
import 'widgets/output_panel.dart';
import 'widgets/timer_warning_banner.dart';
import 'widgets/panel_divider.dart';
import 'widgets/bottom_controls.dart';
import 'widgets/submitted_overlay.dart';

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

  /// Record focus loss when student minimises or alt-tabs.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      context.read<ExamProvider>().recordFocusLoss();
    }
    // Re-enforce fullscreen after macOS finishes its exit-fullscreen transition.
    // A delay is required — calling setFullScreen(true) during the transition
    // causes an NSException crash on macOS.
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
        // Ctrl+Enter → Run Tests
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
                        PanelDivider(axis: axis, dragging: dragging),
                    builder: (context, area) {
                      if (area.id == 'question') {
                        return const QuestionPanel();
                      }
                      return MultiSplitView(
                        controller: _vSplit,
                        axis: Axis.vertical,
                        dividerBuilder: (axis, index, resizable, dragging,
                                highlighted, themeData) =>
                            PanelDivider(axis: axis, dragging: dragging),
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
                          return const Column(
                            children: [
                              Expanded(child: OutputPanel()),
                              BottomControls(),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  // Submitted overlay — shown after successful submission
                  if (exam.showSubmittedOverlay) const SubmittedOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
