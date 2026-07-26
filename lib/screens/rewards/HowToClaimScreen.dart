import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:soui/elements/SpScafold.dart';

/// Renders redeem / claim instructions (HTML or plain text with newlines).
class HowToClaimScreen extends StatelessWidget {
  const HowToClaimScreen({
    super.key,
    required this.html,
    this.title = 'How to claim',
  });

  final String html;
  final String title;

  /// Accepts CMS HTML as-is; converts plain newline text to simple HTML.
  static String normalizeContent(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (RegExp(r'<[a-zA-Z][^>]*>').hasMatch(trimmed)) return trimmed;
    return trimmed
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => '<p>$line</p>')
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final content = normalizeContent(html);

    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text(title),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
        toolbarHeight: 40,
      ),
      body: content.isEmpty
          ? Center(
              child: Text(
                'No claim instructions available.',
                style: TextStyle(
                  color: const Color(0xFF898989),
                  fontSize: 14,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: HtmlWidget(
                content,
                textStyle: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: SharePerksFonts.inter,
                ),
              ),
            ),
    );
  }
}
