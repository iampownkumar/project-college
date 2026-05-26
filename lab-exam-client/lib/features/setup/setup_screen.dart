// ============================================================
// File: lib/features/setup/setup_screen.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: First-launch screen shown when the bundled Python
//   environment (runtime/venv) has not been created yet.
//   Finds a system Python 3.9+, creates a venv, and installs
//   packages from runtime/requirements.txt with live log output.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class SetupScreen extends StatefulWidget {
  /// Called when setup finishes successfully — navigate to login.
  final VoidCallback onSetupComplete;

  const SetupScreen({super.key, required this.onSetupComplete});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<String> _lines = [];
  bool _running = false;
  bool _done = false;
  bool _failed = false;
  final _scrollCtrl = ScrollController();

  void _addLine(String line) {
    setState(() => _lines.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String?> _findSystemPython() async {
    final commands = Platform.isWindows
        ? ['python', 'python3', 'py']
        : ['python3.12', 'python3.11', 'python3.10', 'python3.9', 'python3', 'python'];

    for (final cmd in commands) {
      try {
        final check = await Process.run(cmd, ['-c', 'import sys; sys.exit(0 if sys.version_info >= (3,9) else 1)']);
        if (check.exitCode == 0) {
          return cmd;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _runSetup() async {
    setState(() {
      _running = true;
      _done = false;
      _failed = false;
      _lines.clear();
    });

    try {
      final exe = File(Platform.resolvedExecutable);
      String? runtimePath;
      final candidates = [
        exe.parent,
        exe.parent.parent,
        exe.parent.parent.parent,
        exe.parent.parent.parent.parent,
      ];
      for (final dir in candidates) {
        final path = '${dir.path}/runtime';
        if (Directory(path).existsSync()) {
          runtimePath = path;
          break;
        }
      }
      runtimePath ??= '${Directory.current.path}/runtime';
      
      final venvPath = '$runtimePath/venv';
      final requirementsPath = '$runtimePath/requirements.txt';

      _addLine('→ Target Environment: $venvPath');
      _addLine('→ Requirements File: $requirementsPath');
      _addLine('');

      if (!File(requirementsPath).existsSync()) {
        _addLine('❌ Error: requirements.txt not found at $requirementsPath');
        setState(() {
          _failed = true;
          _running = false;
        });
        return;
      }

      _addLine('→ Searching for system Python 3.9+...');
      final systemPython = await _findSystemPython();
      if (systemPython == null) {
        _addLine('❌ Error: Python 3.9 or later is required but not found.');
        _addLine('Please download and install Python from: https://www.python.org/downloads/');
        _addLine('IMPORTANT: During installation, check "Add Python to PATH".');
        setState(() {
          _failed = true;
          _running = false;
        });
        return;
      }
      _addLine('Found Python: $systemPython');
      _addLine('');

      // Remove old venv if exists
      final venvDir = Directory(venvPath);
      if (venvDir.existsSync()) {
        _addLine('→ Removing old virtual environment...');
        try {
          venvDir.deleteSync(recursive: true);
        } catch (e) {
          _addLine('⚠ Note: Could not completely delete old venv: $e');
        }
      }

      // Create venv
      _addLine('→ Creating virtual environment...');
      final venvResult = await Process.run(systemPython, ['-m', 'venv', venvPath]);
      if (venvResult.exitCode != 0) {
        _addLine('❌ Failed to create virtual environment (exit code: ${venvResult.exitCode}).');
        _addLine(venvResult.stderr.toString());
        setState(() {
          _failed = true;
          _running = false;
        });
        return;
      }

      // Locate venv python
      final venvPython = Platform.isWindows
          ? '$venvPath\\Scripts\\python.exe'
          : '$venvPath/bin/python3';

      if (!File(venvPython).existsSync()) {
        _addLine('❌ Error: Virtual environment Python binary not found at $venvPython');
        setState(() {
          _failed = true;
          _running = false;
        });
        return;
      }

      // Upgrade pip
      _addLine('→ Upgrading pip inside environment...');
      final pipUpgradeResult = await Process.run(venvPython, ['-m', 'pip', 'install', '--upgrade', 'pip']);
      if (pipUpgradeResult.exitCode != 0) {
        _addLine('⚠ Note: Pip upgrade returned non-zero (exit code: ${pipUpgradeResult.exitCode}).');
        _addLine(pipUpgradeResult.stderr.toString());
      }

      // Install requirements
      _addLine('→ Installing packages (numpy, pandas, matplotlib, seaborn, scipy)...');
      _addLine('This will take a few minutes. Output stream below:');
      _addLine('');

      final installProcess = await Process.start(
        venvPython,
        ['-m', 'pip', 'install', '-r', requirementsPath],
        runInShell: false,
      );

      // Listen to stdout
      installProcess.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            _addLine(trimmed);
          }
        }
      });

      // Listen to stderr
      installProcess.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            _addLine('⚠ $trimmed');
          }
        }
      });

      final installExitCode = await installProcess.exitCode;
      if (installExitCode == 0) {
        _addLine('');
        _addLine('✅ Python environment ready!');
        setState(() {
          _done = true;
          _running = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        widget.onSetupComplete();
      } else {
        _addLine('');
        _addLine('❌ Package installation failed (exit code: $installExitCode).');
        setState(() {
          _failed = true;
          _running = false;
        });
      }
    } catch (e) {
      _addLine('');
      _addLine('❌ Error: $e');
      setState(() {
        _failed = true;
        _running = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0D0D14);
    const surface = Color(0xFF1A1A2E);
    const accent = Color(0xFF8B5CF6);
    const textColor = Color(0xFFCDD6F4);
    const greenColor = Color(0xFF10B981);
    const redColor = Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.terminal_rounded,
                          color: accent, size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Koreliurm Lab Exam',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'First-time setup required',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Description ─────────────────────────────
                if (!_running && _lines.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Python Environment Setup',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This needs to run once to install the Python packages '
                          'your exam programs will use:\n\n'
                          '  • numpy      — arrays and math\n'
                          '  • pandas     — data tables and CSV\n'
                          '  • matplotlib — plotting and graphs\n'
                          '  • seaborn    — statistical charts\n'
                          '  • scipy      — scientific computing',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            height: 1.6,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 14, color: accent),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Requires internet connection. Takes ~2-5 minutes.',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Terminal output ──────────────────────────
                if (_lines.isNotEmpty) ...[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _done
                              ? greenColor.withValues(alpha: 0.3)
                              : _failed
                                  ? redColor.withValues(alpha: 0.3)
                                  : accent.withValues(alpha: 0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        itemCount: _lines.length,
                        itemBuilder: (ctx, i) {
                          final line = _lines[i];
                          Color lineColor = const Color(0xFF94A3B8);
                          if (line.startsWith('✅')) {
                            lineColor = greenColor;
                          } else if (line.startsWith('❌') ||
                              line.startsWith('⚠')) {
                            lineColor = redColor;
                          } else if (line.startsWith('→')) {
                            lineColor = accent;
                          }
                          return Text(
                            line,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.5,
                              color: lineColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 24),

                // ── Button ──────────────────────────────────
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _running || _done ? null : _runSetup,
                    icon: _running
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_failed
                            ? Icons.refresh_rounded
                            : Icons.play_arrow_rounded),
                    label: Text(
                      _running
                          ? 'Installing packages…'
                          : _done
                              ? 'Done!'
                              : _failed
                                  ? 'Retry Setup'
                                  : 'Initialize Python Environment',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _done ? greenColor : accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _done ? greenColor : accent.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
