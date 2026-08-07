import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../services/api_service.dart';
import 'account_screen.dart';

/// Ditampilkan saat akun belum punya perangkat terdaftar. `deviceCode` harus
/// persis sama dengan kode yang dipakai di topik MQTT firmware Gateway
/// (contoh: alat kolam sekarang mengirim ke topik "jaqua/kolam1/data", jadi
/// deviceCode-nya adalah "kolam1").
class AddDeviceScreen extends StatefulWidget {
  final VoidCallback onAdded;
  const AddDeviceScreen({super.key, required this.onAdded});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _name = TextEditingController(text: 'Kolam 1');
  final _code = TextEditingController(text: 'kolam1');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _code.text.trim().isEmpty) {
      setState(() => _error = 'Nama dan kode alat harus diisi');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.instance.createDevice(name: _name.text.trim(), deviceCode: _code.text.trim());
      widget.onAdded();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Gagal menyambungkan ke server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
            child: const Text('Akun'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.add_circle_outline, size: 48, color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Tambah Alat Jaqua',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Belum ada alat terdaftar di akun ini. Masukkan nama dan kode alat sesuai yang tertulis di kode Gateway/alat kolam.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              AppTextField(label: 'Nama Alat', hint: 'mis. Kolam 1', icon: Icons.label_outline, controller: _name),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Kode Alat (deviceCode)',
                hint: 'mis. kolam1',
                icon: Icons.qr_code,
                controller: _code,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppTheme.danger)),
              ],
              const SizedBox(height: 24),
              PrimaryButton(label: 'Tambah Alat', onPressed: _loading ? null : _submit, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}
