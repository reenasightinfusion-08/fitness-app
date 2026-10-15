import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:fitness_app/core/config/api_config.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_model.dart';
import 'package:fitness_app/services/video_frame_service.dart';

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

  static Future<String> _getHost() async => ApiConfig.baseUrl;

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
      throw StretchServiceException(
        "Couldn't connect to server. Check your connection.",
      );
    }

    if (response.statusCode >= 400) {
      throw StretchServiceException(
        'Server returned HTTP ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] == false) {
      final message = body['message'] as String? ?? 'Failed to fetch stretches';
      throw StretchServiceException(message);
    }

    final list = body['data'] as List? ?? [];
    final stretches = list
        .map((json) => StretchModel.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final stretch in stretches) {
      VideoFrameService.prefetch(stretch.videoUrl, stretch.defaultHoldSeconds);
    }
    return stretches;
  }
}
