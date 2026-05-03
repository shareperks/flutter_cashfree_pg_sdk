import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/cashback_detail_model.dart';
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
