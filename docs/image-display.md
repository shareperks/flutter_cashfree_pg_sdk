# Image Display API

How images are resolved, fetched, cached, and rendered across the SharePerks
Flutter app.

The pipeline has four layers:

1. **URL resolution** — `imageUrl()` turns any stored value (bare key, query
   key, full URL) into a loadable HTTPS URL via the file proxy.
2. **Raster rendering** — `ImageBuilder` loads cached network bitmaps with a
   shimmer placeholder and a broken-image fallback.
3. **Logo rendering** — `NetworkLogo` handles SVG **and** raster logos, with an
   automatic SVG fallback when a raster decode fails.
4. **Email-coupon rendering** — `EmailCouponNetworkImage` fetches coupon images
   with a hard timeout and degrades to a placeholder instead of throwing.

Asset (bundled) images are loaded directly with `SvgPicture.asset` /
`Image.asset` and are not part of the network pipeline.

---

## 1. URL resolution — `imageUrl()`

**File:** `lib/utils/image_url.dart`

```dart
String imageUrl(String url)
```

Normalizes any image reference into a loadable HTTPS URL. Always run stored
image strings through this before passing them to a widget — the raw bucket URL
is never persisted on records; only the storage **key** is, and `imageUrl()`
wraps it through the proxy so the bucket URL never leaks to clients.

### Resolution rules (in order)

| Input shape | Example | Output |
| --- | --- | --- |
| `data:` URI | `data:image/png;base64,…` | returned unchanged |
| URL with `?key=` / `&key=` | `https://x.com/img?key=file-123.webp` | `https://backend-api.shareperks.in/api/file/get/?key=file-123.webp` |
| Protocol-relative `//…` | `//cdn.x.com/a.png` | `https://cdn.x.com/a.png` |
| Full `http(s)://` URL | `https://cdn.x.com/a.png` | returned unchanged |
| Bare storage key | `file-123.webp` | `https://backend-api.shareperks.in/api/file/get/?key=file-123.webp` |
| Empty string | `""` | `""` |

### Usage

```dart
import 'package:shareperks/utils/image_url.dart';

ImageBuilder(
  imageUrl: imageUrl(reward.image ?? ""),
  width: 160,
  height: 121,
  fit: BoxFit.cover,
);
```

> **Note:** `imageUrl()` prints each resolved URL to the console (`print(...)`)
> for debugging. The `print` calls are tagged `image_url:`.

---

## 2. Raster images — `ImageBuilder`

**File:** `.tmp/soui/lib/elements/ImageBuilder.dart`
**Package:** `soui/elements/ImageBuilder.dart`
**Backed by:** `cached_network_image` + `flutter_cache_manager` (shared
`DefaultCacheManager` disk cache).

The default widget for any network raster (PNG / JPG / WebP). Shows a
`ShimmerBuilder` skeleton while loading and a broken-image icon on failure.
Disk + memory cached, so each URL downloads once per device.

### Constructor

```dart
ImageBuilder({
  required String imageUrl,        // already-resolved URL (run through imageUrl())
  required double width,
  required double height,
  double borderRadius = 0,         // clips image, placeholder, and error state
  double? shimmerBorderRadius,     // defaults to borderRadius
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
  Widget? errorWidget,             // replaces default broken-image UI
  Map<String, String>? httpHeaders,
  String? cacheKey,
  BaseCacheManager? cacheManager,
  Duration fadeInDuration = const Duration(milliseconds: 250),
  Duration fadeOutDuration = const Duration(milliseconds: 150),
  Curve fadeInCurve = Curves.easeOut,
  Curve fadeOutCurve = Curves.easeOut,
  int? memCacheWidth,              // in-memory decode size
  int? memCacheHeight,             // pass only ONE of width/height to keep aspect
  int? maxWidthDiskCache,
  int? maxHeightDiskCache,
  Color? color,
  BlendMode? colorBlendMode,
  FilterQuality filterQuality = FilterQuality.low,
  bool showDownloadProgress = false, // thin LinearProgressIndicator while loading
})
```

### Behavior notes

- **Memory decode sizing:** if you omit `memCacheWidth` / `memCacheHeight`, the
  widget auto-scales by `MediaQuery.devicePixelRatioOf(context)` on the width
  axis only (keeps aspect ratio). If you pass **both**, the shorter side is
  dropped to avoid a stretched decode that would fight `BoxFit.cover`.
- **Empty URL:** renders `errorWidget` (or the default broken-image state)
  immediately — no network attempt.
- **`borderRadius`** wraps the whole thing in `ClipRRect`, so the shimmer and
  error states are clipped too.

### Example

```dart
import 'package:soui/elements/ImageBuilder.dart';
import 'package:shareperks/utils/image_url.dart';

ImageBuilder(
  imageUrl: imageUrl(brand.image ?? ""),
  width: 160,
  height: 121,
  fit: BoxFit.cover,
  borderRadius: 16,
);
```

Used by: `BrandCard`, `RewardCard`, `ClaimedCard`, `PerkBasicInfo`,
`CompanyViewScreen`, `BrandViewScreen`, `HomeScreen`, etc.

---

## 3. Logos — `NetworkLogo`

**File:** `lib/components/NetworkLogo.dart`

Logos may arrive as SVG **or** raster with no reliable extension. `NetworkLogo`
detects SVGs and routes them through `flutter_svg`; everything else goes through
`ImageBuilder`. If a raster decode fails on an extension-less URL, it retries
through the SVG renderer before giving up.

### Constructor

