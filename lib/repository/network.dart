import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shareperks/constants/logger.dart';
import 'package:shareperks/function/localstorage.dart';

class TokenManager {
  static Future<void> setToken(String token) async {
    await LocalStorage.setToken(token);
  }

  static String? getToken() => LocalStorage.getToken();

  static Future<void> removeToken() async {
    await LocalStorage.clearToken();
  }
}

Dio createDio(String baseUrl) {
  final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final token = TokenManager.getToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              _logRequest(options);
              handler.next(options);
            },
            onResponse: (response, handler) {
              _logResponse(response);
              handler.next(response);
            },
            onError: (error, handler) {
              _logError(error);
              handler.next(error);
            },
          ),
        );
  return dio;
}

void _logRequest(RequestOptions options) {
  if (!kDebugMode) return;
  logger.d(
    '${options.method} ${options.uri}\n'
    'headers: ${options.headers}\n'
    'data: ${options.data}\n'
    'query: ${options.queryParameters}',
  );
}

void _logResponse(Response<dynamic> response) {
  if (!kDebugMode) return;
  logger.d(
    '${response.statusCode} ${response.requestOptions.uri}\n'
    'data: ${response.data}\n'
    'headers: ${response.headers}',
  );
}

void _logError(DioException error) {
  if (!kDebugMode) return;
  logger.e(
    '${error.response?.statusCode} ${error.requestOptions.uri}\n'
    '${error.message}\n'
    '${error.response?.data}',
  );
}
