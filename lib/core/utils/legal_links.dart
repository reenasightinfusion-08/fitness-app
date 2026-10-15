import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fitness_app/core/config/api_config.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

/// The public pages served by the backend (`backend/pages/legal.js`).
abstract final class LegalLinks {
  static const String privacy = '${ApiConfig.baseUrl}/privacy';
  static const String terms = '${ApiConfig.baseUrl}/terms';
  static const String support = '${ApiConfig.baseUrl}/support';

  static Future<void> open(BuildContext context, String url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('[LegalLinks] Could not open $url: $e');
    }
    if (!opened && context.mounted) {
      AppSnackBar.showError(context, "Couldn't open the page. Try again.");
    }
  }
}
