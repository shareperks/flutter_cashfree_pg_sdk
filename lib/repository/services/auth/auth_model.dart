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
  VerifyOtpMobileResponse({
    required this.message,
    required this.success,
    this.token,
    this.isProfileComplete,
  });

  factory VerifyOtpMobileResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpMobileResponse(
      message: json['message'],
      success: json['success'],
      token: json['token'],
      isProfileComplete: json['isProfileComplete'],
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
