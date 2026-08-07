import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user.dart';
import '../models/device.dart';
import '../models/sensor_reading.dart';
import '../models/feed_schedule.dart';
import '../models/feed_event.dart';

/// Thrown when the backend responds with `{ error: { code, message } }`.
class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, this.message);

  @override
  String toString() => message;
}

/// Klien tipis ke backend Express (lihat jaqua_backend/src/routes).
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = kApiBaseUrl;
  static const String _tokenPrefsKey = 'jaqua_auth_token';

  String? authToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  dynamic _decode(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body['data'];
    final error = body['error'] as Map<String, dynamic>?;
    throw ApiException(
      error?['code'] as String? ?? 'UNKNOWN_ERROR',
      error?['message'] as String? ?? 'Terjadi kesalahan pada server.',
    );
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl/api$path').replace(queryParameters: query);

  // ── Session ───────────────────────────────────────────────

  Future<void> _persistToken(String token) async {
    authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, token);
  }

  /// Dipanggil sekali saat app start. Mengembalikan `true` kalau ada sesi
  /// tersimpan dan token-nya masih valid (dicek via GET /api/auth/me).
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenPrefsKey);
    if (token == null) return false;
    authToken = token;
    try {
      await me();
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> clearSession() async {
    authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefsKey);
  }

  // ── Auth ──────────────────────────────────────────────────

  Future<AppUser> register({required String email, required String password, String? name}) async {
    final res = await http.post(
      _uri('/auth/register'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password, if (name != null) 'name': name}),
    );
    final data = _decode(res) as Map<String, dynamic>;
    await _persistToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login({required String email, required String password}) async {
    final res = await http.post(
      _uri('/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res) as Map<String, dynamic>;
    await _persistToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> me() async {
    final res = await http.get(_uri('/auth/me'), headers: _headers);
    return AppUser.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await http.post(_uri('/auth/logout'), headers: _headers);
    } finally {
      await clearSession();
    }
  }

  // ── Devices ───────────────────────────────────────────────

  Future<List<Device>> listDevices() async {
    final res = await http.get(_uri('/devices'), headers: _headers);
    final data = _decode(res) as List<dynamic>;
    return data.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Device> createDevice({required String name, required String deviceCode}) async {
    final res = await http.post(
      _uri('/devices'),
      headers: _headers,
      body: jsonEncode({'name': name, 'deviceCode': deviceCode}),
    );
    return Device.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<Device> getDevice(String id) async {
    final res = await http.get(_uri('/devices/$id'), headers: _headers);
    return Device.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<Device> setPower(String id, bool isOn) async {
    final res = await http.patch(
      _uri('/devices/$id/power'),
      headers: _headers,
      body: jsonEncode({'isOn': isOn}),
    );
    return Device.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> feedNow(String id) async {
    final res = await http.post(_uri('/devices/$id/feed-now'), headers: _headers);
    _decode(res);
  }

  // ── Schedules ─────────────────────────────────────────────

  Future<List<FeedSchedule>> listSchedules(String deviceId) async {
    final res = await http.get(_uri('/devices/$deviceId/schedules'), headers: _headers);
    final data = _decode(res) as List<dynamic>;
    return data.map((e) => FeedSchedule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FeedSchedule> createSchedule(String deviceId, {required int jam, required int menit}) async {
    final res = await http.post(
      _uri('/devices/$deviceId/schedules'),
      headers: _headers,
      body: jsonEncode({'jam': jam, 'menit': menit, 'enabled': true}),
    );
    return FeedSchedule.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<FeedSchedule> updateSchedule(String scheduleId, {bool? enabled, int? jam, int? menit}) async {
    final res = await http.patch(
      _uri('/schedules/$scheduleId'),
      headers: _headers,
      body: jsonEncode({
        if (enabled != null) 'enabled': enabled,
        if (jam != null) 'jam': jam,
        if (menit != null) 'menit': menit,
      }),
    );
    return FeedSchedule.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final res = await http.delete(_uri('/schedules/$scheduleId'), headers: _headers);
    _decode(res);
  }

  // ── History ───────────────────────────────────────────────

  Future<List<SensorReading>> getReadings(String deviceId, {int limit = 50}) async {
    final res = await http.get(
      _uri('/devices/$deviceId/history/readings', {'limit': '$limit'}),
      headers: _headers,
    );
    final data = _decode(res) as List<dynamic>;
    return data.map((e) => SensorReading.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FeedEvent>> getFeedEvents(String deviceId, {int limit = 50}) async {
    final res = await http.get(
      _uri('/devices/$deviceId/history/feed-events', {'limit': '$limit'}),
      headers: _headers,
    );
    final data = _decode(res) as List<dynamic>;
    return data.map((e) => FeedEvent.fromJson(e as Map<String, dynamic>)).toList();
  }
}
