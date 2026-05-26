// ============================================================
// File: lib/main.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Entry point — loads app_config.json, initialises
//              the window manager (fullscreen/size), then runs
//              the Flutter application.
// ============================================================

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app/app.dart';
import 'core/config/config_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load app_config.json from assets before anything else.
  await ConfigLoader.load();

  // Window manager setup (title, minimum size, optional fullscreen).
  await windowManager.ensureInitialized();
  final fullscreen = ConfigLoader.instance.exam.fullscreen;

  final options = WindowOptions(
    title: 'Korelium Labs — Exam Client',
    minimumSize: const Size(960, 600),
    center: true,
    backgroundColor: Colors.transparent,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    if (fullscreen) {
      await windowManager.setFullScreen(true);
    } else {
      await windowManager.setSize(const Size(1280, 800));
    }
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const LabExamApp());
}
