// ============================================================
// File: lib/data/services/autosave_service.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Periodic autosave service that persists student code
//              to SharedPreferences on a configurable timer interval.
// ============================================================

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class AutosaveService {
  Timer? _timer;
  final Duration interval;

  AutosaveService({int intervalSeconds = 15})
      : interval = Duration(seconds: intervalSeconds);

  void start({required String Function() codeGetter, required String key}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final code = codeGetter();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${AppConstants.autosaveKeyPrefix}$key', code);
    });
  }

  Future<String?> loadSaved(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${AppConstants.autosaveKeyPrefix}$key');
  }

  Future<void> clearSaved(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${AppConstants.autosaveKeyPrefix}$key');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
