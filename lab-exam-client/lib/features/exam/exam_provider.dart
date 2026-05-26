// ============================================================
// File: lib/features/exam/exam_provider.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Central ChangeNotifier for the exam workspace.
//              Manages question fetch, countdown timer, heartbeat,
//              autosave, local code execution, run log, and submission.
//              Sandbox file download is handled via SandboxService.
//              ExamStatus is split into testRunning / consoleRunning
//              to eliminate dual-purpose ambiguity.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/config/config_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/login_response_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/runner_result_model.dart';
import '../../data/models/test_case_result.dart';
import '../../data/services/api_service.dart';
import '../../data/services/python_runner_service.dart';
import '../../data/services/autosave_service.dart';
import '../../data/services/sandbox_service.dart';
import '../../core/utils/machine_info.dart';

enum ExamStatus {
  loading,
  ready,

  /// Student's code is running in interactive console mode.
  consoleRunning,

  /// Student's code is being run against test cases.
  testRunning,

  submitting,
  submitted,
  error,
}

/// Timer warning levels shown as top banners.
enum TimerWarning { none, thirtyMin, tenMin, fiveMin, expired }

class ExamProvider extends ChangeNotifier {
  final ApiService _api;
  final PythonRunnerService _runner;
  final AutosaveService _autosave;
  final SandboxService _sandbox;

  final StudentModel student;
  final SessionModel session;
  final AssignmentModel assignment;

  ExamProvider({
    required this.student,
    required this.session,
    required this.assignment,
    this.onSessionExpired,
    ApiService? api,
    PythonRunnerService? runner,
    AutosaveService? autosave,
    SandboxService? sandbox,
  })  : _api = api ?? ApiService(),
        _runner = runner ?? PythonRunnerService(),
        _autosave = autosave ??
            AutosaveService(
              intervalSeconds:
                  ConfigLoader.instance.exam.autosaveIntervalSeconds,
            ),
        _sandbox = sandbox ?? SandboxService(api ?? ApiService());

  /// Called when the server reports that the session has been closed/expired.
  /// Wire this to Navigator.pop → login in ExamScreen.
  final VoidCallback? onSessionExpired;

  // ── State ─────────────────────────────────────────────────
  ExamStatus _status = ExamStatus.loading;
  String _error = '';
  QuestionModel? _question;
  RunnerResult? _lastResult;
  bool _serverOnline = true;
  bool _submitted = false;
  bool _disposed = false; // guard to prevent use-after-dispose

  // POST-SUBMIT LOCKOUT — set to true after a successful submit.
  // When true: editor is read-only, all run/submit buttons are hidden,
  // only "Return to Login" is offered. Tab-switch no longer counted.
  bool _examLocked = false;
  bool get examLocked => _examLocked;

  String _currentCode = '';
  String _stdinInput = '';

  // Timer — initialised eagerly to avoid LateInitializationError
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;

  // Heartbeat
  Timer? _heartbeatTimer;

  // Autosave timestamp update timer (stored so we can cancel it)
  Timer? _autosaveTimer;

  // Assignment refresh poll timer
  Timer? _assignmentPollTimer;

  // Autosave state display
  DateTime? _lastSavedAt;

  // Getters
  ExamStatus get status => _status;
  String get error => _error;
  QuestionModel? get question => _question;
  RunnerResult? get lastResult => _lastResult;
  bool get serverOnline => _serverOnline;
  bool get submitted => _submitted;
  bool _showSubmittedOverlay = false;
  bool get showSubmittedOverlay => _showSubmittedOverlay;

  // Timer warning level
  TimerWarning _timerWarning = TimerWarning.none;
  TimerWarning get timerWarning => _timerWarning;

  // Focus-loss / tab-switch counter (anti-cheat)
  int _focusLostCount = 0;
  int get focusLostCount => _focusLostCount;

  // Whether exam is locked due to repeated focus loss (malpractice)
  bool _focusLocked = false;
  bool get focusLocked => _focusLocked;

  // Max allowed tab switches before lock — driven by app_config.json
  int get _maxFocusLossStrikes => ConfigLoader.instance.exam.maxStrikes;

