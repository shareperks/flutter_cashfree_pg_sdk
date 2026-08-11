// File generated for SharePerks Firebase project shareperks-8269f.
// Re-run `flutterfire configure` after installing the `xcodeproj` gem to refresh.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'run flutterfire configure to regenerate.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run flutterfire configure to regenerate.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAhSL8OsKCie5U2NDzLu3hZaeidGCKdWLE',
    appId: '1:681535457811:web:f95bcd9e8dbb3f241e0de6',
    messagingSenderId: '681535457811',
    projectId: 'shareperks-8269f',
    authDomain: 'shareperks-8269f.firebaseapp.com',
    storageBucket: 'shareperks-8269f.appspot.com',
    measurementId: 'G-WVB4HMKPXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAxKBaZpKFwHZ81Nv60oEEgGsINepaeNMI',
    appId: '1:681535457811:android:01aed961d05e9a801e0de6',
    messagingSenderId: '681535457811',
    projectId: 'shareperks-8269f',
    storageBucket: 'shareperks-8269f.appspot.com',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBPgk-wpbLD3qqQ34879XJuSbBJOarhI3Q',
    appId: '1:681535457811:ios:db01d9b8a2fc92921e0de6',
    messagingSenderId: '681535457811',
    projectId: 'shareperks-8269f',
    storageBucket: 'shareperks-8269f.appspot.com',
    iosBundleId: 'com.shareperks',
  );
  /// Uses the iOS Firebase app (same bundle id `com.shareperks`).

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBPgk-wpbLD3qqQ34879XJuSbBJOarhI3Q',
    appId: '1:681535457811:ios:db01d9b8a2fc92921e0de6',
    messagingSenderId: '681535457811',
    projectId: 'shareperks-8269f',
    storageBucket: 'shareperks-8269f.appspot.com',
    iosBundleId: 'com.shareperks',
  );
}
