import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Logo loaded from a URL that may be an SVG **or** a raster (PNG/JPG/WebP).
///
/// SVG sources render with `flutter_svg`; everything else goes through
/// [ImageBuilder]'s cached raster pipeline. Bytes for both paths come from the
/// shared [DefaultCacheManager] disk cache, so a logo downloads once per device.
///
/// When a URL carries no hint at all (no extension, no mime in the query) the
/// raster path runs first and falls back to the SVG renderer if the bytes fail
/// to decode as a bitmap — which is what an extension-less SVG looks like.
class NetworkLogo extends StatelessWidget {
  const NetworkLogo({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.svgFit = BoxFit.contain,
    this.padding = EdgeInsets.zero,
    this.backgroundColor,
    this.errorWidget,
  });

  final String imageUrl;
  final double width;
  final double height;

  /// Clips the loaded logo, the shimmer, and the error state alike.
  final double borderRadius;

  /// Fit for raster logos.
  final BoxFit fit;

  /// Fit for SVG logos — [BoxFit.contain] by default so vector marks with an
  /// odd viewBox aren't cropped the way a bitmap crop would be.
  final BoxFit svgFit;

  /// Inset applied to the logo inside [width] x [height] (useful for SVG marks
  /// drawn edge to edge).
  final EdgeInsets padding;

  /// Painted behind the logo — SVGs are transparent, so this is what shows
  /// through their negative space.
  final Color? backgroundColor;

  /// Replaces the default broken-image UI when the URL is empty or fails.
  final Widget? errorWidget;

  /// True when [url] points at an SVG, judged by extension, mime, or data URI.
  static bool isSvgUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('data:image/svg')) return true;
    final path = (Uri.tryParse(trimmed)?.path ?? trimmed).toLowerCase();
    if (path.endsWith('.svg')) return true;
    return lower.contains('image/svg') || lower.contains('format=svg');
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    final fallback = errorWidget ?? _LogoError(width: width, height: height);

    final Widget logo;
    if (url.isEmpty) {
      logo = fallback;
    } else if (isSvgUrl(url)) {
      logo = _CachedNetworkSvg(
        url: url,
        width: width,
        height: height,
        fit: svgFit,
        borderRadius: borderRadius,
        errorWidget: fallback,
      );
    } else {
      logo = ImageBuilder(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        // A raster decode failure on a logo URL usually means the bytes were
        // SVG all along, so retry through the vector renderer before giving up.
        errorWidget: _CachedNetworkSvg(
          url: url,
          width: width,
          height: height,
          fit: svgFit,
          borderRadius: borderRadius,
          errorWidget: fallback,
        ),
      );
    }

    Widget child = logo;
    if (padding != EdgeInsets.zero) {
      child = Padding(padding: padding, child: child);
    }
    if (backgroundColor != null) {
      child = ColoredBox(color: backgroundColor!, child: child);
    }
    child = SizedBox(width: width, height: height, child: child);

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      );
    }
    return child;
  }
}

/// Fetches SVG bytes through the shared disk cache, then paints them with
/// [SvgPicture.memory] — `SvgPicture.network` has no disk cache of its own.
class _CachedNetworkSvg extends StatefulWidget {
  const _CachedNetworkSvg({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.borderRadius,
    required this.errorWidget,
  });

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;
  final Widget errorWidget;

  @override
  State<_CachedNetworkSvg> createState() => _CachedNetworkSvgState();
}

class _CachedNetworkSvgState extends State<_CachedNetworkSvg> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _load(widget.url);
  }

  @override
  void didUpdateWidget(covariant _CachedNetworkSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = _load(widget.url);
    }
  }

  static Future<Uint8List?> _load(String url) async {
    try {
      if (url.toLowerCase().startsWith('data:')) {
        return Uri.parse(url).data?.contentAsBytes();
      }
      final file = await DefaultCacheManager().getSingleFile(url);
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Widget get _shimmer => ShimmerBuilder(
    width: widget.width,
    height: widget.height,
    radius: widget.borderRadius,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return _shimmer;

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return widget.errorWidget;

        return SvgPicture.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholderBuilder: (_) => _shimmer,
          errorBuilder: (_, _, _) => widget.errorWidget,
        );
      },
    );
  }
}

/// Mirrors [ImageBuilder]'s default broken-image state so raster and vector
/// logos fail the same way.
class _LogoError extends StatelessWidget {
  const _LogoError({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = (width < height ? width : height) * 0.32;

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: iconSize.clamp(20.0, 56.0),
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
