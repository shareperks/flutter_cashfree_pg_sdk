import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/referral_list_model.dart';
import 'package:shareperks/repository/network.dart';

/// Listing API: referred users for the signed-in account.
class ReferralListingService {
  ReferralListingService._();

  static final Dio _dio = createDio(Host.listingUrl);

  /// `GET /referral/all` — returns a JSON array of [ReferralListEntry].
  static Future<List<ReferralListEntry>> getAllReferrals() async {
    final response = await _dio.get<dynamic>('/referral/all');
    final body = response.data;
    if (body == null) {
      return <ReferralListEntry>[];
    }
    if (body is! List) {
      throw StateError(
        'Referral list: expected JSON array, got ${body.runtimeType}',
      );
    }
    return ReferralListEntry.listFromJson(body);
  }
}
