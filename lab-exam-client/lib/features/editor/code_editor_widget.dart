// ============================================================
// File: lib/features/editor/code_editor_widget.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Full-featured code editor using re_editor with Python
//              syntax highlighting, line numbers, and auto-bracket close.
//
//  Anti-cheat measures (production only):
//    1. Copy / Cut / Paste keyboard shortcuts are disabled via
//       shortcutOverrideActions (Ctrl/Cmd+C, Ctrl/Cmd+X, Ctrl/Cmd+V).
//       In debug mode (debug.allow_copy_paste: true) these work normally.
//    2. When focusLocked is true (strike limit reached):
//         - editor is set to readOnly so no keyboard input is accepted.
//         - a full AbsorbPointer overlay blocks all mouse/touch interaction.
//         - a lock badge is shown at the top-right of the editor.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/python.dart';
// re_highlight 0.0.3 themes are under lib/styles/ (not lib/themes/)
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/github.dart';
import '../../core/config/config_loader.dart';
import '../exam/exam_provider.dart';
import '../theme/theme_provider.dart';

// ---------------------------------------------------------------------------
// A no-op Action that swallows the intent and stops propagation.
// Used to override Copy / Cut / Paste in the editor.
// ---------------------------------------------------------------------------
class _BlockAction<T extends Intent> extends Action<T> {
  @override
  Object? invoke(T intent) => null; // do nothing
}

class CodeEditorWidget extends StatefulWidget {
  final String initialCode;
  const CodeEditorWidget({super.key, required this.initialCode});

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late CodeLineEditingController _controller;

  // Map that disables Copy, Cut, and Paste shortcuts inside the editor.
  // This is passed to CodeEditor.shortcutOverrideActions and is always active.
  static final Map<Type, Action<Intent>> _blockedClipboardActions = {
    CodeShortcutCopyIntent: _BlockAction<CodeShortcutCopyIntent>(),
    CodeShortcutCutIntent: _BlockAction<CodeShortcutCutIntent>(),
    CodeShortcutPasteIntent: _BlockAction<CodeShortcutPasteIntent>(),
  };

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.initialCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final isLocked = context.watch<ExamProvider>().focusLocked;

    final lineNumColor =
        isDark ? const Color(0xFF6C7086) : const Color(0xFF9CA3AF);
    final editorBg =
        isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFFFFFF);

    // ── Core editor ───────────────────────────────────────────
    final editor = Container(
      color: editorBg,
      child: CodeEditor(
        controller: _controller,
        wordWrap: false,

        // Locked exam → editor becomes fully read-only at the widget level.
        readOnly: isLocked,

        // ALWAYS block copy / cut / paste shortcuts regardless of lock state,
        // UNLESS debug.allow_copy_paste is active (for testing convenience).
        shortcutOverrideActions: ConfigLoader.instance.debug.isCopyPasteAllowed
            ? const {} // debug mode: allow all clipboard shortcuts
            : _blockedClipboardActions,

        onChanged: (CodeLineEditingValue value) {
          if (isLocked) return; // extra guard — readOnly should already block
          final code = value.codeLines.asString(TextLineBreak.lf);
          context.read<ExamProvider>().updateCode(code);
        },
        style: CodeEditorStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          fontHeight: 1.6,
          backgroundColor: editorBg,
          codeTheme: CodeHighlightTheme(
            languages: {'python': CodeHighlightThemeMode(mode: langPython)},
            theme: isDark ? atomOneDarkTheme : githubTheme,
          ),
        ),
        indicatorBuilder: (
          BuildContext context,
          CodeLineEditingController editingController,
          CodeChunkController chunkController,
          ValueNotifier<CodeIndicatorValue?> notifier,
        ) {
          return Row(
            children: [
              DefaultCodeLineNumber(
                controller: editingController,
                notifier: notifier,
                textStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: lineNumColor,
                ),
              ),
            ],
          );
        },
        sperator: Container(
          width: 1,
          color: isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0),
        ),
      ),
    );

    // ── Unlocked: just the editor (copy/paste still blocked) ──
    if (!isLocked) return editor;

    // ── Locked: overlay blocks all remaining pointer interaction ──
    // readOnly handles keyboard, AbsorbPointer handles mouse/touch.
    return Stack(
      children: [
        editor,

        // Full-area pointer absorber — no clicks, no selection, no context menu.
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: ColoredBox(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
            ),
          ),
        ),

        // Lock badge at top-right corner of the editor.
        Positioned(
          top: 10,
          right: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                SizedBox(width: 5),
                Text(
                  'Editing Locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
