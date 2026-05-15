// ============================================================
// File: lib/data/models/runner_result_model.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Typed model for the JSON output of the Python runner
//              script (execute_student_code.py). Holds stdout, stderr,
//              exit_code, and duration_ms.
// ============================================================

import 'dart:convert';

class RunnerResult {
  final String stdout;
  final String stderr;
  final int exitCode;
  final int durationMs;

  const RunnerResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.durationMs,
  });

  factory RunnerResult.fromJson(Map<String, dynamic> j) => RunnerResult(
        stdout: j['stdout'] as String? ?? '',
        stderr: j['stderr'] as String? ?? '',
        exitCode: j['exit_code'] as int? ?? -1,
        durationMs: j['duration_ms'] as int? ?? 0,
      );

  /// Parse from the raw stdout string printed by execute_student_code.py.
  factory RunnerResult.fromRaw(String raw) {
    try {
      return RunnerResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return RunnerResult(
        stdout: raw,
        stderr: 'Could not parse runner output.',
        exitCode: -1,
        durationMs: 0,
      );
    }
  }

  bool get isSuccess => exitCode == 0;
}
