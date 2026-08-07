import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/device.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

class DashboardScreen extends StatefulWidget {
  final Device device;
  final VoidCallback onDeviceChanged;

  const DashboardScreen({super.key, required this.device, required this.onDeviceChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Device _device = widget.device;
  bool _togglingPower = false;
  bool _feeding = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    // Poll for fresh readings every 15s so the temp/level feel "real-time"
    // without needing a persistent socket connection.
    _poller = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.id != widget.device.id) {
      setState(() => _device = widget.device);
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await ApiService.instance.getDevice(_device.id);
      if (mounted) setState(() => _device = fresh);
    } catch (_) {
      // Silent — the next poll tick will retry.
    }
  }

  Future<void> _togglePower(bool value) async {
    setState(() => _togglingPower = true);
    try {
      final updated = await ApiService.instance.setPower(_device.id, value);
      if (mounted) setState(() => _device = updated);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _togglingPower = false);
    }
  }

  Future<void> _feedNow() async {
    setState(() => _feeding = true);
    try {
      await ApiService.instance.feedNow(_device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perintah beri pakan terkirim')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _feeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _device;
    final lastSeenText = d.lastSeenAt == null
        ? 'Belum pernah kirim data'
        : 'Update terakhir: ${DateFormat('dd MMM yyyy HH:mm').format(d.lastSeenAt!.toLocal())}';

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(d.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              _PowerBadge(isOn: d.isOn),
            ],
          ),
          const SizedBox(height: 4),
          Text(lastSeenText, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.thermostat,
                  label: 'Suhu Air',
                  value: d.hasData ? '${d.lastSuhu!.toStringAsFixed(1)}°C' : '—',
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Sisa Pakan',
                  value: d.hasData ? '${d.lastLevelPeletPersen!.toStringAsFixed(0)}%' : '—',
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                const Icon(Icons.power_settings_new, color: AppTheme.textMuted),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Status Alat', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                ),
                _togglingPower
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(value: d.isOn, onChanged: _togglePower, activeThumbColor: AppTheme.primary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Beri Pakan Sekarang',
            icon: Icons.restaurant,
            onPressed: _feeding ? null : _feedNow,
            loading: _feeding,
          ),
          const SizedBox(height: 8),
          const Text(
            'Di luar jadwal otomatis — alat akan langsung memberi pakan begitu perintah diterima.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PowerBadge extends StatelessWidget {
  final bool isOn;
  const _PowerBadge({required this.isOn});

  @override
  Widget build(BuildContext context) {
    final color = isOn ? AppTheme.success : AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(isOn ? 'Aktif' : 'Nonaktif', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}
