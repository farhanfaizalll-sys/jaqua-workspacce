import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/device.dart';
import '../models/sensor_reading.dart';
import '../models/feed_event.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  final Device device;
  const HistoryScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat'),
          bottom: const TabBar(tabs: [Tab(text: 'Sensor'), Tab(text: 'Pemberian Pakan')]),
        ),
        body: TabBarView(
          children: [
            _ReadingsTab(deviceId: device.id),
            _FeedEventsTab(deviceId: device.id),
          ],
        ),
      ),
    );
  }
}

class _ReadingsTab extends StatefulWidget {
  final String deviceId;
  const _ReadingsTab({required this.deviceId});

  @override
  State<_ReadingsTab> createState() => _ReadingsTabState();
}

class _ReadingsTabState extends State<_ReadingsTab> {
  List<SensorReading> _readings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final readings = await ApiService.instance.getReadings(widget.deviceId, limit: 50);
      if (mounted) setState(() => _readings = readings);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_readings.isEmpty) {
      return const Center(child: Text('Belum ada data sensor', style: TextStyle(color: AppTheme.textMuted)));
    }

    // API returns newest-first; chart reads left-to-right chronologically.
    final chronological = _readings.reversed.toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: AppTheme.cardShadow),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < chronological.length; i++)
                        FlSpot(i.toDouble(), chronological[i].suhu),
                    ],
                    isCurved: true,
                    color: AppTheme.accent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppTheme.accent.withValues(alpha: 0.12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Suhu air (°C) — data terbaru di kanan', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          ..._readings.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusSm), boxShadow: AppTheme.cardShadow),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM HH:mm').format(r.recordedAt.toLocal()),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ),
                    Text('${r.suhu.toStringAsFixed(1)}°C', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 16),
                    Text('${r.levelPeletPersen.toStringAsFixed(0)}% pakan', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedEventsTab extends StatefulWidget {
  final String deviceId;
  const _FeedEventsTab({required this.deviceId});

  @override
  State<_FeedEventsTab> createState() => _FeedEventsTabState();
}

class _FeedEventsTabState extends State<_FeedEventsTab> {
  List<FeedEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await ApiService.instance.getFeedEvents(widget.deviceId, limit: 50);
      if (mounted) setState(() => _events = events);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_events.isEmpty) {
      return const Center(child: Text('Belum ada riwayat pemberian pakan', style: TextStyle(color: AppTheme.textMuted)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _events.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final e = _events[i];
          final manual = e.triggeredBy == 'MANUAL';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusSm), boxShadow: AppTheme.cardShadow),
            child: Row(
              children: [
                Icon(manual ? Icons.touch_app : Icons.schedule, color: manual ? AppTheme.accent : AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    manual ? 'Diberi pakan manual' : 'Pakan otomatis (jadwal)',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  ),
                ),
                Text(DateFormat('dd MMM HH:mm').format(e.createdAt.toLocal()), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
