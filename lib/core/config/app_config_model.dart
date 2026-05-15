// ============================================================
// File: lib/core/config/app_config_model.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Typed Dart model for app_config.json. Holds server URL,
//              Python runtime path, exam intervals, and client version.
// ============================================================

class AppConfig {
  final ServerConfig server;
  final PythonConfig python;
  final ExamConfig exam;
  final ClientConfig client;

  const AppConfig({
    required this.server,
    required this.python,
    required this.exam,
    required this.client,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        server: ServerConfig.fromJson(json['server'] as Map<String, dynamic>),
        python: PythonConfig.fromJson(json['python'] as Map<String, dynamic>),
        exam: ExamConfig.fromJson(json['exam'] as Map<String, dynamic>),
        client: ClientConfig.fromJson(json['client'] as Map<String, dynamic>),
      );
}

class ServerConfig {
  final String baseUrl;
  final int heartbeatIntervalSeconds;

  const ServerConfig({required this.baseUrl, required this.heartbeatIntervalSeconds});

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        baseUrl: json['base_url'] as String,
        heartbeatIntervalSeconds: json['heartbeat_interval_seconds'] as int,
      );
}

class PythonConfig {
  final String executablePath;
  final String runnerScript;
  final int timeoutSeconds;

  const PythonConfig({
    required this.executablePath,
    required this.runnerScript,
    required this.timeoutSeconds,
  });

  factory PythonConfig.fromJson(Map<String, dynamic> json) => PythonConfig(
        executablePath: json['executable_path'] as String,
        runnerScript: json['runner_script'] as String,
        timeoutSeconds: json['timeout_seconds'] as int,
      );
}

class ExamConfig {
  final int autosaveIntervalSeconds;
  final bool fullscreen;
  final int defaultDurationMinutes;

  const ExamConfig({
    required this.autosaveIntervalSeconds,
    required this.fullscreen,
    required this.defaultDurationMinutes,
  });

  factory ExamConfig.fromJson(Map<String, dynamic> json) => ExamConfig(
        autosaveIntervalSeconds: json['autosave_interval_seconds'] as int,
        fullscreen: json['fullscreen'] as bool,
        defaultDurationMinutes: json['default_duration_minutes'] as int,
      );
}

class ClientConfig {
  final String version;

  const ClientConfig({required this.version});

  factory ClientConfig.fromJson(Map<String, dynamic> json) =>
      ClientConfig(version: json['version'] as String);
}
