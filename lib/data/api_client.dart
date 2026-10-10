import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

/// REST client for the Health Circle backend (`backend/server.py`).
///
/// Base URL resolution order:
///  1. `--dart-define=API_BASE=https://your-host`  (release / APK builds)
///  2. Web: same host as the page, port 5061 (sandbox preview)
///  3. Android emulator default `http://10.0.2.2:5061`
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _defineBase = String.fromEnvironment('API_BASE', defaultValue: '');
  String? _token;
  String? _baseOverride;

  String get baseUrl {
    if (_baseOverride != null && _baseOverride!.isNotEmpty) return _baseOverride!;
    if (_defineBase.isNotEmpty) return _defineBase;
    if (kIsWeb) {
      final u = Uri.base;
      // sandbox preview hosts look like 5060-xxxx.sandbox.novita.ai → swap port prefix
      if (u.host.startsWith('5060-')) {
        return '${u.scheme}://${u.host.replaceFirst('5060-', '5061-')}';
      }
      return '${u.scheme}://${u.host}:5061';
    }
    return 'http://10.0.2.2:5061';
  }

  String? get token => _token;
  bool get isAuthed => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _token = p.getString('auth_token');
      _baseOverride = p.getString('api_base');
    } catch (_) {}
  }

  Future<void> setToken(String? t) async {
    _token = t;
    try {
      final p = await SharedPreferences.getInstance();
      if (t == null) {
        await p.remove('auth_token');
      } else {
        await p.setString('auth_token', t);
      }
    } catch (_) {}
  }

  Future<void> setBaseOverride(String? url) async {
    _baseOverride = url;
    try {
      final p = await SharedPreferences.getInstance();
      if (url == null || url.isEmpty) {
        await p.remove('api_base');
      } else {
        await p.setString('api_base', url);
      }
    } catch (_) {}
  }

  /// Resolve asset-ish URLs returned by the API (`/uploads/x.jpg`, `/assets/...`).
  String resolve(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http')) return url;
    if (url.startsWith('/uploads/')) return '$baseUrl$url';
    return url; // `/assets/...` → bundled flutter asset (strip leading slash by caller)
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (isAuthed) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http
        .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers).timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  Future<String> upload(Uint8List bytes) async {
    final res = await http
        .post(Uri.parse('$baseUrl/api/upload'), headers: {'Content-Type': 'application/octet-stream'}, body: bytes)
        .timeout(const Duration(seconds: 20));
    final j = _decode(res);
    return j['url'] as String;
  }

  dynamic _decode(http.Response res) {
    dynamic j;
    try {
      j = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiException('服务器响应格式错误', res.statusCode);
    }
    if (res.statusCode >= 400) {
      throw ApiException((j is Map && j['error'] != null) ? j['error'].toString() : '请求失败 (${res.statusCode})', res.statusCode);
    }
    return j;
  }
}
