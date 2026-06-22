import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/network.dart';

/// Result of `POST /files/upload`.
///
/// - [url]: the full HTTPS URL the server responded with (typically a
///   Cloudflare R2 path-style URL like
///   `https://<acct>.r2.cloudflarestorage.com/<bucket>/<key>`). Useful for
///   immediate previews / debug.
/// - [key]: the storage key suitable for persisting (e.g. on the user
///   profile). Read sites wrap this through `imageUrl()` -> the proxy
///   `/api/file/get/?key=…` so the bucket URL never leaks to clients and
///   stays valid even if the bucket / account changes.
class UploadedFile {
  const UploadedFile({required this.url, required this.key});

  final String url;
  final String key;
}

/// Generic file upload against the data_service `POST /files/upload` route.
///
/// Sends a single `multipart/form-data` request with the field name **file**
/// and parses the response into an [UploadedFile]. The server may return
/// the URL under any of `location`, `publicUrl`, or `url` and the storage
/// key under any of `key`, `fileKey`, `objectKey`, or `Key` (and may wrap
/// either in a `data` envelope). [_extract] handles all common shapes.
class FileUploadService {
  FileUploadService._();

  static final Dio _dio = createDio(Host.listingUrl);

  static const _urlKeys = <String>['location', 'publicUrl', 'url'];
  static const _keyKeys = <String>['key', 'fileKey', 'objectKey', 'Key'];

  /// Uploads the file at [filePath] and returns both the public URL and the
  /// storage key. Auth header is attached by the existing interceptor.
  ///
  /// Persist [UploadedFile.key] on the user record (e.g. `image` on the
  /// profile) — never the raw URL — so the proxy in `imageUrl()` can serve
  /// it via `/api/file/get/?key=…`.
  static Future<UploadedFile> uploadFile(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/files/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Upload: empty response body');
    }
    final inner = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : null;

    final url = _extract(body, _urlKeys) ??
        (inner != null ? _extract(inner, _urlKeys) : null);
    if (url == null || url.isEmpty) {
      throw StateError('Upload: response missing file URL');
    }

    final serverKey = _extract(body, _keyKeys) ??
        (inner != null ? _extract(inner, _keyKeys) : null);
    final key = serverKey ?? _deriveKeyFromUrl(url) ?? url;

    return UploadedFile(url: url, key: key);
  }

  static String? _extract(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Derives the storage key from an upload URL when the server doesn't
  /// surface it directly.
  ///
  /// Handles Cloudflare R2 **path-style** URLs of the form
  /// `https://<accountid>.r2.cloudflarestorage.com/<bucket>/<key…>` — the
  /// first path segment is the bucket and is dropped. Anything else falls
  /// back to the full path. Returns `null` for malformed URIs so the caller
  /// can fall back to storing the URL verbatim.
  static String? _deriveKeyFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    final segments =
        uri.pathSegments.where((s) => s.isNotEmpty).toList(growable: false);
    if (segments.isEmpty) return null;

    if (uri.host.endsWith('.r2.cloudflarestorage.com') &&
        segments.length >= 2) {
      return segments.sublist(1).join('/');
    }
    return segments.join('/');
  }
}