  // Test case results (populated after runCode)
  List<TestCaseResult> _testCaseResults = [];
  List<TestCaseResult> get testCaseResults =>
      List.unmodifiable(_testCaseResults);
  bool _isTestingCases = false;
  bool get isTestingCases => _isTestingCases;

  Duration get remaining => _remaining;
  DateTime? get lastSavedAt => _lastSavedAt;
  String get stdinInput => _stdinInput;

  /// Path to the local sandbox directory for the current question.
  /// Null until sandbox files are downloaded in [initialize].
  String? get sandboxPath => _sandbox.sandboxPath;

  void setStdin(String val) {
    // Convert literal \n typed by the user in the single-line field into an actual newline
    _stdinInput = val.replaceAll('\\n', '\n');
    if (!_disposed) notifyListeners();
  }

  void updateCode(String code) {
    if (_focusLocked || _examLocked) return; // locked exam — reject edits
    _currentCode = code;
  }

  // ── Interactive Console ────────────────────────────────────
  Process? _interactiveProcess;
  final List<String> _consoleLines = [];
  List<String> get consoleLines => List.unmodifiable(_consoleLines);
  bool get isInteractiveRunning => _interactiveProcess != null;

  void clearConsole() {
    _consoleLines.clear();
    if (!_disposed) notifyListeners();
  }

  Future<void> startInteractiveRun() async {
    if (isInteractiveRunning || _currentCode.isEmpty) return;

    clearConsole();
    _status = ExamStatus.consoleRunning;
    notifyListeners();

    try {
      _interactiveProcess =
          await _runner.startInteractive(
            sourceCode: _currentCode,
            sandboxPath: _sandbox.sandboxPath,
          );

      _interactiveProcess!.stdout.transform(utf8.decoder).listen((data) {
        _consoleLines.add(data);
        if (!_disposed) notifyListeners();
      });

      _interactiveProcess!.stderr.transform(utf8.decoder).listen((data) {
        _consoleLines.add('STDERR: $data');
        if (!_disposed) notifyListeners();
      });

      final exitCode = await _interactiveProcess!.exitCode;
      _consoleLines.add('\n[Process exited with code $exitCode]');
    } catch (e) {
      _consoleLines.add('\n[Failed to start: $e]');
    } finally {
      _interactiveProcess = null;
      _status = ExamStatus.ready;
      if (!_disposed) notifyListeners();
    }
  }

  void stopInteractiveRun() {
    if (_interactiveProcess != null) {
      _interactiveProcess!.kill();
      _interactiveProcess = null;
      _consoleLines.add('\n[Process terminated manually]');
      _status = ExamStatus.ready;
      notifyListeners();
    }
  }

  void sendConsoleInput(String text) {
    if (_interactiveProcess != null) {
      _consoleLines.add('> $text\n');
      _interactiveProcess!.stdin.writeln(text);
      notifyListeners();
    }
  }

