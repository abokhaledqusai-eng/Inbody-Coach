import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String? _cachedToken;
  static String? _workingUrl; // Cache the last working base URL

  static String get baseUrl => _workingUrl ?? _baseUrls.first;

  static List<String> get _baseUrls {
    if (kIsWeb) {
      return const [
        'http://127.0.0.1:8000/api',
        'http://localhost:8000/api',
      ];
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return const [
        'http://127.0.0.1:8000/api',              // 1. Physical USB via adb reverse (BEST FOR VIDEO STREAMING)
        'https://inbody-coach-zayed.loca.lt/api', // 2. Localtunnel (Internet - No cable needed)
        'http://10.138.207.131:8000/api',         // 3. Laptop local Wi-Fi IP
        'http://10.0.2.2:8000/api',               // 4. Android Emulator
      ];
    }

    return const [
      'https://cold-taxis-take.loca.lt/api',
      'http://127.0.0.1:8000/api',
    ];
  }

  /// Returns URLs in order: cached working URL first, then the rest as fallback
  static List<String> get _orderedUrls {
    if (_workingUrl == null) return _baseUrls;
    return [
      _workingUrl!,
      ..._baseUrls.where((u) => u != _workingUrl),
    ];
  }

  // Single Dio instance — headers & interceptors only, NO baseUrl mutation
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Accept': 'application/json',
      'Bypass-Tunnel-Reminder': 'true',
    },
  ));

  static Future<void> _setAuthToken() async {
    final token = _cachedToken ?? await getToken();
    if (token != null) {
      _cachedToken = token;
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// GET request — tries each URL independently (no shared state mutation)
  static Future<Response> get(String path) async {
    await _setAuthToken();
    DioException? lastException;

    for (final base in _orderedUrls) {
      try {
        final response = await _dio.get(
          '$base$path', // Full URL passed directly — no race condition
          options: Options(headers: Map.from(_dio.options.headers)),
        );
        _workingUrl = base; // ✅ Cache successful URL
        return response;
      } on DioException catch (e) {
        lastException = e;
      }
    }

    _workingUrl = null;
    throw lastException ?? Exception('API request failed');
  }

  /// POST request — tries each URL independently (no shared state mutation)
  static Future<Response> post(String path, dynamic data, {bool isMultipart = false}) async {
    await _setAuthToken();
    DioException? lastException;

    for (final base in _orderedUrls) {
      try {
        final headers = Map<String, dynamic>.from(_dio.options.headers);
        headers['Content-Type'] = isMultipart ? 'multipart/form-data' : 'application/json';

        final response = await _dio.post(
          '$base$path', // Full URL passed directly — no race condition
          data: data,
          options: Options(headers: headers),
        );
        _workingUrl = base; // ✅ Cache successful URL
        return response;
      } on DioException catch (e) {
        lastException = e;
      }
    }

    _workingUrl = null;
    throw lastException ?? Exception('API request failed');
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }
}
