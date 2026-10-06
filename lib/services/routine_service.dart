import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/services/video_frame_service.dart';

/// Thrown when fetching or parsing routines fails.
class RoutineServiceException implements Exception {
  RoutineServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Service that communicates with the Express backend to fetch routine data.
class RoutineService {
  RoutineService();

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

  /// Automatically tests connection to backend candidate hosts (matching StretchService/AuthService logic).
  static Future<String> _getHost() async {
    if (_resolvedHost != null) return _resolvedHost!;

    for (final host in _candidateHosts) {
      try {
        final timeout = host.startsWith('https://')
            ? const Duration(seconds: 4)
            : const Duration(milliseconds: 800);
        final res = await http.get(Uri.parse('$host/health')).timeout(timeout);
        if (res.statusCode == 200) {
          debugPrint('[RoutineService] Connected to backend at $host');
          _resolvedHost = host;
          return host;
        }
      } catch (e) {
        debugPrint('[RoutineService] Probe to $host: $e');
      }
    }

    _resolvedHost = _liveProductionHost;
    debugPrint('[RoutineService] Defaulting to live production at $_liveProductionHost');
    return _liveProductionHost;
  }

  /// Fetches all active routines from `GET /api/routines`.
  Future<List<RoutineSummary>> fetchRoutines() async {
    final host = await _getHost();
    final url = '$host/api/routines';
    debugPrint('[RoutineService] GET $url');

    final http.Response response;
    try {
      response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[RoutineService] Request to $url failed: $e');
      _resolvedHost = null;
      throw RoutineServiceException(
        "Couldn't connect to server. Check your connection.",
      );
    }

    if (response.statusCode >= 400) {
      throw RoutineServiceException('Server returned HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] == false) {
      final message = body['message'] as String? ?? 'Failed to fetch routines';
      throw RoutineServiceException(message);
    }

    final list = body['data'] as List? ?? [];
    final routines = list
        .map((json) => RoutineSummary.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final routine in routines) {
      for (final stretch in routine.stretches) {
        final model = stretch.model;
        VideoFrameService.prefetch(model?.videoUrl, model?.defaultHoldSeconds ?? 30);
      }
    }
    return routines;
  }
}
