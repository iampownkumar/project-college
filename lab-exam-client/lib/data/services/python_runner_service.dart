// ============================================================
// File: lib/data/services/python_runner_service.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-26
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
import builtins

def _run_student_code(source_code, stdin_text):
    old_stdout = sys.stdout
    old_stderr = sys.stderr
    old_stdin  = sys.stdin
    old_input  = builtins.input

    captured_out = io.StringIO()
    captured_err = io.StringIO()
    stdin_io     = io.StringIO(stdin_text or "")

    # Override input() so that:
    #   1. It reads from the pre-fed stdin (not the real terminal)
    #   2. The PROMPT text is NEVER written to stdout (suppressed)
    # This means test-case output only contains actual print() calls.
    def _silent_input(prompt=''):
        if prompt:
            # Write prompt to real stderr so the teacher can see it during debugging,
            # but it must NOT pollute the captured stdout used for grading.
            old_stderr.write(str(prompt))
            old_stderr.flush()
        line = stdin_io.readline()
        if not line and not stdin_io.closed:
            raise EOFError("EOF when reading a line")
        return line.rstrip('\n')

    builtins.input = _silent_input
    sys.stdin  = stdin_io
    sys.stdout = captured_out
    sys.stderr = captured_err

    exit_code = 0
    start = time.time()

    # Provide a clean globals dict that still has __builtins__ so students
    # can freely import math, random, collections, etc.
    exec_globals = {"__builtins__": builtins}

    try:
        exec(compile(source_code, "<student>", "exec"), exec_globals)
    except SystemExit as e:
        exit_code = e.code if isinstance(e.code, int) else 1
    except Exception:
        captured_err.write(traceback.format_exc())
        exit_code = 1
    finally:
        sys.stdout    = old_stdout
        sys.stderr    = old_stderr
        sys.stdin     = old_stdin
        builtins.input = old_input

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
  // ── Venv paths ────────────────────────────────────────────────────────────
  // The bundled venv lives at  <executable dir>/runtime/venv/
  // On macOS app bundles the executable is inside .app/Contents/MacOS/,
  // so we also look relative to the parent dirs.

  static String get _venvPython {
    if (Platform.isWindows) return _venvRoot + r'\Scripts\python.exe';
    return _venvRoot + '/bin/python3';
  }

  static String get _venvRoot {
    // Walk up from the Flutter executable to find runtime/venv
    final exe = File(Platform.resolvedExecutable);
    final candidates = [
      exe.parent,                        // Linux: alongside executable
      exe.parent.parent,                 // macOS: Contents/ folder
      exe.parent.parent.parent,          // macOS: .app/
      exe.parent.parent.parent.parent,   // dev: build/macos/...
    ];
    for (final dir in candidates) {
      final venv = '${dir.path}/runtime/venv';
      if (Directory(venv).existsSync()) return venv;
    }
    // Dev fallback: look relative to CWD (flutter run from project root)
    return '${Directory.current.path}/runtime/venv';
  }

  /// Returns true when the bundled venv exists and has a python binary.
  static bool get isVenvReady => File(_venvPython).existsSync();

  /// Returns the full path to setup_env.sh for display purposes.
  static String get setupScriptPath {
    final exe = File(Platform.resolvedExecutable);
    final candidates = [
      exe.parent,
      exe.parent.parent,
      exe.parent.parent.parent,
    ];
    for (final dir in candidates) {
      final sh = '${dir.path}/runtime/setup_env.sh';
      if (File(sh).existsSync()) return sh;
    }
    return '${Directory.current.path}/runtime/setup_env.sh';
  }

  // ── Executable resolution ─────────────────────────────────────────────────
  /// Priority (in order):
  ///   1. debug.force_system_python → system `python3` immediately
  ///   2. Bundled venv              (runtime/venv/bin/python3)
  ///   3. Config path               (app_config.json python.executable_path)
  ///   4. System python             (python3 / python on Windows)
  String _resolveExecutable() {
    // Debug override: bypass the bundled venv entirely.
    // Useful when the venv symlinks are broken in a copied release bundle.
    if (ConfigLoader.instance.debug.isForceSystemPython) {
      return Platform.isWindows ? 'python' : 'python3';
    }
    if (isVenvReady) return _venvPython;
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
    final sourceFile = File('${cacheDir.path}/student_$ts.py');

    try {
      // Write both files
      await wrapperFile.writeAsString(_kPythonWrapper, encoding: utf8);
      await sourceFile.writeAsString(sourceCode, encoding: utf8);

      final executable = _resolveExecutable();
      final timeout = ConfigLoader.instance.python.timeoutSeconds;

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
        onTimeout: () =>
            ProcessResult(0, -1, '', 'Process timed out after ${timeout}s.'),
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
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }

  /// Spawns an interactive, unbuffered Python process.
  /// The caller is responsible for listening to stdout/stderr and writing to stdin.
  Future<Process> startInteractive({required String sourceCode}) async {
    final cacheDir = await getApplicationCacheDirectory();
    final sourceFile = File(
        '${cacheDir.path}/student_interactive_${DateTime.now().millisecondsSinceEpoch}.py');
    await sourceFile.writeAsString(sourceCode);

    final executable = _resolveExecutable();

    // Spawn python in unbuffered mode (-u) so prints appear immediately
    final process = await Process.start(
      executable,
      ['-u', sourceFile.path],
    );

    // Clean up file when process exits
    process.exitCode.then((_) {
      try {
        sourceFile.deleteSync();
      } catch (_) {}
    });

    return process;
  }
}
