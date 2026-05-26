// ============================================================
// File: lib/data/models/attached_file_model.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Dart model for a single file attached to a question
//              by faculty. Mirrors the server's AttachedFileOut schema.
//              Does NOT contain file bytes — only metadata. The actual
//              bytes are downloaded by SandboxService on question load.
// ============================================================

class AttachedFile {
  final int id;

  /// Original filename as uploaded by faculty (e.g. "data.csv").
  final String filename;

  /// MIME type detected at upload time (e.g. "text/csv", "image/png").
  final String mimeType;

  /// File size in bytes — used for display in the Files tab.
  final int sizeBytes;

  const AttachedFile({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
  });

  factory AttachedFile.fromJson(Map<String, dynamic> j) => AttachedFile(
        id: j['id'] as int,
        filename: j['filename'] as String,
        mimeType: j['mime_type'] as String,
        sizeBytes: j['size_bytes'] as int,
      );

  /// Human-readable file size (e.g. "3.2 KB", "1.1 MB").
  String get displaySize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// True when this file is an image that can be rendered inline.
  bool get isImage =>
      mimeType.startsWith('image/') ||
      filename.toLowerCase().endsWith('.png') ||
      filename.toLowerCase().endsWith('.jpg') ||
      filename.toLowerCase().endsWith('.jpeg');

  /// True when this file is a CSV table.
  bool get isCsv => mimeType == 'text/csv' || filename.toLowerCase().endsWith('.csv');

  /// True when this file is human-readable text (JSON, TXT, DAT).
  bool get isText =>
      mimeType.startsWith('text/') ||
      mimeType == 'application/json' ||
      filename.toLowerCase().endsWith('.json') ||
      filename.toLowerCase().endsWith('.txt') ||
      filename.toLowerCase().endsWith('.dat');

  /// Display icon name for this file type.
  String get iconLabel {
    if (isImage) return '🖼️';
    if (isCsv) return '📊';
    if (isText) return '📄';
    if (filename.toLowerCase().endsWith('.xlsx')) return '📊';
    return '📦';
  }
}
