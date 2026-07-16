# OneSignal Push Setup (Android + iOS)

Production-ready push for SharePerks. App ID: `1660b763-2ad4-484c-828d-f5c361aa376a`.

Flutter integration is already in place:

| File | Role |
|---|---|
| `lib/constants/onesignal_config.dart` | App ID via `--dart-define=ONESIGNAL_APP_ID=...` |
| `lib/integrations/onesignal_push.dart` | SDK facade (init / login / logout / opt-in / deep-link) |
| `lib/main.dart` | `OneSignalPush.init()` at startup |
| `lib/repository/providers/user.provider.dart` | Login/logout identity |
| `lib/screens/main/SettingScreen.dart` | Notifications toggle ↔ optIn/optOut |

Screens must **not** import `onesignal_flutter` directly.

---

## Android (FCM)

### 1. Firebase project

1. Firebase Console → add Android app with package `com.shareperks`.
2. Download `google-services.json`.
3. Place it at `android/app/google-services.json` (gitignored).  
   Template: `android/app/google-services.json.example`.
4. Gradle applies the Google Services plugin **only when that file exists**.

### 2. OneSignal dashboard

**Settings → Push & In-App → Google Android (FCM)** → upload Firebase service account / FCM credentials.

### 3. Verify

```bash
flutter run -d <android-device>
# Log in → accept permission → Audience → Subscriptions should show Subscribed
```

Optional: replace `android/app/src/main/res/drawable/ic_stat_onesignal_default.xml` with branded white-on-transparent artwork.

---

## iOS (APNs + NSE)

### 1. Dashboard

Upload APNs **p8** key in OneSignal → **Settings → Push & In-App → Apple iOS**.

### 2. Already done in repo

- Deployment target **iOS 15.0** (`Podfile` + `project.pbxproj`)
- `Runner/Runner.entitlements` — Push (`aps-environment`) + App Group `group.com.shareperks.onesignal`
- `Info.plist` — `UIBackgroundModes` → `remote-notification`
- NSE source ready under `ios/OneSignalNotificationServiceExtension/`

### 3. Xcode (manual, one-time)

Open `ios/Runner.xcworkspace`:

1. **Runner** target → **Signing & Capabilities**
   - Confirm **Push Notifications**
   - Confirm **Background Modes → Remote notifications**
   - Confirm **App Groups** → `group.com.shareperks.onesignal`
2. **File → New → Target → Notification Service Extension**
   - Name: `OneSignalNotificationServiceExtension`
   - Minimum deployment: **15.0**
   - Bundle ID: `com.shareperks.OneSignalNotificationServiceExtension`
   - When prompted to activate scheme: **Don't Activate**
3. Replace auto-generated `NotificationService.swift` with the file already in
   `ios/OneSignalNotificationServiceExtension/NotificationService.swift`
   (or point the target at that file).
4. On the **NSE** target → **Signing & Capabilities** → same App Group.
5. Set NSE **CODE_SIGN_ENTITLEMENTS** to
   `OneSignalNotificationServiceExtension/OneSignalNotificationServiceExtension.entitlements`
6. Uncomment the NSE CocoaPods target at the bottom of `ios/Podfile`, then:

```bash
cd ios && pod install && cd ..
```

7. For App Store / TestFlight builds, set `aps-environment` in
   `Runner/Runner.entitlements` to `production` (Xcode usually switches this via provisioning).

### 4. Verify

```bash
flutter run -d <ios-device>   # real device required for push
```

---

## Deep-link payload

Send in OneSignal **Additional Data**:

```json
{
  "screen": "GiftCardViewScreen",
  "rewardId": "abc123"
}
```

`screen` must match a known `RouteNames` value (same allow-list as in-app notifications).

---

## Release builds

```bash
flutter build apk --release \
  --dart-define=ONESIGNAL_APP_ID=1660b763-2ad4-484c-828d-f5c361aa376a

flutter build ipa --release \
  --dart-define=ONESIGNAL_APP_ID=1660b763-2ad4-484c-828d-f5c361aa376a
```

Verbose OneSignal logs are **debug-only** (`kDebugMode`).

---

## Test checklist

- [ ] Fresh install → login → permission prompt once
- [ ] Subscription **Subscribed** in OneSignal Audience
- [ ] Test push received (foreground + background)
- [ ] Tap push deep-links to correct screen
- [ ] Settings → notifications off → optOut (no delivery)
- [ ] Logout → `OneSignal.logout` (anonymous / unlinked)
- [ ] Release build: no verbose SDK logs
