String imageUrl(String url) {
  final raw = url.trim();
  if (raw.isEmpty) return raw;
  if (raw.startsWith('data:')) return raw;

  // Any URL/path that carries a storage key should use the SharePerks file proxy.
  // Examples:
  // - file-123.webp
  // - gomein.com?key=file-123.webp
  // - https://gomein.com?key=file-123.webp
  // - https://backend-api.shareperks.in/api/file/get/?key=file-123.webp
  final keyFromQuery = RegExp(
    r'[?&]key=([^&\s#]+)',
    caseSensitive: false,
  ).firstMatch(raw)?.group(1);
  if (keyFromQuery != null && keyFromQuery.isNotEmpty) {
    final key = Uri.decodeComponent(keyFromQuery);
    final resolved =
        'https://backend-api.shareperks.in/api/file/get/?key=$key';
    // ignore: avoid_print
    print('image_url: $resolved');
    return resolved;
  }

  if (raw.startsWith('//')) {
    final resolved = 'https:$raw';
    // ignore: avoid_print
    print('image_url: $resolved');
    return resolved;
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    // ignore: avoid_print
    print('image_url: $raw');
    return raw;
  }

  // Bare storage key, e.g. file-123.webp
  final resolved =
      'https://backend-api.shareperks.in/api/file/get/?key=$raw';
  // ignore: avoid_print
  print('image_url: $resolved');
  return resolved;
}
