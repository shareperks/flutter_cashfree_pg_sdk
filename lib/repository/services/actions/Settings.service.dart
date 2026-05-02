import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/user_settings_model.dart';
import 'package:shareperks/repository/network.dart';

/// Auth API settings: `GET` / `PUT` [`/api/settings`](https://auth.shareperks.in/api/settings).
class SettingsService {
  SettingsService._();

  static final Dio _dio = createDio(Host.authUrl);

  /// `GET /api/settings`
  static Future<UserSettings> getSettings() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/settings');
    final body = response.data;
    if (body == null) {
      throw StateError('Settings: empty response body');
    }
    return UserSettings.fromJson(body);
  }

  /// `PUT /api/settings` — partial updates supported via [UserSettingsUpdate].
  static Future<UserSettings> updateSettings(UserSettingsUpdate patch) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/settings',
      data: patch.toJson(),
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Settings update: empty response body');
    }
    return UserSettings.fromJson(body);
  }
}
