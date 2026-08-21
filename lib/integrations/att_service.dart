import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AttStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  notApplicable,
  unknown,
}

extension AttStatusX on AttStatus {
  static AttStatus fromName(String? raw) {
    switch (raw) {
      case 'notDetermined':
        return AttStatus.notDetermined;
      case 'restricted':
        return AttStatus.restricted;
      case 'denied':
        return AttStatus.denied;
      case 'authorized':
        return AttStatus.authorized;
      case 'notApplicable':
        return AttStatus.notApplicable;
      default:
        return AttStatus.unknown;
    }
  }
}

/// iOS App Tracking Transparency. No-op on Android / web.
///
/// Native [AttCoordinator] presents Apple's system dialog when the scene is
/// active. Dart waits on that result before initializing tracking SDKs.
class AttService {
  AttService._();
  static final AttService instance = AttService._();

  static const _channel = MethodChannel('in.shareperks.app/att');

  AttStatus _status = AttStatus.notDetermined;
  bool _resolved = false;

  AttStatus get status => _status;

  /// True when advertising identifiers may be used (ATT authorized, or not iOS).
  bool get allowsAdvertisingTracking =>
      _status == AttStatus.authorized || _status == AttStatus.notApplicable;

  Future<AttStatus> ensureRequested() async {
    if (_resolved) return _status;

    if (kIsWeb || !Platform.isIOS) {
      _status = AttStatus.notApplicable;
      _resolved = true;
      debugPrint('[att] not iOS; skipping ATT prompt');
      return _status;
    }

    try {
      debugPrint('[att] waiting for native ATT authorization');
      final raw = await _channel
          .invokeMethod<String>('requestTrackingAuthorization')
          .timeout(const Duration(seconds: 90));
      _status = AttStatusX.fromName(raw);
      debugPrint('[att] status=$_status');
    } on PlatformException catch (e, st) {
      debugPrint('[att] platform error: ${e.code} ${e.message}\n$st');
      _status = AttStatus.unknown;
    } catch (e, st) {
      debugPrint('[att] request failed: $e\n$st');
      _status = AttStatus.unknown;
    }

    _resolved = true;
    return _status;
  }
}
