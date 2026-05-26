// ============================================================
// File: lib/data/services/sandbox_service.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Manages the local sandbox directory for question files.
//              Downloads all files attached to the current question from
//              the server and stores them in the app cache directory so
//              the student's Python code can access them by relative path
//              (CWD is set to the sandbox dir by PythonRunnerService).
//
//  Sandbox path layout:
//    <app_cache>/sandbox/<session_id>/<question_id>/<filename>
//
//  Student code usage (CWD = sandbox dir):
//    import pandas as pd
//    df = pd.read_csv('data.csv')   # no path needed
// ============================================================

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/attached_file_model.dart';
import 'api_service.dart';

class SandboxService {
  final ApiService _api;

  SandboxService(this._api);

  // ── State ──────────────────────────────────────────────────────────────────

  String? _sandboxPath;

  /// Full path to the sandbox directory for the current question.
  /// Null until [downloadFiles] completes successfully.
  String? get sandboxPath => _sandboxPath;

  /// True when the sandbox directory is ready with all files downloaded.
  bool get isReady => _sandboxPath != null;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Download all [files] for [questionId] / [sessionId] to the local sandbox.
  ///
  /// Skips files that already exist on disk with the same size (avoids
  /// re-downloading on hot-reload or re-login within the same session).
  ///
  /// Returns the sandbox directory path on success.
  Future<String> downloadFiles({
    required int questionId,
    required int sessionId,
    required List<AttachedFile> files,
  }) async {
    final dir = await _sandboxDir(sessionId, questionId);
    _sandboxPath = dir.path;

    if (files.isEmpty) {
      return dir.path; // nothing to download — sandbox path is still valid
    }

    for (final file in files) {
      final localFile = File('${dir.path}/${file.filename}');

      // Skip if already downloaded with the correct size
      if (await localFile.exists()) {
        final stat = await localFile.stat();
        if (stat.size == file.sizeBytes) continue;
      }

      // Download bytes from server
      final bytes = await _api.downloadSandboxFile(
        questionId: questionId,
        filename: file.filename,
      );
      await localFile.writeAsBytes(bytes, flush: true);
    }

    return dir.path;
  }

  /// Delete the sandbox directory for a specific question.
  /// Called automatically when the student logs out.
  Future<void> clearSandbox({
    required int sessionId,
    required int questionId,
  }) async {
    final dir = await _sandboxDir(sessionId, questionId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _sandboxPath = null;
  }

  /// Delete ALL sandbox data (all sessions, all questions).
  /// Called on full logout / app reset.
  Future<void> clearAll() async {
    final cacheDir = await getApplicationCacheDirectory();
    final root = Directory('${cacheDir.path}/sandbox');
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    _sandboxPath = null;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<Directory> _sandboxDir(int sessionId, int questionId) async {
    final cacheDir = await getApplicationCacheDirectory();
    final dir = Directory(
      '${cacheDir.path}/sandbox/$sessionId/$questionId',
    );
    await dir.create(recursive: true);
    return dir;
  }
}
