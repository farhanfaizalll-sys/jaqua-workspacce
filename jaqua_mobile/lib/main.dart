import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'services/api_service.dart';

void main() {
  runApp(const JaquaApp());
}

class JaquaApp extends StatelessWidget {
  const JaquaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jaqua',
      theme: AppTheme.lightTheme,
      home: const SessionGate(),
    );
  }
}

/// Cek sesi login tersimpan saat app dibuka, lalu arahkan ke HomeShell
/// (kalau token masih valid) atau ke Login.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _checked = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final loggedIn = await ApiService.instance.restoreSession();
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? const HomeShell() : const LoginScreen();
  }
}
