// ============================================================
// File: lib/core/config/app_config_model.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Typed Dart model for app_config.json. Holds server URL,
//              Python runtime path, exam intervals, client version, and
//              an optional debug section for dev/test overrides.
// ============================================================

class AppConfig {
  final ServerConfig server;
  final PythonConfig python;
  final ExamConfig exam;
  final ClientConfig client;
  final DebugConfig debug;

  const AppConfig({
    required this.server,
    required this.python,
    required this.exam,
    required this.client,
    this.debug = const DebugConfig(),
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        server: ServerConfig.fromJson(json['server'] as Map<String, dynamic>),
        python: PythonConfig.fromJson(json['python'] as Map<String, dynamic>),
        exam: ExamConfig.fromJson(json['exam'] as Map<String, dynamic>),
        client: ClientConfig.fromJson(json['client'] as Map<String, dynamic>),
        debug: json['debug'] != null
            ? DebugConfig.fromJson(json['debug'] as Map<String, dynamic>)
            : const DebugConfig(),
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
  final int maxStrikes;

  const ExamConfig({
    required this.autosaveIntervalSeconds,
    required this.fullscreen,
    required this.defaultDurationMinutes,
    this.maxStrikes = 1,
  });

  factory ExamConfig.fromJson(Map<String, dynamic> json) => ExamConfig(
        autosaveIntervalSeconds: json['autosave_interval_seconds'] as int,
        fullscreen: json['fullscreen'] as bool,
        defaultDurationMinutes: json['default_duration_minutes'] as int,
        maxStrikes: (json['max_strikes'] as int?) ?? 1,
      );
}

class ClientConfig {
  final String version;

  const ClientConfig({required this.version});

  factory ClientConfig.fromJson(Map<String, dynamic> json) =>
      ClientConfig(version: json['version'] as String);
}

/// Debug / dev-testing overrides. All flags default to false so the
/// production build is never affected when the [debug] block is absent
/// from app_config.json.
class DebugConfig {
  /// Master switch — must be true for any debug flag to take effect.
  final bool enabled;

  /// When true, all focus-loss / tab-switch tracking is silently ignored.
  /// Students can alt-tab freely without triggering the strike counter.
  final bool disableFocusTracking;

  /// When true, Ctrl+C / Ctrl+V / Ctrl+X work normally in the editor.
  /// Set to false in production to prevent code cheating.
  final bool allowCopyPaste;

  /// When true, skips the bundled venv and calls system `python3` directly.
  /// Use this when the bundled venv symlinks are broken (e.g. release build
  /// copied to a different machine or the venv was regenerated).
  final bool forceSystemPython;

  const DebugConfig({
    this.enabled = false,
    this.disableFocusTracking = false,
    this.allowCopyPaste = false,
    this.forceSystemPython = false,
  });

  factory DebugConfig.fromJson(Map<String, dynamic> json) => DebugConfig(
        enabled: json['enabled'] as bool? ?? false,
        disableFocusTracking:
            json['disable_focus_tracking'] as bool? ?? false,
        allowCopyPaste: json['allow_copy_paste'] as bool? ?? false,
        forceSystemPython: json['force_system_python'] as bool? ?? false,
      );

  /// Returns true when this flag is active (enabled AND the specific flag).
  bool get isFocusTrackingDisabled => enabled && disableFocusTracking;
  bool get isCopyPasteAllowed => enabled && allowCopyPaste;
  bool get isForceSystemPython => enabled && forceSystemPython;
}
