import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/theme_data.dart';

/// Loads coupon / email images via timed HTTP fetch.
/// Timeouts / socket errors become an empty-coupon placeholder (no
/// NetworkImage exception spam).
class EmailCouponNetworkImage extends StatefulWidget {
  const EmailCouponNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.compact = false,
    this.borderRadius,
    this.loadTimeout = const Duration(seconds: 6),
  });

  final String? url;
  final BoxFit fit;
  final bool compact;
  final BorderRadius? borderRadius;
  final Duration loadTimeout;

  static bool isSvgUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    final path = (uri?.path ?? url).toLowerCase();
    if (path.endsWith('.svg')) return true;
    final lower = url.toLowerCase();
    return lower.contains('image/svg') || lower.contains('format=svg');
  }

  static bool isLoadableUrl(String? raw) {
    final url = raw?.trim() ?? '';
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.startsWith('cid:')) return false;
    if (lower.startsWith('data:image')) return true;
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return true;
    }
    if (lower.startsWith('//')) return true;
    return false;
  }

  static String normalizeUrl(String raw) {
    final url = raw.trim();
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }

  @override
  State<EmailCouponNetworkImage> createState() =>
      _EmailCouponNetworkImageState();
}

class _EmailCouponNetworkImageState extends State<EmailCouponNetworkImage> {
  Uint8List? _bytes;
  bool _failed = false;
  bool _loading = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant EmailCouponNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    final raw = widget.url?.trim() ?? '';

    if (!EmailCouponNetworkImage.isLoadableUrl(raw)) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _bytes = null;
        _failed = true;
        _loading = false;
      });
      return;
    }

    // data: URIs aren't fetched over HTTP — leave them unsupported for now.
    if (raw.toLowerCase().startsWith('data:image')) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _bytes = null;
        _failed = true;
        _loading = false;
      });
      return;
    }

    setState(() {
      _bytes = null;
      _failed = false;
      _loading = true;
    });

    final bytes = await _fetchBytes(
      EmailCouponNetworkImage.normalizeUrl(raw),
      widget.loadTimeout,
    );

    if (!mounted || token != _loadToken) return;
    setState(() {
      _loading = false;
      if (bytes == null || bytes.isEmpty) {
        _failed = true;
        _bytes = null;
      } else {
        _failed = false;
        _bytes = bytes;
      }
    });
  }

  static Future<Uint8List?> _fetchBytes(String url, Duration timeout) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..idleTimeout = timeout;
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = true;
      request.maxRedirects = 5;
      final response = await request.close().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final bytes = await consolidateHttpClientResponseBytes(
        response,
      ).timeout(timeout);
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_failed || (!_loading && _bytes == null)) {
      child = EmailCouponImagePlaceholder(compact: widget.compact);
    } else if (_loading || _bytes == null) {
      child = EmailCouponImagePlaceholder(compact: widget.compact);
    } else {
      final resolved = EmailCouponNetworkImage.normalizeUrl(
        widget.url!.trim(),
      );
      if (EmailCouponNetworkImage.isSvgUrl(resolved)) {
        child = ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(widget.compact ? 10 : 20),
            child: SvgPicture.memory(
              _bytes!,
              fit: widget.fit == BoxFit.cover
                  ? BoxFit.contain
                  : widget.fit,
              placeholderBuilder: (_) =>
                  EmailCouponImagePlaceholder(compact: widget.compact),
              errorBuilder: (_, _, _) =>
                  EmailCouponImagePlaceholder(compact: widget.compact),
            ),
          ),
        );
      } else {
        child = Image.memory(
          _bytes!,
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) =>
              EmailCouponImagePlaceholder(compact: widget.compact),
        );
      }
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }
}

/// Empty coupon visual used when no image is available / failed to load.
class EmailCouponImagePlaceholder extends StatelessWidget {
  const EmailCouponImagePlaceholder({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SharePerksColors.surfaceLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 34 : 52,
              height: compact ? 34 : 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SharePerksColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(compact ? 10 : 14),
              ),
              child: Icon(
                HugeIconsSolid.couponPercent,
                size: compact ? 18 : 26,
                color: SharePerksColors.primary.withValues(alpha: 0.55),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 10),
              Text(
                'No image',
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
