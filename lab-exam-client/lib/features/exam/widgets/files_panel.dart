// ============================================================
// File: lib/features/exam/widgets/files_panel.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Files tab inside the left question panel.
//              Shows all sandbox files attached to the current question.
//              Provides inline preview for CSV, images, text, and JSON.
//              "Copy Path" and "Copy Snippet" buttons help students
//              reference files in their code without guessing paths.
//
//  Anti-cheat benefit:
//    Students never need to alt-tab to view input files —
//    all previews and paths are accessible inside the exam client.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/models/attached_file_model.dart';
import '../exam_provider.dart';

class FilesPanel extends StatefulWidget {
  const FilesPanel({super.key});

  @override
  State<FilesPanel> createState() => _FilesPanelState();
}

class _FilesPanelState extends State<FilesPanel> {
  AttachedFile? _selected;

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamProvider>();
    final theme = Theme.of(context);
    final files = exam.question?.attachedFiles ?? [];
    final sandboxReady = exam.sandboxPath != null;

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              'No files attached to this question.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Download status banner ─────────────────────────────
        if (!sandboxReady)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.tertiary.withValues(alpha: 0.12),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Downloading files…',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),

        // ── File list ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Attached Files (${files.length})',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...files.map((f) => _FileListTile(
              file: f,
              isSelected: _selected?.filename == f.filename,
              sandboxReady: sandboxReady,
              onTap: () => setState(() {
                _selected =
                    (_selected?.filename == f.filename) ? null : f;
              }),
            )),

        const Divider(height: 24),

        // ── Preview + path area ────────────────────────────────
        if (_selected != null && sandboxReady)
          Expanded(
            child: _FilePreview(
              file: _selected!,
              sandboxPath: exam.sandboxPath!,
            ),
          )
        else if (_selected != null && !sandboxReady)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Waiting for file download to complete…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tap a file above to preview it and copy its path.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
      ],
    );
  }
}

// ── File list tile ─────────────────────────────────────────────────────────

class _FileListTile extends StatelessWidget {
  final AttachedFile file;
  final bool isSelected;
  final bool sandboxReady;
  final VoidCallback onTap;

  const _FileListTile({
    required this.file,
    required this.isSelected,
    required this.sandboxReady,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(file.iconLabel, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file.filename,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              file.displaySize,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            if (sandboxReady) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_outline,
                  size: 14,
                  color: Colors.green.withValues(alpha: 0.7)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Preview + path copy area ────────────────────────────────────────────────

class _FilePreview extends StatefulWidget {
  final AttachedFile file;
  final String sandboxPath;

  const _FilePreview({required this.file, required this.sandboxPath});

  @override
  State<_FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<_FilePreview> {
  String? _previewContent;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void didUpdateWidget(_FilePreview old) {
    super.didUpdateWidget(old);
    if (old.file.filename != widget.file.filename) {
      setState(() {
        _previewContent = null;
        _loading = true;
        _loadError = null;
      });
      _loadPreview();
    }
  }

  Future<void> _loadPreview() async {
    final f = widget.file;
    final path = '${widget.sandboxPath}/${f.filename}';
    final file = File(path);

    // Images: we don't read bytes — Flutter renders from path directly.
    if (f.isImage) {
      setState(() => _loading = false);
      return;
    }

    // Text-based files (CSV, JSON, TXT, DAT): read first 4 KB.
    if (f.isCsv || f.isText) {
      try {
        final content = await file.readAsString();
        // Limit preview to first 100 lines to avoid UI freeze on huge files.
        final lines = content.split('\n');
        final preview = lines.take(100).join('\n');
        setState(() {
          _previewContent = preview;
          _loading = false;
        });
      } catch (e) {
        setState(() {
          _loadError = 'Could not read file: $e';
          _loading = false;
        });
      }
      return;
    }

    // All other types: show size and path only.
    setState(() => _loading = false);
  }

  void _copyPath() {
    Clipboard.setData(ClipboardData(text: widget.file.filename));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Path copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copySnippet() {
    final f = widget.file;
    String snippet;
    if (f.isCsv) {
      snippet = "import pandas as pd\ndf = pd.read_csv('${f.filename}')";
    } else if (f.isImage) {
      snippet = "from PIL import Image\nimg = Image.open('${f.filename}')";
    } else if (f.isText &&
        f.filename.toLowerCase().endsWith('.json')) {
      snippet =
          "import json\nwith open('${f.filename}') as f:\n    data = json.load(f)";
    } else {
      snippet = "with open('${f.filename}') as f:\n    content = f.read()";
    }
    Clipboard.setData(ClipboardData(text: snippet));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code snippet copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = widget.file;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Path display + copy buttons ────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📌 Use in your code:',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "'${f.filename}'",
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _CopyButton(
                    label: 'Copy Path',
                    icon: Icons.copy,
                    onTap: _copyPath,
                  ),
                  const SizedBox(width: 8),
                  _CopyButton(
                    label: 'Copy Snippet',
                    icon: Icons.code,
                    onTap: _copySnippet,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Preview area ───────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildPreview(theme, f),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme, AttachedFile f) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_loadError != null) {
      return Center(
        child: Text(_loadError!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
      );
    }

    // Image preview
    if (f.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File('${widget.sandboxPath}/${f.filename}'),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('Could not render image'),
          ),
        ),
      );
    }

    // CSV table preview (first 100 rows as a scrollable text block)
    if (f.isCsv && _previewContent != null) {
      return _CsvPreview(content: _previewContent!);
    }

    // Text / JSON preview
    if (f.isText && _previewContent != null) {
      return _TextPreview(content: _previewContent!);
    }

    // Other types — no preview available
    return Center(
      child: Text(
        'No preview available for .${f.filename.split('.').last} files.\nUse the file path above to access it in your code.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _CopyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CopyButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CsvPreview extends StatelessWidget {
  final String content;
  const _CsvPreview({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = content.split('\n');
    final bg = theme.brightness == Brightness.dark
        ? const Color(0xFF11111B)
        : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .take(50)
                .map(
                  (line) => Text(
                    line,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      height: 1.6,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  final String content;
  const _TextPreview({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? const Color(0xFF11111B)
        : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Text(
          content,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
