import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

import 'biometric_auth_result.dart';

/// Reusable wrapper around [LocalAuthentication] for sensitive screens.
class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Checks whether the device can show a local auth prompt (biometrics and/or
  /// device PIN / passcode / pattern).
  Future<BiometricAvailability> checkAvailability() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) {
        return const BiometricAvailability(
          isDeviceSupported: false,
          canCheckBiometrics: false,
          availableBiometrics: [],
          canAuthenticate: false,
        );
      }

      var canCheckBiometrics = false;
      var availableBiometrics = <String>[];

      try {
        canCheckBiometrics = await _auth.canCheckBiometrics;
        final types = await _auth.getAvailableBiometrics();
        availableBiometrics = types.map(_biometricLabel).toList();
      } on PlatformException {
        // Older Android devices may throw here; device credential auth can still work.
      }

      return BiometricAvailability(
        isDeviceSupported: true,
        canCheckBiometrics: canCheckBiometrics,
        availableBiometrics: availableBiometrics,
        canAuthenticate: true,
      );
    } catch (_) {
      return const BiometricAvailability(
        isDeviceSupported: false,
        canCheckBiometrics: false,
        availableBiometrics: [],
        canAuthenticate: false,
      );
    }
  }

  /// Prompts the user. Falls back to device credentials when biometrics are
  /// unavailable or not enrolled ([biometricOnly] is false).
  Future<BiometricAuthResult> authenticate({
    required String reason,
  }) async {
    final availability = await checkAvailability();
    if (!availability.canAuthenticate) {
      return const BiometricAuthResult(
        status: BiometricAuthStatus.notSupported,
        message:
            'This device does not support secure authentication. '
            'Holdings cannot be displayed.',
      );
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: false,
        ),
      );

      if (didAuthenticate) {
        return const BiometricAuthResult(status: BiometricAuthStatus.success);
      }

      return const BiometricAuthResult(
        status: BiometricAuthStatus.cancelled,
        message: 'Authentication was cancelled. Holdings are hidden.',
      );
    } on PlatformException catch (e) {
      return _mapPlatformException(e);
    } catch (_) {
      return const BiometricAuthResult(
        status: BiometricAuthStatus.error,
        message: 'Authentication failed. Please try again.',
      );
    }
  }

  BiometricAuthResult _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return const BiometricAuthResult(
          status: BiometricAuthStatus.notSupported,
          message:
              'Secure authentication is not available on this device. '
              'Holdings cannot be displayed.',
        );
      case auth_error.notEnrolled:
        return const BiometricAuthResult(
          status: BiometricAuthStatus.notEnrolled,
          message:
              'No biometrics are enrolled. Use your device PIN or passcode, '
              'or enroll biometrics in system settings.',
        );
      case auth_error.lockedOut:
      case auth_error.permanentlyLockedOut:
        return const BiometricAuthResult(
          status: BiometricAuthStatus.lockedOut,
          message:
              'Too many failed attempts. Unlock your device and try again.',
        );
      case auth_error.passcodeNotSet:
        return const BiometricAuthResult(
          status: BiometricAuthStatus.passcodeNotSet,
          message:
              'Set a screen lock (PIN, passcode, or pattern) in your device '
              'settings to view holdings.',
        );
      default:
        final code = e.code.toLowerCase();
        if (code.contains('cancel')) {
          return const BiometricAuthResult(
            status: BiometricAuthStatus.cancelled,
            message: 'Authentication was cancelled. Holdings are hidden.',
          );
        }
        return BiometricAuthResult(
          status: BiometricAuthStatus.error,
          message: e.message ?? 'Authentication failed. Please try again.',
        );
    }
  }

  String _biometricLabel(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong biometrics';
      case BiometricType.weak:
        return 'Biometrics';
    }
  }
}
