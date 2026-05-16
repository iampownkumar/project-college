// ============================================================
// File: lib/features/exam/exam_provider.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Central ChangeNotifier for the exam workspace.
//              Manages question fetch, countdown timer, heartbeat,
//              autosave, local code execution, run log, and submission.
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/config/config_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/login_response_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/runner_result_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/python_runner_service.dart';
import '../../data/services/autosave_service.dart';
import '../../core/utils/machine_info.dart';

enum ExamStatus { loading, ready, running, submitting, submitted, error }

/// Timer warning levels shown as top banners.
enum TimerWarning { none, thirtyMin, tenMin, fiveMin, expired }

/// Result of running one test case.
class TestCaseResult {
  final int index;          // 0-based case index
  final String input;       // stdin sent
  final String expected;    // expected stdout
  final String actual;      // actual stdout produced
  final bool passed;        // trimmed comparison
  final String stderr;
  final int durationMs;

  const TestCaseResult({
    required this.index,
    required this.input,
    required this.expected,
    required this.actual,
    required this.passed,
    required this.stderr,
    required this.durationMs,
  });
}

class ExamProvider extends ChangeNotifier {
  final ApiService _api;
  final PythonRunnerService _runner;
  final AutosaveService _autosave;

  final StudentModel student;
  final SessionModel session;
  final AssignmentModel assignment;

  ExamProvider({
    required this.student,
    required this.session,
    required this.assignment,
    ApiService? api,
    PythonRunnerService? runner,
    AutosaveService? autosave,
  })  : _api = api ?? ApiService(),
        _runner = runner ?? PythonRunnerService(),
        _autosave = autosave ?? AutosaveService(
          intervalSeconds: ConfigLoader.instance.exam.autosaveIntervalSeconds,
        );

  // ── State ─────────────────────────────────────────────────
  ExamStatus _status = ExamStatus.loading;
  String _error = '';
  QuestionModel? _question;
  RunnerResult? _lastResult;
  bool _serverOnline = true;
  bool _submitted = false;

  String _currentCode = '';
  String _stdinInput = '';

  // Timer
  late Duration _remaining;
  Timer? _countdownTimer;

  // Heartbeat
  Timer? _heartbeatTimer;

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

  // Whether exam is locked due to repeated focus loss
  bool _focusLocked = false;
  bool get focusLocked => _focusLocked;

  static const int _maxFocusLossStrikes = 3;

  // Test case results (populated after runCode)
  List<TestCaseResult> _testCaseResults = [];
  List<TestCaseResult> get testCaseResults => List.unmodifiable(_testCaseResults);
  bool _isTestingCases = false;
  bool get isTestingCases => _isTestingCases;

  Duration get remaining => _remaining;
  DateTime? get lastSavedAt => _lastSavedAt;
  String get stdinInput => _stdinInput;

  void setStdin(String v) {
    _stdinInput = v;
    notifyListeners();
  }

  void updateCode(String code) {
    _currentCode = code;
  }

