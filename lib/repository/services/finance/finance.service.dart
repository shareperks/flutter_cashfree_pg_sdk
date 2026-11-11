import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/finance_perks_model.dart';
import 'package:shareperks/repository/network.dart';

/// Client for the Finance / Screener API (`Host.financeApi`).
///
/// Endpoints are public (no auth) and live under `/api/...`. Perk images are
/// already resolved to loadable URLs by the service, so callers only need to
/// run them through `imageUrl()` before rendering.
class FinanceService {
  FinanceService._();

  static final Dio _dio = createDio(Host.financeApi)
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 20);

  /// `&` in a symbol (e.g. `M&M`) would start a new query param — encode it.
  static String _ticker(String symbol) =>
      Uri.encodeComponent(symbol.trim().toUpperCase());

  /// `GET /api/company/:ticker/perks` — gift cards, cashbacks, discount codes
  /// for one company.
  static Future<FinancePerksResponse> getCompanyPerks(String ticker) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/company/${_ticker(ticker)}/perks',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Company perks: empty response body');
    }
    return FinancePerksResponse.fromJson(body);
  }

  /// `GET /api/perks` — every visible perk across all companies.
  static Future<FinancePerksResponse> getAllPerks() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/perks');
    final body = response.data;
    if (body == null) {
      throw StateError('Perks: empty response body');
    }
    return FinancePerksResponse.fromJson(body);
  }

  /// `GET /api/company/:ticker/profile` — name, sector, description, ISIN…
  static Future<FinanceProfileResponse> getProfile(String ticker) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/company/${_ticker(ticker)}/profile',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Company profile: empty response body');
    }
    return FinanceProfileResponse.fromJson(body);
  }
}
