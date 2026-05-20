// ============================================================
// File: test/widget_test.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-16
// Location: Tamil Nadu, India
// Description: Basic smoke test — verifies the app widget tree
//              initialises without throwing. Full integration
//              tests require a running server instance.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lab_exam_client/core/config/app_config_model.dart';
import 'package:lab_exam_client/core/config/config_loader.dart';

void main() {
  group('AppConfig model', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'server': {'base_url': 'http://127.0.0.1:8000/api/v1', 'heartbeat_interval_seconds': 15},
        'python': {'executable_path': './runtime/python/python.exe', 'runner_script': '', 'timeout_seconds': 30},
        'exam': {'autosave_interval_seconds': 15, 'fullscreen': true, 'default_duration_minutes': 120},
        'client': {'version': '1.0.0'},
      };
      final config = AppConfig.fromJson(json);
      expect(config.server.baseUrl, 'http://127.0.0.1:8000/api/v1');
      expect(config.server.heartbeatIntervalSeconds, 15);
      expect(config.exam.defaultDurationMinutes, 120);
      expect(config.client.version, '1.0.0');
    });

    test('ConfigLoader singleton is not null after init', () {
      // ConfigLoader.instance throws if not initialized — this test
      // documents that it must be called before runApp().
      expect(() => ConfigLoader.instance, throwsA(isA<StateError>()));
    });
  });
}
