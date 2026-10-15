import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:fitness_app/core/config/api_config.dart';
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

  static Future<String> _getHost() async => ApiConfig.baseUrl;

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
