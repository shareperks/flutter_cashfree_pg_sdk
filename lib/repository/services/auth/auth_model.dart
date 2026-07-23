// {{baseUrl}}/api/login/mobile
import 'package:shareperks/repository/services/auth/user_model.dart';

class LoginMobilePayload {
  final String phone;
  final String? deviceToken;

  LoginMobilePayload({required this.phone, this.deviceToken});

  factory LoginMobilePayload.fromJson(Map<String, dynamic> json) {
    return LoginMobilePayload(
      phone: json['phone'],
      deviceToken: json['deviceToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'deviceToken': deviceToken};
  }
}

class AuthResponse {
  final String message;
  final bool success;

  AuthResponse({required this.message, required this.success});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(message: json['message'], success: json['success']);
  }
}

// {{baseUrl}}/api/login/verify-otp/mobile
class VerifyOtpMobilePayload {
  final String phone;
  final String otp;

  VerifyOtpMobilePayload({required this.phone, required this.otp});

  factory VerifyOtpMobilePayload.fromJson(Map<String, dynamic> json) {
    return VerifyOtpMobilePayload(phone: json['phone'], otp: json['otp']);
  }

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'otp': otp};
  }
}

class VerifyOtpMobileResponse {
  final String message;
  final bool success;
  final String? token;
  final bool? isProfileComplete;
  final bool? mfaRequired;
  final String? mfaToken;

  VerifyOtpMobileResponse({
    required this.message,
    required this.success,
    this.token,
    this.isProfileComplete,
    this.mfaRequired,
    this.mfaToken,
  });

  factory VerifyOtpMobileResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpMobileResponse(
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      token: json['token'] as String?,
      isProfileComplete: json['isProfileComplete'] as bool?,
      mfaRequired: json['mfaRequired'] as bool?,
      mfaToken: json['mfaToken'] as String?,
    );
  }
}

// {{baseUrl}}/api/login/verify-mfa
class VerifyMfaPayload {
  final String mfaToken;
  final String code;

  VerifyMfaPayload({required this.mfaToken, required this.code});

  Map<String, dynamic> toJson() => {'mfaToken': mfaToken, 'code': code};
}

class VerifyMfaResponse {
  final String message;
  final bool success;
  final String? token;
  final bool? isProfileComplete;

  VerifyMfaResponse({
    required this.message,
    required this.success,
    this.token,
    this.isProfileComplete,
  });

  factory VerifyMfaResponse.fromJson(Map<String, dynamic> json) {
    return VerifyMfaResponse(
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      token: json['token'] as String?,
      isProfileComplete: json['isProfileComplete'] as bool?,
    );
  }
}

// {{baseUrl}}/api/mfa/setup
class MfaSetupResponse {
  final bool success;
  final String? message;
  final String? qrCode;
  final String? otpauthUrl;
  final String? secret;
  final bool? mfaEnabled;

  MfaSetupResponse({
    required this.success,
    this.message,
    this.qrCode,
    this.otpauthUrl,
    this.secret,
    this.mfaEnabled,
  });

  factory MfaSetupResponse.fromJson(Map<String, dynamic> json) {
    return MfaSetupResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      qrCode: json['qrCode'] as String?,
      otpauthUrl: json['otpauthUrl'] as String?,
      secret: json['secret'] as String?,
      mfaEnabled: json['mfaEnabled'] as bool?,
    );
  }
}

// {{baseUrl}}/api/mfa/enable
class MfaEnableResponse {
  final bool success;
  final String message;
  final bool? mfaEnabled;
  final List<String> backupCodes;

  MfaEnableResponse({
    required this.success,
    required this.message,
    this.mfaEnabled,
    this.backupCodes = const [],
  });

  factory MfaEnableResponse.fromJson(Map<String, dynamic> json) {
    final rawCodes = json['backupCodes'];
    return MfaEnableResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      mfaEnabled: json['mfaEnabled'] as bool?,
      backupCodes: rawCodes is List
          ? rawCodes.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

// {{baseUrl}}/api/mfa/disable
class MfaDisableResponse {
  final bool success;
  final String message;
  final bool? mfaEnabled;

  MfaDisableResponse({
    required this.success,
    required this.message,
    this.mfaEnabled,
  });

  factory MfaDisableResponse.fromJson(Map<String, dynamic> json) {
    return MfaDisableResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      mfaEnabled: json['mfaEnabled'] as bool?,
    );
  }
}

// {{baseUrl}}/api/complete-profile
class CompleteProfilePayload {
  final String name;
  final String email;
  final String? referralCode;

  CompleteProfilePayload({
    required this.name,
    required this.email,
    this.referralCode,
  });

  factory CompleteProfilePayload.fromJson(Map<String, dynamic> json) {
    return CompleteProfilePayload(
      name: json['name'],
      email: json['email'],
      referralCode: json['referralCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'referralCode': referralCode};
  }
}

// {{baseUrl}}/api/complete-profile
class SessionResponse {
  final String message;
  final bool success;
  final UserModel? user;
  SessionResponse({required this.message, required this.success, this.user});

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      message: json['message'],
      success: json['success'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

// {{baseUrl}}/api/onload
class VersionModel {
  bool? success;
  String? version;
  String? latestVersion;
  bool? isUpdateAvailable;
  bool? isForceUpdate;
  String? title;
  String? message;

  VersionModel({
    this.success,
    this.version,
    this.latestVersion,
    this.isUpdateAvailable,
    this.isForceUpdate,
    this.title,
    this.message,
  });

  VersionModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    version = json['version'];
    latestVersion = json['latestVersion'];
    isUpdateAvailable = json['isUpdateAvailable'];
    isForceUpdate = json['isForceUpdate'];
    title = json['title'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['version'] = version;
    data['latestVersion'] = latestVersion;
    data['isUpdateAvailable'] = isUpdateAvailable;
    data['isForceUpdate'] = isForceUpdate;
    data['title'] = title;
    data['message'] = message;
    return data;
  }
}
