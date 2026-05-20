// ============================================================
// File: lib/app/app.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Root MaterialApp — wires ThemeProvider, AuthProvider,
//              and lazily creates ExamProvider scoped to the exam route.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'theme.dart';
import '../data/services/python_runner_service.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/exam/exam_provider.dart';
import '../features/exam/exam_screen.dart';
import '../features/setup/setup_screen.dart';
import '../features/theme/theme_provider.dart';

class LabExamApp extends StatelessWidget {
  const LabExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, tp, _) => MaterialApp(
          title: 'Koreliurm Labs — Exam Client',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: tp.mode,
          // Go to setup screen if venv isn't ready, else straight to login
          initialRoute: PythonRunnerService.isVenvReady
              ? AppRoutes.login
              : AppRoutes.setup,
          onGenerateRoute: _onGenerateRoute,
        ),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.setup:
        return MaterialPageRoute(
          builder: (ctx) => SetupScreen(
            onSetupComplete: () =>
                Navigator.pushReplacementNamed(ctx, AppRoutes.login),
          ),
        );

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.exam:
        // Exam screen requires auth data passed via constructor.
        // We rebuild ExamProvider here so it's scoped to the exam screen.
        return MaterialPageRoute(
          builder: (ctx) {
            final auth = ctx.read<AuthProvider>();
            final navCtx = ctx; // capture before async gap
            return ChangeNotifierProvider(
              create: (_) => ExamProvider(
                student: auth.student!,
                session: auth.session!,
                assignment: auth.assignment!,
                onSessionExpired: () {
                  // Auto-submit was already done inside ExamProvider.
                  // Navigate back to login and show an info message.
                  Navigator.of(navCtx).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (_) => false,
                  );
                  ScaffoldMessenger.of(navCtx).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '⏰ Exam session has ended. Your work has been submitted.'),
                      duration: Duration(seconds: 6),
                      backgroundColor: Color(0xFF8B5CF6),
                    ),
                  );
                },
              ),
              child: const ExamScreen(),
            );
          },
        );

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
