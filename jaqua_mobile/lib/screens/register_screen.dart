import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;

import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../services/api_service.dart';
import 'home_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password harus diisi!')),
      );
      return;
    }
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.instance.register(
        email: _email.text.trim(),
        password: _password.text,
        name: _name.text.isEmpty ? null : _name.text.trim(),
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (_) => const HomeShell()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada koneksi internet atau server tidak dapat dijangkau.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak dapat terhubung ke server: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Akun',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textDark, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              const Text(
                'Daftar untuk mulai memantau kolam Anda',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              AppTextField(label: 'Nama (opsional)', hint: 'Nama Anda', icon: Icons.person_outline, controller: _name),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Email',
                hint: 'nama@email.com',
                icon: Icons.email_outlined,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Password',
                hint: 'Minimal 6 karakter',
                icon: Icons.lock_outline,
                controller: _password,
                obscure: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Daftar', onPressed: _loading ? null : _register, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}
