// ============================================================
// File: lib/features/editor/code_editor_widget.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Full-featured code editor using re_editor with Python
//              syntax highlighting, line numbers, and auto-bracket close.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/python.dart';
// re_highlight 0.0.3 themes are under lib/styles/ (not lib/themes/)
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/github.dart';
import '../exam/exam_provider.dart';
import '../theme/theme_provider.dart';

class CodeEditorWidget extends StatefulWidget {
  final String initialCode;
  const CodeEditorWidget({super.key, required this.initialCode});

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late CodeLineEditingController _controller;

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
    final lineNumColor =
        isDark ? const Color(0xFF6C7086) : const Color(0xFF9CA3AF);
    final editorBg =
        isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFFFFFF);

    return Container(
      color: editorBg,
      child: CodeEditor(
        controller: _controller,
        wordWrap: false,
        onChanged: (CodeLineEditingValue value) {
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
          color:
              isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}
