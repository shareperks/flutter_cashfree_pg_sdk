import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/payout_request_model.dart';
import 'package:shareperks/repository/models/wallet_info_model.dart';
import 'package:shareperks/repository/network.dart';

class WalletDataService {
  static final Dio _dio = createDio(Host.listingUrl);
  static final Dio _payoutDio = createDio(Host.payoutUrl);

  /// `GET /wallet/info` — wallet totals and recent transactions (auth via [createDio]).
  static Future<WalletInfoResponse> getWalletInfo() async {
    final response = await _dio.get<Map<String, dynamic>>('/wallet/info');
    final data = response.data;
    if (data == null) {
      return WalletInfoResponse(wallet: null, transactions: []);
    }
    return WalletInfoResponse.fromJson(data);
  }

  /// `GET /wallet/transitions?tab=…` — filtered wallet history rows.
  ///
  /// [tab]: [WalletTransitionsTab.all], [WalletTransitionsTab.payout], or
  /// [WalletTransitionsTab.earning].
  static Future<List<WalletTransaction>> getTransitions({
    WalletTransitionsTab tab = WalletTransitionsTab.all,
  }) async {
    final response = await _dio.get<dynamic>(
      '/wallet/transitions',
      queryParameters: {'tab': tab.queryValue},
    );
    return WalletTransaction.listFromJsonArray(response.data);
  }

  /// `GET /wallet/cashback-transitions` — cashback credit rows (same shape as [WalletTransaction]).
  static Future<List<WalletTransaction>> getCashbackTransitions() async {
    final response = await _dio.get<dynamic>('/wallet/cashback-transitions');
    return WalletTransaction.listFromJsonArray(response.data);
  }

  /// `GET /wallet/payout-transitions` — payout / withdrawal debit rows.
  static Future<List<WalletTransaction>> getPayoutTransitions() async {
    final response = await _dio.get<dynamic>('/wallet/payout-transitions');
    return WalletTransaction.listFromJsonArray(response.data);
  }

  /// `POST /payout/request` — withdraw to UPI; auth via [createDio] on [Host.payoutUrl].
  static Future<PayoutRequestResponse> requestPayout(
    PayoutRequestPayload payload,
  ) async {
    final response = await _payoutDio.post<Map<String, dynamic>>(
      '/payout/request',
      data: payload.toJson(),
    );
    final data = response.data;
    if (data == null) {
      return PayoutRequestResponse(success: true, raw: const {});
    }
    return PayoutRequestResponse.fromJson(data);
  }
}
