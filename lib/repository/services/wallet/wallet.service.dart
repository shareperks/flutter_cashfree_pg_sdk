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