```dart
NetworkLogo({
  required String imageUrl,         // resolved URL
  required double width,
  required double height,
  double borderRadius = 0,
  BoxFit fit = BoxFit.cover,         // raster fit
  BoxFit svgFit = BoxFit.contain,    // SVG fit (contain so vector marks aren't cropped)
  EdgeInsets padding = EdgeInsets.zero,
  Color? backgroundColor,           // shows through SVG negative space
  Widget? errorWidget,
})
```

### SVG detection — `NetworkLogo.isSvgUrl(url)`

Returns `true` when the URL is a `data:image/svg` URI, ends in `.svg`, or
contains `image/svg` / `format=svg`.

### Caching

SVG bytes are fetched through `DefaultCacheManager().getSingleFile(url)` (the
same shared disk cache `ImageBuilder` uses), then painted with
`SvgPicture.memory` — `SvgPicture.network` has no disk cache of its own.

### Example

```dart
import 'package:shareperks/components/NetworkLogo.dart';
import 'package:shareperks/utils/image_url.dart';

NetworkLogo(
  imageUrl: imageUrl(broker.logo ?? ""),
  width: 40,
  height: 40,
  borderRadius: 8,
  backgroundColor: Colors.white,
);
```

Used by: `MyHoldingScreen` (broker logos), and internally by `ImageBuilder`
fallback paths.

---

## 4. Email-coupon images — `EmailCouponNetworkImage`

**File:** `lib/components/EmailCouponNetworkImage.dart`

Coupon / email images are fetched with a hard timeout via a raw `HttpClient`
(not the cached pipeline) so a slow / dead image host degrades to a placeholder
instead of throwing `NetworkImage` exceptions. Supports SVG and raster.

### Constructor

```dart
EmailCouponNetworkImage({
  required String? url,
  BoxFit fit = BoxFit.cover,
  bool compact = false,             // smaller placeholder padding
  BorderRadius? borderRadius,
  Duration loadTimeout = const Duration(seconds: 6),
})
```

### Static helpers

```dart
static bool isSvgUrl(String url)        // .svg / image/svg / format=svg
static bool isLoadableUrl(String? raw)  // http(s)://, //, data:image (cid: is NOT loadable)
static String normalizeUrl(String raw)  // prefixes 'https:' to '//…' URLs
```

### Behavior

- `cid:` attachments → not loadable → placeholder.
- `data:image` URIs → currently unsupported → placeholder.
- HTTP fetch follows up to 5 redirects; non-2xx → placeholder.
- SVG bytes render via `SvgPicture.memory` on a white background with
  `BoxFit.contain`; raster bytes render via `Image.memory`.
- `borderRadius` wraps the result in `ClipRRect`.

### Example

```dart
import 'package:shareperks/components/EmailCouponNetworkImage.dart';

EmailCouponNetworkImage(
  url: coupon.imageUrl,
  fit: BoxFit.contain,
  borderRadius: BorderRadius.circular(12),
);
```

Used by: `EmailCouponCard`, `EmailCouponsHomeSection`, `EmailCouponDetailScreen`.

---

## 5. Asset (bundled) images

Bundled SVGs / PNGs live under `assets/` and are referenced through the generated
`Assets` constants (`lib/constants/assets.dart`) and rendered directly — they do
**not** go through `imageUrl()` or the network widgets.

```dart
import 'package:flutter_svg/svg.dart';
import 'package:shareperks/constants/assets.dart';

SvgPicture.asset(Assets.ASSETS_ICONS_NEWADDITIONS_SVG);
```

Use these for icons, badges, and any static artwork shipped with the app.

---

## 6. Uploading images — `FileUploadService`

**File:** `lib/repository/services/files/files.service.dart`

```dart
class UploadedFile {
  final String url;  // full HTTPS URL (e.g. Cloudflare R2 path-style URL)
  final String key;  // storage key to persist on the record
}

static Future<UploadedFile> FileUploadService.uploadFile(String filePath)
```

`POST /files/upload` (multipart, field name `file`) against `Host.listingUrl`.
Auth header is attached by the existing Dio interceptor.

### Critical rule

**Persist `UploadedFile.key` on the record (e.g. `image` on the user profile) —
never the raw URL.** Read sites wrap the key through `imageUrl()` → the proxy
`/api/file/get/?key=…`, so the bucket URL never leaks and stays valid even if
the bucket / account changes.

```dart
final uploaded = await FileUploadService.uploadFile(file.path);
await updateProfile(image: uploaded.key); // store the KEY, not uploaded.url
```

---

## 7. Choosing the right widget

| You have… | Use |
| --- | --- |
| A network raster (PNG/JPG/WebP) | `ImageBuilder(imageUrl: imageUrl(x))` |
| A logo that might be SVG or raster | `NetworkLogo(imageUrl: imageUrl(x))` |
| An email-coupon / untrusted-host image | `EmailCouponNetworkImage(url: x)` |
| A bundled asset | `SvgPicture.asset(...)` / `Image.asset(...)` |
| A user-uploaded file to send | `FileUploadService.uploadFile(path)` then store the `key` |

### Golden rules

1. **Always wrap stored image values in `imageUrl()`** before rendering — even
   if they look like full URLs today.
2. **Always pass explicit `width` + `height`** to `ImageBuilder` /
   `NetworkLogo`; both default to required params and the memory-decode sizing
   depends on them.
3. **Store upload keys, not URLs**, on any persistent record.
4. **Don't reach for `Image.network` / `NetworkImage` directly** — they have no
   disk cache and throw on failure. Use `ImageBuilder` instead.
