import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/network.dart';
import 'package:shareperks/repository/services/auth/auth_model.dart';

class AuthService {
  static final Dio _dio = createDio(Host.authUrl);

  static Future<bool> isLoggedIn() async {
    final token = TokenManager.getToken();
    if (token == null) {
      return false;
    }
    return true;
  }

  static Future<void> logout() async {
    await TokenManager.removeToken();
  }

  // {{baseUrl}}/api/onload
  static Future<VersionModel> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    try {
      final response = await _dio.get(
        '/api/onload',
        queryParameters: {'versionNumber': version},
      );
      return VersionModel.fromJson(response.data['version']);
    } catch (e) {
      rethrow;
    }
  }

  // api/login/mobile
  static Future<AuthResponse> login(LoginMobilePayload payload) async {
    try {
      final response = await _dio.post(
        '/api/login/mobile',
        data: payload.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          return AuthResponse.fromJson(e.response?.data);
        }
      }
      rethrow;
    }
  }

  // api/login/verify-otp/mobile
  static Future<VerifyOtpMobileResponse> verifyOtp(
    VerifyOtpMobilePayload payload,
  ) async {
    try {
      final response = await _dio.post(
        '/api/login/verify-otp/mobile',
        data: payload.toJson(),
      );
      final verifyOtpResponse = VerifyOtpMobileResponse.fromJson(response.data);
      if (verifyOtpResponse.token == null ||
          verifyOtpResponse.success != true) {
        throw Exception(verifyOtpResponse.message);
      }
      await TokenManager.setToken(verifyOtpResponse.token!);
      return verifyOtpResponse;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          return VerifyOtpMobileResponse.fromJson(e.response?.data);
        }
      }
      rethrow;
    }
  }

  // api/complete-profile
  static Future<SessionResponse> completeProfile(
    CompleteProfilePayload payload,
  ) async {
    try {
      final response = await _dio.post(
        '/api/complete-profile',
        data: payload.toJson(),
      );
      return SessionResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          return SessionResponse.fromJson(e.response?.data);
        }
      }
      rethrow;
    }
  }

  // api/verify-session
  static Future<SessionResponse> verifySession() async {
    try {
      final response = await _dio.get('/api/verify-session');
      return SessionResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          return SessionResponse.fromJson(e.response?.data);
        }
        if (e.response?.statusCode == 401) {
          return SessionResponse.fromJson(e.response?.data);
        }
      }
      rethrow;
    }
  }
}
