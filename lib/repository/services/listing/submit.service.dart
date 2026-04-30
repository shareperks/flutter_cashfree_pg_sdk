import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/perk_request_payload.dart';
import 'package:shareperks/repository/network.dart';

class SubmitService {
  static final Dio _dio = createDio(Host.submitApi);

  /// `POST /api/perk-request` — JSON body matches backend contract; auth via [TokenManager] interceptor.
  static Future<void> submitPerkRequest(PerkRequestPayload payload) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/perk-request',
      data: payload.toJson(),
    );
  }
}
