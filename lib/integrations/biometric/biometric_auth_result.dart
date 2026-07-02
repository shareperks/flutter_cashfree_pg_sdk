/// Outcome of a local biometric / device-credential authentication attempt.
enum BiometricAuthStatus {
  success,
  cancelled,
  failed,
  notSupported,
  notEnrolled,
  lockedOut,
  passcodeNotSet,
  error,
}

class BiometricAuthResult {
  const BiometricAuthResult({required this.status, this.message});

  final BiometricAuthStatus status;
  final String? message;

  bool get isSuccess => status == BiometricAuthStatus.success;
}

class BiometricAvailability {
  const BiometricAvailability({
    required this.isDeviceSupported,
    required this.canCheckBiometrics,
    required this.availableBiometrics,
    required this.canAuthenticate,
  });

  final bool isDeviceSupported;
  final bool canCheckBiometrics;
  final List<String> availableBiometrics;
  final bool canAuthenticate;

  bool get hasEnrolledBiometrics => availableBiometrics.isNotEmpty;
}
