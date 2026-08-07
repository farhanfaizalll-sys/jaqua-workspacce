import 'package:flutter/material.dart';

import '../models/device.dart';
import '../models/feed_schedule.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  final Device device;
  const ScheduleScreen({super.key, required this.device});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<FeedSchedule> _schedules = [];
  bool _loading = true;
  String? _error;

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
      final schedules = await ApiService.instance.listSchedules(widget.device.id);
      if (mounted) setState(() => _schedules = schedules);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showGagalKirim() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal terhubung ke server, coba lagi')),
      );
    }
  }

  Future<void> _addSchedule() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    try {
      await ApiService.instance.createSchedule(widget.device.id, jam: time.hour, menit: time.minute);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      _showGagalKirim();
    }
  }

  Future<void> _toggleEnabled(FeedSchedule s, bool enabled) async {
    setState(() {
      _schedules = _schedules
          .map((x) => x.id == s.id ? FeedSchedule(id: x.id, jam: x.jam, menit: x.menit, enabled: enabled) : x)
          .toList();
    });
    try {
      await ApiService.instance.updateSchedule(s.id, enabled: enabled);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      _load();
    } catch (_) {
      _showGagalKirim();
      _load();
    }
  }

  Future<void> _delete(FeedSchedule s) async {
    try {
      await ApiService.instance.deleteSchedule(s.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      _showGagalKirim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Pakan')),
      floatingActionButton: FloatingActionButton(onPressed: _addSchedule, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.textMuted)))
              : _schedules.isEmpty
                  ? const Center(
                      child: Text('Belum ada jadwal. Tap + untuk menambah.', style: TextStyle(color: AppTheme.textMuted)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _schedules.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final s = _schedules[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: AppTheme.primary),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    s.label,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                  ),
                                ),
                                Switch(value: s.enabled, onChanged: (v) => _toggleEnabled(s, v), activeThumbColor: AppTheme.primary),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                                  onPressed: () => _delete(s),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
