// ============================================================
// File: lib/data/services/python_runner_service.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Runs student Python code via the bundled runtime.
//              The wrapper logic is embedded in Dart — no external
//              runner script dependency. On Windows (production) uses
//              the bundled python.exe. On macOS/Linux (dev) uses
//              system python3 as a fallback.
// ============================================================

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../../core/config/config_loader.dart';
import '../../core/errors/app_exception.dart';
import '../models/runner_result_model.dart';

// ── Embedded Python wrapper ────────────────────────────────────────────────
// This is the entire runner logic. It is written to a temp file alongside
// the student code so there is NO external file dependency at all.
const _kPythonWrapper = r'''
import sys
import time
import json
import io
import traceback

def _run_student_code(source_code, stdin_text):
    old_stdout = sys.stdout
    old_stderr = sys.stderr
    old_stdin  = sys.stdin

    captured_out = io.StringIO()
    captured_err = io.StringIO()

    if stdin_text:
        sys.stdin = io.StringIO(stdin_text)

    sys.stdout = captured_out
    sys.stderr = captured_err

    exit_code = 0
    start = time.time()

    try:
        exec(compile(source_code, "<student>", "exec"), {})
    except SystemExit as e:
        exit_code = e.code if isinstance(e.code, int) else 1
    except Exception:
        captured_err.write(traceback.format_exc())
        exit_code = 1
    finally:
        sys.stdout = old_stdout
        sys.stderr = old_stderr
        sys.stdin  = old_stdin

    duration_ms = int((time.time() - start) * 1000)
    return {
        "stdout":      captured_out.getvalue(),
        "stderr":      captured_err.getvalue(),
        "exit_code":   exit_code,
        "duration_ms": duration_ms,
    }

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("code_file")
    parser.add_argument("stdin_text", nargs="?", default="")
    args = parser.parse_args()

    with open(args.code_file, "r", encoding="utf-8") as f:
        source = f.read()

    result = _run_student_code(source, args.stdin_text)
    print(json.dumps(result))
''';

class PythonRunnerService {
  /// Returns the Python executable path.
  /// - On Windows production: uses bundled python.exe from config.
  /// - On macOS/Linux dev:    falls back to system python3.
  String _resolveExecutable() {
    final configPath = ConfigLoader.instance.python.executablePath;
    if (File(configPath).existsSync()) return configPath;
    return Platform.isWindows ? 'python' : 'python3';
  }

  /// Writes [sourceCode] + embedded wrapper to temp files, runs them,
  /// and returns a [RunnerResult]. No external runner script needed.
  Future<RunnerResult> run({
    required String sourceCode,
    String? stdin,
  }) async {
    // Use the app's cache directory — always exists and is writable.
    final cacheDir = await getApplicationCacheDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;

    final wrapperFile = File('${cacheDir.path}/runner_$ts.py');
    final sourceFile  = File('${cacheDir.path}/student_$ts.py');

    try {
      // Write both files
      await wrapperFile.writeAsString(_kPythonWrapper, encoding: utf8);
      await sourceFile.writeAsString(sourceCode,       encoding: utf8);

      final executable = _resolveExecutable();
      final timeout    = ConfigLoader.instance.python.timeoutSeconds;

      final args = [wrapperFile.path, sourceFile.path];
      if (stdin != null && stdin.isNotEmpty) args.add(stdin);

      final result = await Process.run(
        executable,
        args,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
        runInShell: false,
      ).timeout(
        Duration(seconds: timeout + 5),
        onTimeout: () => ProcessResult(0, -1, '', 'Process timed out after ${timeout}s.'),
      );

      final raw = (result.stdout as String).trim();
      if (raw.isNotEmpty) {
        try {
          return RunnerResult.fromRaw(raw);
        } catch (_) {
          // Runner printed something but not valid JSON — show it as stdout.
          return RunnerResult(
            stdout: raw,
            stderr: result.stderr as String? ?? '',
            exitCode: result.exitCode,
            durationMs: 0,
          );
        }
      }

      // Runner itself crashed (import error, permission denied, etc.)
      return RunnerResult(
        stdout: '',
        stderr: (result.stderr as String?)?.isNotEmpty == true
            ? result.stderr as String
            : 'Runner exited with code ${result.exitCode}.',
        exitCode: result.exitCode,
        durationMs: 0,
      );
    } on RunnerException {
      rethrow;
    } catch (e) {
      throw RunnerException('Failed to execute code: $e');
    } finally {
      for (final f in [wrapperFile, sourceFile]) {
        try { await f.delete(); } catch (_) {}
      }
    }
  }
}
