import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/network.dart';
import 'package:shareperks/repository/services/auth/auth_model.dart';

class MfaService {
  MfaService._();

  static final Dio _dio = createDio(Host.authUrl);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return {'success': false, 'message': 'Unexpected response'};
  }

  /// `POST /api/mfa/setup`
  static Future<MfaSetupResponse> setup() async {
    try {
      final response = await _dio.post('/api/mfa/setup');
      return MfaSetupResponse.fromJson(_asMap(response.data));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        return MfaSetupResponse.fromJson(_asMap(e.response?.data));
      }
      rethrow;
    }
  }

  /// `POST /api/mfa/enable` — body `{ "code": "..." }`
  static Future<MfaEnableResponse> enable(String code) async {
    try {
      final response = await _dio.post(
        '/api/mfa/enable',
        data: {'code': code},
      );
      return MfaEnableResponse.fromJson(_asMap(response.data));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        return MfaEnableResponse.fromJson(_asMap(e.response?.data));
      }
      rethrow;
    }
  }

  /// `POST /api/mfa/disable` — body `{ "code": "..." }`
  static Future<MfaDisableResponse> disable(String code) async {
    try {
      final response = await _dio.post(
        '/api/mfa/disable',
        data: {'code': code},
      );
      return MfaDisableResponse.fromJson(_asMap(response.data));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        return MfaDisableResponse.fromJson(_asMap(e.response?.data));
      }
      rethrow;
    }
  }
}
