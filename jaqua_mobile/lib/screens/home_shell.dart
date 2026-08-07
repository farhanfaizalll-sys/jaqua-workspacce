import 'package:flutter/material.dart';

import '../models/device.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'history_screen.dart';
import 'account_screen.dart';
import 'add_device_screen.dart';

/// Shell utama setelah login: bottom nav dengan 4 tab. Memuat daftar
/// perangkat sekali di sini supaya semua tab berbagi state yang sama,
/// dan menampilkan alur "Tambah Alat" kalau akun belum punya perangkat.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await ApiService.instance.listDevices();
      if (!mounted) return;
      setState(() => _devices = devices);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 40, color: AppTheme.textMuted),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Coba lagi')),
              ],
            ),
          ),
        ),
      );
    }

    if (_devices.isEmpty) {
      return AddDeviceScreen(onAdded: _load);
    }

    final device = _devices.first;

    final tabs = [
      DashboardScreen(device: device, onDeviceChanged: _load),
      ScheduleScreen(device: device),
      HistoryScreen(device: device),
      const AccountScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: tabs)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Jadwal'),
          NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}
