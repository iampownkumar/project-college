// ============================================================
// File: lib/features/auth/login_screen.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Student login screen with animated fade-in, server
//              status badge, registration number input, and error display.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../../app/routes.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _regController = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkServer();
    });
  }

  @override
  void dispose() {
    _regController.dispose();
    _focusNode.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final reg = _regController.text.trim();
    if (reg.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(reg);
    if (ok && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.exam);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F0F1A), const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFF0FDF4), const Color(0xFFFFFBEB)],
              ),
            ),
          ),

          // Theme toggle (top right)
          Positioned(
            top: 16,
            right: 16,
            child: _ThemeToggle(),
          ),

          // Center card
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _LoginCard(
                  regController: _regController,
                  focusNode: _focusNode,
                  onLogin: _handleLogin,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return IconButton(
      tooltip: tp.isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      icon: Icon(tp.isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round),
      onPressed: tp.toggle,
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController regController;
  final FocusNode focusNode;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.regController,
    required this.focusNode,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black12,
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo / title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Koreliurm Labs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      )),
                  Text('Lab Exam System',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      )),
                ],
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Server status badge
          _ServerStatusBadge(online: auth.serverOnline),

          const SizedBox(height: 28),

          Text('Student Login',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),

          const SizedBox(height: 8),
          Text('Enter your registration number to start the exam.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
              textAlign: TextAlign.center),

          const SizedBox(height: 28),

          // Registration number input
          TextField(
            controller: regController,
            focusNode: focusNode,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Registration Number',
              hintText: 'e.g. 21CSR001',
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),

          const SizedBox(height: 16),

          // Error message
          if (auth.status == AuthStatus.error)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(auth.error,
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
                  ),
                ],
              ),
            ),

          if (auth.status == AuthStatus.error) const SizedBox(height: 16),

          // Login button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: auth.status == AuthStatus.loading ? null : onLogin,
              child: auth.status == AuthStatus.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Start Exam', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Retry server check
          TextButton(
            onPressed: () => context.read<AuthProvider>().checkServer(),
            child: const Text('Re-check server connection'),
          ),
        ],
        ),
      ),
    );
  }
}

class _ServerStatusBadge extends StatelessWidget {
  final bool online;
  const _ServerStatusBadge({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final label = online ? 'Server Online' : 'Server Unreachable';
    final icon = online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
