// ============================================================
// File: lib/data/models/test_case_result.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Immutable result model for a single test case run.
//              Holds input, expected output, actual output, pass/fail
//              flag, stderr, and execution duration.
// ============================================================

/// Result of running one test case against the student's code.
class TestCaseResult {
  /// 0-based index of this test case in the question's example list.
  final int index;

  /// The stdin that was sent to the program.
  final String input;

  /// The expected stdout from the question.
  final String expected;

  /// The actual stdout produced by the student's code.
  final String actual;

  /// True if [actual] matches [expected] after smart normalization.
  final bool passed;

  /// Any stderr output from the program.
  final String stderr;

  /// How long the run took in milliseconds.
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
