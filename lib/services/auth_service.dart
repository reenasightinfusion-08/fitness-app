import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Thrown for any auth failure the UI should show as-is (bad credentials,
/// wrong code, unreachable server, etc).
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Talks to the fitness-backend Express API and holds the JWT it hands
/// back in secure storage.
class AuthService {
  AuthService();

  /// Android emulator reaches the host machine at 10.0.2.2. On a physical
  /// device swap this for your computer's LAN IP (see backend/README.md);
  /// on the iOS simulator `localhost` works.
  static const _tokenKey = 'auth_token';

  /// Candidate addresses:
  /// - Live Vercel production backend (24/7 online)
  /// - 127.0.0.1:4000 (physical Android device with `adb reverse`, or desktop)
  /// - 10.0.2.2:4000 (standard Android Studio emulator)
  /// - 192.168.29.88:4000 (local Wi-Fi IP for physical phones without USB reverse)
  /// - localhost:4000 (desktop / web / iOS simulator)
  static const String _liveProductionHost =
      'https://fitness-backend-eight.vercel.app';

  static const List<String> _candidateHosts = [
    _liveProductionHost,
    'http://127.0.0.1:4000',
    'http://10.0.2.2:4000',
    'http://192.168.29.88:4000',
    'http://localhost:4000',
  ];

  static String? _resolvedHost;

  static Future<String> _getHost() async {
    if (_resolvedHost != null) return _resolvedHost!;

    for (final host in _candidateHosts) {
      try {
        final timeout = host.startsWith('https://')
            ? const Duration(seconds: 4)
            : const Duration(milliseconds: 800);
        final res = await http.get(Uri.parse('$host/health')).timeout(timeout);
        if (res.statusCode == 200) {
          debugPrint('[AuthService] Connected to backend at $host');
          _resolvedHost = host;
          return host;
        }
      } catch (e) {
        debugPrint('[AuthService] Probe to $host: $e');
      }
    }

    _resolvedHost = _liveProductionHost;
    debugPrint('[AuthService] Defaulting to live production at $_liveProductionHost');
    return _liveProductionHost;
  }

  static Future<String> _getBaseUrl() async => '${await _getHost()}/api/auth';

  final _storage = const FlutterSecureStorage();

  Future<void> signup({required String email, required String password}) =>
      _post('/signup', {'email': email, 'password': password});

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    final data = await _post('/verify-email', {'email': email, 'code': code});
    await _storage.write(key: _tokenKey, value: data['token'] as String);
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _post('/login', {'email': email, 'password': password});
    await _storage.write(key: _tokenKey, value: data['token'] as String);
  }

  Future<void> forgotPassword({required String email}) =>
      _post('/forgot-password', {'email': email});

  Future<void> resendCode({required String email, required String purpose}) =>
      _post('/resend-code', {'email': email, 'purpose': purpose});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _post('/reset-password', {
    'email': email,
    'code': code,
    'newPassword': newPassword,
  });

  Future<bool> hasSession() async =>
      (await _storage.read(key: _tokenKey)) != null;

  Future<void> logout() => _storage.delete(key: _tokenKey);

  Future<Map<String, dynamic>> getMe() => _authedGet('/users/me');

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> updates) =>
      _authedPatch('/users/me', updates);

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final baseUrl = await _getBaseUrl();
    final url = '$baseUrl$path';
    debugPrint('[AuthService] POST $url');

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[AuthService] request to $url failed: $e');
      _resolvedHost = null;
      throw AuthException("Couldn't reach the server. Check your connection.");
    }

    debugPrint('[AuthService] Response status: ${response.statusCode}');

    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      final errorMsg = data['error'] as String? ?? 'Something went wrong';
      debugPrint('[AuthService] Server returned error: $errorMsg');
      throw AuthException(errorMsg);
    }
    return data;
  }

  Future<String?> _authHeader() async {
    final token = await _storage.read(key: _tokenKey);
    return token == null ? null : 'Bearer $token';
  }

  Future<Map<String, dynamic>> _authedGet(String path) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .get(Uri.parse('$host/api$path'), headers: {'Authorization': auth})
        .timeout(const Duration(seconds: 10));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _authedPatch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .patch(
          Uri.parse('$host/api$path'),
          headers: {'Content-Type': 'application/json', 'Authorization': auth},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['error'] as String? ?? 'Something went wrong');
    }
    return data;
  }
}
