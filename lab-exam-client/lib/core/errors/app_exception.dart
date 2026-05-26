// ============================================================
// File: lib/core/errors/app_exception.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Sealed exception hierarchy for typed error handling
//              across network, runner, login, and question layers.
// ============================================================

sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the server is unreachable.
class ServerUnreachableException extends AppException {
  const ServerUnreachableException([super.message = 'Cannot reach the exam server.']);
}

/// Thrown when login fails (student not found, no session, etc.).
class LoginException extends AppException {
  const LoginException(super.message);
}

/// Thrown when a question cannot be fetched.
class QuestionException extends AppException {
  const QuestionException(super.message);
}

/// Thrown when the Python runner fails to execute.
class RunnerException extends AppException {
  const RunnerException(super.message);
}

/// Thrown for unexpected HTTP errors.
class ApiException extends AppException {
  final int? statusCode;
  const ApiException(super.message, {this.statusCode});
}
