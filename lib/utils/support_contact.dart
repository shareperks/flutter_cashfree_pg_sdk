import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// SharePerks support contact details and launch helpers.
class SupportContact {
  SupportContact._();

  static const String email = 'shareperks@gmail.com';
  static const String phoneDisplay = '+91 7014733904';
  static const String phoneE164 = '917014733904';

  static Future<void> openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQuery({'subject': 'SharePerks Support'}),
    );
    await _launch(context, uri, 'Could not open your email app');
  }

  static Future<void> openPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '+$phoneE164');
    await _launch(context, uri, 'Could not open the phone dialer');
  }

  static Future<void> openWhatsApp(BuildContext context) async {
    const message = 'Hi SharePerks team, I need help with';
    final uri = Uri.parse(
      'https://wa.me/$phoneE164?text=${Uri.encodeComponent(message)}',
    );
    await _launch(
      context,
      uri,
      'Could not open WhatsApp. Make sure it is installed.',
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> _launch(
    BuildContext context,
    Uri uri,
    String errorMessage, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      final launched = await launchUrl(uri, mode: mode);
      if (!launched && context.mounted) {
        _showError(context, errorMessage);
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, errorMessage);
      }
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String? _encodeQuery(Map<String, String> params) {
    if (params.isEmpty) return null;
    return params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }
}
