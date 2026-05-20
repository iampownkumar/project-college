// ============================================================
// File: lib/core/config/config_loader.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Singleton loader that reads config/app_config.json
//              from Flutter assets at startup before runApp().
// ============================================================

import 'dart:convert';
import 'package:flutter/services.dart';
import 'app_config_model.dart';

class ConfigLoader {
  static AppConfig? _instance;

  static AppConfig get instance {
    assert(_instance != null, 'ConfigLoader.load() must be called before accessing instance');
    return _instance!;
  }

  /// Call once in main() before runApp().
  static Future<void> load() async {
    final raw = await rootBundle.loadString('config/app_config.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _instance = AppConfig.fromJson(json);
  }
}
