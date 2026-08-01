import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/utils/image_url.dart';
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

    var content = trimmed;
    if (!RegExp(r'<[a-zA-Z][^>]*>').hasMatch(content)) {
      content = content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) => '<p>$line</p>')
          .join();
    }

    // Repair a few common CMS HTML typos that break the parser.
    content = content
        .replaceAll(RegExp(r'</strong<', caseSensitive: false), '</strong>')
        .replaceAll(RegExp(r'</b<', caseSensitive: false), '</b>')
        .replaceAll(RegExp(r'</p<', caseSensitive: false), '</p>');

    // Collapse empty / whitespace-only paragraphs and stacked breaks.
    content = content
        .replaceAll(
          RegExp(r'<p>(\s|&nbsp;|<br\s*/?>)*</p>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'(<br\s*/?>\s*){2,}', caseSensitive: false),
          '<br/>',
        )
        .replaceAll(RegExp(r'(\s*&nbsp;\s*){2,}', caseSensitive: false), ' ')
        .trim();

    // Normalize every <img src> to the SharePerks file proxy URL.
    content = content.replaceAllMapped(
      RegExp(
        r'''(<img\b[^>]*?\b(?:src|data-src)\s*=\s*["'])([^"']+)(["'])''',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}${imageUrl(match.group(2)!)}${match.group(3)}',
    );

    return content;
  }

  static String? _rawImageSrc(Map<Object, String> attributes) {
    for (final attr in ['src', 'data-src', 'data-lazy-src', 'data-original']) {
      final value = attributes[attr]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Widget? _buildHtmlImage(dynamic element) {
    if (element.localName != 'img') return null;

    final rawSrc = _rawImageSrc(element.attributes);
    if (rawSrc == null) return const SizedBox.shrink();

    final url = imageUrl(rawSrc);
    if (url.isEmpty) return const SizedBox.shrink();

    // ignore: avoid_print
    print('html_img: raw=$rawSrc => $url');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              height: 120,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // ignore: avoid_print
            print('html_img_error: $url error=$error');
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF3F4F6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Image unavailable',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
                  height: 1.35,
                  fontFamily: SharePerksFonts.inter,
                ),
                customWidgetBuilder: _buildHtmlImage,
                customStylesBuilder: (element) {
                  switch (element.localName) {
                    case 'p':
                      return {'margin': '0 0 6px 0', 'padding': '0'};
                    case 'li':
                      return {'margin': '0 0 4px 0', 'padding': '0'};
                    case 'ul':
                    case 'ol':
                      return {
                        'margin': '0 0 8px 0',
                        'padding-left': '18px',
                      };
                    case 'h1':
                    case 'h2':
                    case 'h3':
                    case 'h4':
                      return {'margin': '8px 0 4px 0', 'padding': '0'};
                    case 'br':
                      return {'line-height': '1.1'};
                    default:
                      return null;
                  }
                },
              ),
            ),
    );
  }
}
