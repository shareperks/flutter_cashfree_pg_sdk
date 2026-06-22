import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/cashback_detail_model.dart';
import 'package:shareperks/repository/models/cashback_tracking_link_model.dart';
import 'package:shareperks/repository/models/claim_promocode_response_model.dart';
import 'package:shareperks/repository/models/giftcard_detail_model.dart';
import 'package:shareperks/repository/models/promocode_detail_model.dart';
import 'package:shareperks/repository/models/my_claimed_giftcard_detail_model.dart';
import 'package:shareperks/repository/models/my_claimed_rewards_model.dart';
import 'package:shareperks/repository/models/reward_content_model.dart';
import 'package:shareperks/repository/models/toggle_redeemed_model.dart';
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

  /// `GET /rewards/cashback/:id` — cashback/benefit perk detail.
  static Future<CashbackDetailResponse> getCashbackDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rewards/cashback/$id',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Cashback detail: empty response body');
    }
    return CashbackDetailResponse.fromJson(body);
  }

  /// `GET /cashback/tracking-link?offerId=<benefitId>` — JWT-protected.
  ///
  /// Resolves the benefit's campaign source on the server (cuelinks /
  /// admitad) and returns a click-attributed affiliate link we open in the
  /// OS browser. Throws [StateError] with the server's `message` on any
  /// business error (`not_found`, `campaign_not_found`, `invalid_provider`,
  /// `no_link`).
  static Future<CashbackTrackingLink> getCashbackTrackingLink(
    String benefitId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/cashback/tracking-link',
        queryParameters: <String, dynamic>{'offerId': benefitId},
      );
      final body = response.data;
      if (body == null) {
        throw StateError('Cashback tracking link: empty response body');
      }
      final ok = body['success'] == true;
      final link = body['link'];
      if (!ok || link is! String || link.isEmpty) {
        throw StateError(
          (body['message'] as String?) ?? 'Could not generate tracking link.',
        );
      }
      return CashbackTrackingLink.fromJson(body);
    } on DioException catch (e) {
      // Server surfaces business errors with `{ message }` in the body.
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw StateError(data['message'] as String);
      }
      rethrow;
    }
  }

  /// `GET /rewards/promocode/:id` — promo code / offer perk detail.
  static Future<PromocodeDetailResponse> getPromocodeDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rewards/promocode/$id',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Promocode detail: empty response body');
    }
    return PromocodeDetailResponse.fromJson(body);
  }

  /// `POST /rewards/promocode/:id/claim` — allocate a code from the offer's
  /// pool to the authenticated user. Idempotent (re-claim returns the same
  /// code with `alreadyClaimed: true`).
  ///
  /// Throws [StateError] with the server's `message` on business errors
  /// (currently surfaced as HTTP 5xx by the data_service global error
  /// middleware).
  static Future<ClaimPromocodeResponse> claimPromocode(String rewardId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/rewards/promocode/$rewardId/claim',
      );
      final body = response.data;
      if (body == null) {
        throw StateError('Claim promocode: empty response body');
      }
      final envelope = ClaimPromocodeEnvelope.fromJson(body);
      if (!envelope.success || envelope.data == null) {
        throw StateError(envelope.message ?? 'Could not claim promo code.');
      }
      return envelope.data!;
    } on DioException catch (e) {
      // Business errors come back as 5xx with `{ message }` in the body.
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw StateError(data['message'] as String);
      }
      rethrow;
    }
  }

  /// `GET /reward/content/:id` — legal / terms (short + full HTML).
  static Future<RewardContent> getRewardContent(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reward/content/$id',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Reward content: empty response body');
    }
    return RewardContent.fromJson(body);
  }

  /// `GET /rewards/my-claimed` — claimed gift cards & promo codes + totals.
  static Future<MyClaimedRewardsResponse> getMyClaimedRewards() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rewards/my-claimed',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('My claimed rewards: empty response body');
    }
    return MyClaimedRewardsResponse.fromJson(body);
  }

  /// `GET /rewards/my-claimed/giftcard/:claimedId` — one claimed gift card (codes, pin, info).
  ///
  /// [claimedId] is [MyClaimedPerk.claimedId] from my-claimed list, not the catalog reward id.
  static Future<MyClaimedGiftcardDetailResponse> getMyClaimedGiftcardDetail(
    String claimedId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rewards/my-claimed/giftcard/$claimedId',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('My claimed giftcard detail: empty response body');
    }
    return MyClaimedGiftcardDetailResponse.fromJson(body);
  }

  /// `PATCH /rewards/my-claimed/giftcard/:claimedId/toggle-redeemed` — flip redeemed state.
  ///
  /// [claimedId] is [MyClaimedPerk.claimedId] from my-claimed list.
  static Future<ToggleRedeemedResponse> toggleGiftcardRedeemed(
    String claimedId,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/rewards/my-claimed/giftcard/$claimedId/toggle-redeemed',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Toggle giftcard redeemed: empty response body');
    }
    return ToggleRedeemedResponse.fromJson(body);
  }

  /// `PATCH /rewards/my-claimed/promocode/:claimedId/toggle-redeemed` — flip redeemed state.
  static Future<ToggleRedeemedResponse> togglePromocodeRedeemed(
    String claimedId,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/rewards/my-claimed/promocode/$claimedId/toggle-redeemed',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Toggle promocode redeemed: empty response body');
    }
    return ToggleRedeemedResponse.fromJson(body);
  }
}
