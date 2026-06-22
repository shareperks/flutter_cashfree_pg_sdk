import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/profile_model.dart';
import 'package:shareperks/repository/network.dart';

/// Profile API on the data_service:
/// - `GET  /profile`   — fetch the logged-in user's profile
/// - `PATCH /profile`  — partial update (name / email / mobile / dob / image)
///
/// Both routes require the JWT (attached automatically by the Dio interceptor
/// in [createDio]).
class ProfileService {
  ProfileService._();

  static final Dio _dio = createDio(Host.listingUrl);

  /// `GET /profile` — returns the logged-in user's profile.
  static Future<Profile> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/profile');
    final body = response.data;
    if (body == null) {
      throw StateError('Profile fetch: empty response body');
    }
    final envelope = ProfileEnvelope.fromJson(body);
    if (!envelope.success || envelope.data == null) {
      throw StateError(envelope.message ?? 'Profile fetch failed');
    }
    return envelope.data!;
  }

  /// `PATCH /profile` — partial update. At least one field must be set.
  /// Throws if [patch] is empty (server would reject it anyway).
  static Future<Profile> updateProfile(ProfileUpdate patch) async {
    if (patch.isEmpty) {
      throw ArgumentError(
        'ProfileUpdate must include at least one field to change.',
      );
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '/profile',
      data: patch.toJson(),
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Profile update: empty response body');
    }
    final envelope = ProfileEnvelope.fromJson(body);
    if (!envelope.success || envelope.data == null) {
      throw StateError(envelope.message ?? 'Profile update failed');
    }
    return envelope.data!;
  }
}
