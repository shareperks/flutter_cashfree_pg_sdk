import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/giftcard_detail_model.dart';
import 'package:shareperks/repository/network.dart';

class RewardListingDataService {
  static final Dio _dio = createDio(Host.listingUrl);

  /// `GET /rewards/giftcard/:id` — gift card / voucher detail for redemption UI.
  static Future<GiftcardDetailResponse> getGiftcardDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rewards/giftcard/$id',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Giftcard detail: empty response body');
    }
    return GiftcardDetailResponse.fromJson(body);
  }
}