  // ── Init ──────────────────────────────────────────────────
  Future<void> initialize() async {
    _status = ExamStatus.loading;
    notifyListeners();

    try {
      // Compute timer from session data or use default
      _remaining = _computeInitialTimer();

      // Load question
      final json = await _api.fetchAssignedQuestion(student.registrationNumber);
      _question = QuestionModel.fromJson(json);

      // Try to restore autosaved code
      final savedCode = await _autosave.loadSaved(_autosaveKey);
      _currentCode = savedCode ?? _question!.starterCode ?? '';

      _status = ExamStatus.ready;
      notifyListeners();

      _startCountdown();
      _startHeartbeat();
      _startAutosave();
    } catch (e) {
      _status = ExamStatus.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  String get _autosaveKey => '${student.registrationNumber}_${assignment.questionId}';

  Duration _computeInitialTimer() {
    if (session.endTime != null) {
      final diff = session.endTime!.difference(DateTime.now().toUtc());
      return diff.isNegative ? Duration.zero : diff;
    }
    return Duration(minutes: session.durationMinutes > 0
        ? session.durationMinutes
        : AppConstants.defaultExamDurationMinutes);
  }

  // ── Countdown timer ───────────────────────────────────────
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 0) {
        _countdownTimer?.cancel();
        _timerWarning = TimerWarning.expired;
        notifyListeners();
        _autoSubmitOnExpiry();
        return;
      }
      _remaining = _remaining - const Duration(seconds: 1);
      _updateTimerWarning();
      notifyListeners();
    });
  }

  void _updateTimerWarning() {
    final mins = _remaining.inMinutes;
    if (mins <= 5 && _timerWarning != TimerWarning.fiveMin && _timerWarning != TimerWarning.expired) {
      _timerWarning = TimerWarning.fiveMin;
    } else if (mins <= 10 && mins > 5 && _timerWarning == TimerWarning.none || _timerWarning == TimerWarning.thirtyMin) {
      _timerWarning = TimerWarning.tenMin;
    } else if (mins <= 30 && mins > 10 && _timerWarning == TimerWarning.none) {
      _timerWarning = TimerWarning.thirtyMin;
    }
  }

  /// Auto-submit when timer expires — standard college exam behaviour.
  Future<void> _autoSubmitOnExpiry() async {
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
  /// After 3 strikes the exam is locked and auto-submitted.
  void recordFocusLoss() {
    if (_focusLocked) return; // already locked
    _focusLostCount++;
    notifyListeners();

    if (_focusLostCount >= _maxFocusLossStrikes) {
      _focusLocked = true;
      _countdownTimer?.cancel(); // stop timer
      _autoSubmitOnExpiry();    // force submit immediately
    }
  }

  // ── Heartbeat ─────────────────────────────────────────────
  void _startHeartbeat() {
    final interval = ConfigLoader.instance.server.heartbeatIntervalSeconds;
    _heartbeatTimer = Timer.periodic(Duration(seconds: interval), (_) => _sendHeartbeat());
    _sendHeartbeat(); // immediate first ping
  }

  Future<void> _sendHeartbeat() async {
    try {
      final ip = await MachineInfo.getMachineIp();
      await _api.postHeartbeat({
        'registration_number': student.registrationNumber,
        'session_id': session.id,
        'machine_name': MachineInfo.machineName,
        'machine_ip': ip,
        'client_state': _status.name,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      _serverOnline = true;
    } catch (_) {
      _serverOnline = false;
    }
    notifyListeners();
  }

  // ── Autosave ──────────────────────────────────────────────
  void _startAutosave() {
    _autosave.start(
      codeGetter: () => _currentCode,
      key: _autosaveKey,
    );
    // Update timestamp periodically
    Timer.periodic(
      Duration(seconds: ConfigLoader.instance.exam.autosaveIntervalSeconds),
      (_) {
        _lastSavedAt = DateTime.now();
        notifyListeners();
      },
    );
  }

  // ── Run code ──────────────────────────────────────────────
  Future<void> runCode() async {
    if (_status == ExamStatus.running || _currentCode.isEmpty) return;

    _status = ExamStatus.running;
    _lastResult = null;
    notifyListeners();

    final start = DateTime.now();

    try {
      final result = await _runner.run(
        sourceCode: _currentCode,
        stdin: _stdinInput.isEmpty ? null : _stdinInput,
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
        );
        final actual = r.stdout.trimRight();
        final expected = ex.output.trimRight();
        results.add(TestCaseResult(
          index: i,
          input: ex.input,
          expected: expected,
          actual: actual,
          passed: actual == expected,
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
    // Re-submission is allowed — each submit overwrites the previous on server.
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
      });

      _submitted = true;
      _showSubmittedOverlay = true;
      _status = ExamStatus.ready; // back to ready so button stays active
      await _autosave.clearSaved(_autosaveKey);
      notifyListeners();
      return true;
    } catch (e) {
      _status = ExamStatus.ready;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void dismissOverlay() {
    _showSubmittedOverlay = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    _autosave.dispose();
    super.dispose();
  }
}
