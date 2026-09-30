import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:fitness_app/features/stretch_detail/models/stretch_model.dart';

/// Thrown when fetching or parsing stretches fails.
class StretchServiceException implements Exception {
  StretchServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Service that communicates with the Express backend to fetch stretch data.
class StretchService {
  StretchService();

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

  /// Automatically tests connection to backend candidate hosts (matching AuthService logic).
  static Future<String> _getHost() async {
    if (_resolvedHost != null) return _resolvedHost!;

    for (final host in _candidateHosts) {
      try {
        final timeout = host.startsWith('https://')
            ? const Duration(seconds: 4)
            : const Duration(milliseconds: 800);
        final res = await http.get(Uri.parse('$host/health')).timeout(timeout);
        if (res.statusCode == 200) {
          debugPrint('[StretchService] Connected to backend at $host');
          _resolvedHost = host;
          return host;
        }
      } catch (e) {
        debugPrint('[StretchService] Probe to $host: $e');
      }
    }

    _resolvedHost = _liveProductionHost;
    debugPrint('[StretchService] Defaulting to live production at $_liveProductionHost');
    return _liveProductionHost;
  }

  /// Fetches all active stretches from `GET /api/stretches`.
  Future<List<StretchModel>> fetchStretches() async {
    final host = await _getHost();
    final url = '$host/api/stretches';
    debugPrint('[StretchService] GET $url');

    final http.Response response;
    try {
      response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[StretchService] Request to $url failed: $e');
      _resolvedHost = null;
      throw StretchServiceException(
        "Couldn't connect to server. Check your connection.",
      );
    }

    if (response.statusCode >= 400) {
      throw StretchServiceException('Server returned HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] == false) {
      final message = body['message'] as String? ?? 'Failed to fetch stretches';
      throw StretchServiceException(message);
    }

    final list = body['data'] as List? ?? [];
    return list
        .map((json) => StretchModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