  // ── Init ──────────────────────────────────────────────────
  Future<void> initialize() async {
    _status = ExamStatus.loading;
    if (!_disposed) notifyListeners();

    try {
      // Compute timer from session data or use default
      _remaining = _computeInitialTimer();

      // Load question
      final json =
          await _api.fetchAssignedQuestion(student.registrationNumber);
      _question = QuestionModel.fromJson(json);

      // Download sandbox files (if any) — runs in background after status → ready
      if (_question!.attachedFiles.isNotEmpty) {
        // Don't await here: let the question render immediately,
        // sandbox downloads in background and notifies when done.
        _downloadSandboxFiles();
      }

      // Try to restore autosaved code
      final savedCode = await _autosave.loadSaved(_autosaveKey);
      _currentCode = savedCode ?? _question!.starterCode ?? '';

      // Pre-fill Custom Input exactly like LeetCode
      if (_question!.visibleExamples.isNotEmpty) {
        _stdinInput = _question!.visibleExamples.first.input;
      }

      _status = ExamStatus.ready;
      if (!_disposed) notifyListeners();

      _startCountdown();
      _startHeartbeat();
      _startAutosave();
      _startAssignmentPoll();
    } catch (e) {
      _status = ExamStatus.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Download question sandbox files in the background.
  /// Updates listeners once done so the Files tab can show the ready state.
  Future<void> _downloadSandboxFiles() async {
    try {
      await _sandbox.downloadFiles(
        questionId: _question!.id,
        sessionId: session.id,
        files: _question!.attachedFiles,
      );
      if (!_disposed) notifyListeners(); // Files tab re-renders with sandboxPath
    } catch (e) {
      // Non-fatal: sandbox failure doesn't crash the exam.
      // The Files tab will show a warning instead.
      debugPrint('SandboxService: failed to download files — $e');
    }
  }

  String get _autosaveKey =>
      '${student.registrationNumber}_${assignment.questionId}';

  Duration _computeInitialTimer() {
    if (session.endTime != null) {
      final diff = session.endTime!.difference(DateTime.now().toUtc());
      return diff.isNegative ? Duration.zero : diff;
    }
    return Duration(
        minutes: session.durationMinutes > 0
            ? session.durationMinutes
            : AppConstants.defaultExamDurationMinutes);
  }

  // ── Countdown timer ───────────────────────────────────────
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 0) {
        _countdownTimer?.cancel();
        _remaining = Duration.zero;
        _autoSubmitOnExpiry('auto_timer');
      } else {
        _remaining = _remaining - const Duration(seconds: 1);
        _updateTimerWarning();
        notifyListeners();
      }
    });
  }

  void _updateTimerWarning() {
    final mins = _remaining.inMinutes;
    if (mins <= 5 &&
        _timerWarning != TimerWarning.fiveMin &&
        _timerWarning != TimerWarning.expired) {
      _timerWarning = TimerWarning.fiveMin;
    } else if (mins <= 10 && mins > 5 && _timerWarning == TimerWarning.none ||
        _timerWarning == TimerWarning.thirtyMin) {
      _timerWarning = TimerWarning.tenMin;
    } else if (mins <= 30 && mins > 10 && _timerWarning == TimerWarning.none) {
      _timerWarning = TimerWarning.thirtyMin;
    }
  }

  /// Auto-submit when timer expires — standard college exam behaviour.
  Future<void> _autoSubmitOnExpiry(String type) async {
    if (_status == ExamStatus.submitting) return;
    _error = '';
    _status = ExamStatus.submitting;
    notifyListeners();
    try {
      await _api.postSubmission({
        'registration_number': student.registrationNumber,
        'session_id': session.id,
        'question_id': assignment.questionId,
        'source_code': _currentCode,
        'stdout': _lastResult?.stdout,
        'stderr': _lastResult?.stderr,
        'exit_code': _lastResult?.exitCode,
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
        'submission_type': type,
      });
      _submitted = true;
      _showSubmittedOverlay = true;
    } catch (_) {
      // Even if server is unreachable, mark locally as expired.
    } finally {
      _status = ExamStatus.ready;
      notifyListeners();
    }
  }

  /// Called by UI when app loses focus (window minimised / user alt-tabs).
  /// Ignored if the exam has already been submitted (post-submit lockout).
  /// Ignored entirely when debug.disable_focus_tracking is true.
  /// After N strikes the exam is locked and auto-submitted.
  void recordFocusLoss() {
    // Debug mode: silently skip all focus tracking.
    if (ConfigLoader.instance.debug.isFocusTrackingDisabled) return;
    if (_focusLocked) return; // already locked by malpractice
    if (_examLocked || _submitted) return; // already submitted — don't flag
    _focusLostCount++;
    notifyListeners();

    if (_focusLostCount >= _maxFocusLossStrikes) {
      _focusLocked = true;
      _countdownTimer?.cancel(); // stop timer
      _autoSubmitOnExpiry('auto_tab_switch'); // force submit immediately
    }
  }

  // ── Assignment Refresh Poll ──────────────────────────────
  /// Every 20 s, re-fetch the assigned question. If the admin swapped
  /// the question (different question_id) the exam reloads with the
  /// new question and fresh starter code, resetting test results.
  void _startAssignmentPoll() {
    _assignmentPollTimer =
        Timer.periodic(const Duration(seconds: 20), (_) async {
      if (_disposed) return;
      try {
        final json =
            await _api.fetchAssignedQuestion(student.registrationNumber);
        final newQ = QuestionModel.fromJson(json);
        if (_question == null || newQ.id != _question!.id) {
          // New question assigned — reset state
          _question = newQ;
          _currentCode = newQ.starterCode ?? '';
          _lastResult = null;
          _testCaseResults = [];
          _submitted = false;
          _showSubmittedOverlay = false;
          if (!_disposed) notifyListeners();
        }
      } catch (_) {/* ignore network errors */}
    });
  }

  // ── Heartbeat ─────────────────────────────────────────────
  void _startHeartbeat() {
    final interval = ConfigLoader.instance.server.heartbeatIntervalSeconds;
    _heartbeatTimer =
        Timer.periodic(Duration(seconds: interval), (_) => _sendHeartbeat());
    _sendHeartbeat(); // immediate first ping
  }

  void _sendHeartbeat() async {
    if (_disposed) return;
    try {
      final ip = await MachineInfo.getMachineIp();
      final resp = await _api.postHeartbeat({
        'registration_number': student.registrationNumber,
        'session_id': session.id,
        'machine_name': MachineInfo.machineName,
        'machine_ip': ip,
        'client_state': _status.name,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      _serverOnline = true;

      // Check if the server says the session is closed/expired
      if (resp != null) {
        final data = resp['data'] as Map<String, dynamic>?;
        final closed = data?['session_closed'] as bool? ?? false;
        if (closed && !_disposed) {
          // Auto-submit first, then logout
          if (!_submitted) await _autoSubmitAndLogout();
          return;
        }
      }
    } catch (_) {
      _serverOnline = false;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _autoSubmitAndLogout() async {
    // Submit whatever code exists silently
    try {
      await _api.postSubmission({
        'registration_number': student.registrationNumber,
        'session_id': session.id,
        'question_id': assignment.questionId,
        'source_code': _currentCode,
        'language': 'python',
        'submission_type': 'auto',
      });
    } catch (_) {}
    _submitted = true;
    // Fire the callback — ExamScreen pops to login
    onSessionExpired?.call();
  }

  // ── Autosave ──────────────────────────────────────────────
  void _startAutosave() {
    _autosave.start(
      codeGetter: () => _currentCode,
      key: _autosaveKey,
    );
    // Update timestamp periodically — store timer so we can cancel it
    _autosaveTimer = Timer.periodic(
      Duration(seconds: ConfigLoader.instance.exam.autosaveIntervalSeconds),
      (_) {
        if (_disposed) return;
        _lastSavedAt = DateTime.now();
        notifyListeners();
      },
    );
  }

  // ── Run code ──────────────────────────────────────────────
  Future<void> runCode() async {
    if (_status == ExamStatus.testRunning || _currentCode.isEmpty) return;

    _status = ExamStatus.testRunning;
    _lastResult = null;
    notifyListeners();

    final start = DateTime.now();

    try {
      final result = await _runner.run(
        sourceCode: _currentCode,
        stdin: _stdinInput.isEmpty ? null : _stdinInput,
        sandboxPath: _sandbox.sandboxPath,
      );

      _lastResult = result;
      _status = ExamStatus.ready;
      notifyListeners();

      // Post run log (fire & forget)
      _postRunLog(result, start);

      // Auto-run test cases if the question has examples
      if (_question != null && _question!.visibleExamples.isNotEmpty) {
        runAllTestCases();
      }
    } catch (e) {
      _lastResult = RunnerResult(
        stdout: '',
        stderr: e.toString(),
        exitCode: -1,
        durationMs: DateTime.now().difference(start).inMilliseconds,
      );
      _status = ExamStatus.ready;
      notifyListeners();
    }
  }

  /// Run the current code against every visible_example as a test case.
  /// Results are stored in [testCaseResults] for the output panel to display.
  Future<void> runAllTestCases() async {
    if (_question == null || _question!.visibleExamples.isEmpty) return;
    if (_currentCode.isEmpty) return;

    _isTestingCases = true;
    _testCaseResults = [];
    notifyListeners();

    final examples = _question!.visibleExamples;
    final results = <TestCaseResult>[];

    for (int i = 0; i < examples.length; i++) {
      final ex = examples[i];
      final start = DateTime.now();
      try {
        final r = await _runner.run(
          sourceCode: _currentCode,
          stdin: ex.input.isEmpty ? null : ex.input,
          sandboxPath: _sandbox.sandboxPath,
        );
        final actual = r.stdout.trimRight();
        final expected = ex.output.trimRight();
        final passed = _outputsMatch(actual, expected);
        results.add(TestCaseResult(
          index: i,
          input: ex.input,
          expected: expected,
          actual: actual,
          passed: passed,
          stderr: r.stderr,
          durationMs: DateTime.now().difference(start).inMilliseconds,
        ));
      } catch (e) {
        results.add(TestCaseResult(
          index: i,
          input: ex.input,
          expected: ex.output.trimRight(),
          actual: '',
          passed: false,
          stderr: e.toString(),
          durationMs: DateTime.now().difference(start).inMilliseconds,
        ));
      }
    }

    _testCaseResults = results;
    _isTestingCases = false;
    notifyListeners();
  }

  // ── Smart output comparison ─────────────────────────────────────────────────
  /// Compares two multi-line output strings with smart normalization:
  ///   - Trims trailing whitespace on each line
  ///   - Ignores blank lines
  ///   - Compares numbers numerically ("8.0" == "8", "1e3" == "1000.0")
  static bool _outputsMatch(String actual, String expected) {
    final aLines = actual
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();
    final eLines = expected
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();
    if (aLines.length != eLines.length) return false;
    for (int i = 0; i < aLines.length; i++) {
      final a = aLines[i].trim();
      final e = eLines[i].trim();
      if (a == e) continue;
      final aNum = double.tryParse(a);
      final eNum = double.tryParse(e);
      if (aNum != null && eNum != null && (aNum - eNum).abs() < 1e-9) continue;
      return false;
    }
    return true;
  }

  void _postRunLog(RunnerResult result, DateTime start) {
    _api.postRunLog({
      'registration_number': student.registrationNumber,
      'session_id': session.id,
      'question_id': assignment.questionId,
      'source_code': _currentCode,
      'stdout': result.stdout,
      'stderr': result.stderr,
      'exit_code': result.exitCode,
      'duration_ms': result.durationMs,
      'timestamp': start.toUtc().toIso8601String(),
    });
  }

  // ── Submit ────────────────────────────────────────────────
  Future<bool> submitCode() async {
    if (_status == ExamStatus.submitting) return false; // prevent double-tap
    _status = ExamStatus.submitting;
    notifyListeners();

    try {
      await _api.postSubmission({
        'registration_number': student.registrationNumber,
        'session_id': session.id,
        'question_id': assignment.questionId,
        'source_code': _currentCode,
        'stdout': _lastResult?.stdout,
        'stderr': _lastResult?.stderr,
        'exit_code': _lastResult?.exitCode,
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
        'submission_type': 'normal',
      });

      _submitted = true;
      _showSubmittedOverlay = true;
      _status = ExamStatus.ready;

      // ── Post-submit lockout ────────────────────────────────
      // Stop all background timers — no more editing, running, or
      // tab-switch tracking. The exam is permanently locked.
      _examLocked = true;
      _countdownTimer?.cancel();
      _autosaveTimer?.cancel();
      _assignmentPollTimer?.cancel();
      _autosave.dispose();
      await _autosave.clearSaved(_autosaveKey);
      // ──────────────────────────────────────────────────────

      notifyListeners();
      return true;
    } catch (e) {
      _status = ExamStatus.ready;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // dismissOverlay is kept for auto-submit / malpractice flow only.
  void dismissOverlay() {
    _showSubmittedOverlay = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    _autosaveTimer?.cancel();
    _assignmentPollTimer?.cancel();
    _autosave.dispose();
    super.dispose();
  }
}
