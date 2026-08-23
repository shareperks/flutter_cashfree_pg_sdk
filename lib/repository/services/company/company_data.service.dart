import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/repository/network.dart';

/// Client for the company-data-service (`/api/v1/companies/*`).
///
/// Every success is wrapped in a `data` key and every failure in an `error`
/// key, so unwrapping and error mapping live here once — callers only ever see
/// a typed model or a [CompanyApiException].
class CompanyDataService {
  CompanyDataService._();

  /// The service's own upstream times out at 30s and retries twice; staying
  /// under that keeps a hung FinEdge call from holding a screen open forever.
  static final Dio _dio = createDio(Host.companyDataApi)
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 25);

  /// `M&M` must reach the service as `M%26M` or the `&` starts a new query
  /// parameter.
  static String _symbol(String symbol) =>
      Uri.encodeComponent(symbol.trim().toUpperCase());

  static Future<T> _get<T>(
    String path,
    T Function(dynamic data) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          if (query != null)
            for (final entry in query.entries)
              if (entry.value != null) entry.key: entry.value,
        },
      );
      final body = response.data;
      if (body == null || !body.containsKey('data')) {
        throw const CompanyApiException(
          status: 500,
          message: 'Empty response body',
        );
      }
      return parse(body['data']);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  static CompanyApiException _mapError(DioException e) {
    final data = e.response?.data;
    final status = e.response?.statusCode ?? 0;
    if (data is Map) {
      return CompanyApiException.fromJson(data.cast<String, dynamic>(), status);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => const CompanyApiException(
        status: 504,
        message: 'Company data service did not respond',
      ),
      _ => CompanyApiException(
        status: status == 0 ? 502 : status,
        message: e.message ?? 'Company data service is unreachable',
      ),
    };
  }

  static Map<String, dynamic> _asMap(dynamic data) =>
      data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};

  /// `GET /companies/:symbol` — the whole page in one call. Sections that
  /// failed upstream come back null and are named in `unavailable`.
  static Future<CompanyPage> getPage(
    String symbol, {
    Consolidation consolidation = Consolidation.standalone,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}',
      (data) => CompanyPage.fromJson(_asMap(data)),
      query: {'consolidation': consolidation.value},
    );
  }

  /// `GET /companies/:symbol/overview`
  static Future<CompanyOverview> getOverview(
    String symbol, {
    Consolidation consolidation = Consolidation.standalone,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}/overview',
      (data) => CompanyOverview.fromJson(_asMap(data)),
      query: {'consolidation': consolidation.value},
    );
  }

  /// `GET /companies/:symbol/financials`
  static Future<FinancialTable> getFinancials(
    String symbol, {
    StatementKind statement = StatementKind.pl,
    ReportPeriod period = ReportPeriod.annual,
    Consolidation consolidation = Consolidation.standalone,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}/financials',
      (data) => FinancialTable.fromJson(_asMap(data)),
      query: {
        'statement': statement.value,
        'period': period.value,
        'consolidation': consolidation.value,
      },
    );
  }

  /// `GET /companies/:symbol/quarters` — P&L forced to quarterly.
  static Future<FinancialTable> getQuarters(
    String symbol, {
    Consolidation consolidation = Consolidation.standalone,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}/quarters',
      (data) => FinancialTable.fromJson(_asMap(data)),
      query: {'consolidation': consolidation.value},
    );
  }

  /// `GET /companies/:symbol/ratios` — every row is `unit: pct`.
  static Future<FinancialTable> getRatios(
    String symbol, {
    Consolidation consolidation = Consolidation.standalone,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}/ratios',
      (data) => FinancialTable.fromJson(_asMap(data)),
      query: {'consolidation': consolidation.value},
    );
  }

  /// `GET /companies/:symbol/growth` — compounded growth blocks.
  static Future<CompanyGrowth> getGrowth(
    String symbol, {
    Consolidation consolidation = Consolidation.standalone,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}/growth',
      (data) => CompanyGrowth.fromJson(_asMap(data)),
      query: {'consolidation': consolidation.value},
    );
  }

  /// `GET /companies/:symbol/shareholding` — defaults to quarterly.
  static Future<CompanyShareholding> getShareholding(
    String symbol, {
    ReportPeriod period = ReportPeriod.quarterly,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}/shareholding',
      (data) => CompanyShareholding.fromJson(_asMap(data)),
      query: {'period': period.value},
    );
  }

  /// `GET /companies/:symbol/peers`
  static Future<PeerComparison> getPeers(
    String symbol, {
    ClassificationGroup group = ClassificationGroup.sector,
    int limit = 10,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}/peers',
      (data) => PeerComparison.fromJson(_asMap(data)),
      query: {'group': group.value, 'limit': limit},
    );
  }

  /// `GET /companies/:symbol/chart` — [from] and [to] are *years*, not dates.
  static Future<CompanyChart> getChart(String symbol, {int? from, int? to}) {
    return _get(
      '/companies/${_symbol(symbol)}/chart',
      (data) => CompanyChart.fromJson(_asMap(data)),
      query: {'from': from, 'to': to},
    );
  }

  /// `GET /companies/:symbol/segments` — a bare array, newest period first.
  static Future<List<SegmentPeriod>> getSegments(
    String symbol, {
    Consolidation consolidation = Consolidation.standalone,
    ReportPeriod period = ReportPeriod.annual,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}/segments',
      (data) => data is List
          ? data
                .whereType<Map>()
                .map((e) => SegmentPeriod.fromJson(e.cast<String, dynamic>()))
                .toList()
          : <SegmentPeriod>[],
      query: {'consolidation': consolidation.value, 'period': period.value},
    );
  }

  /// `GET /companies/:symbol/documents`
  static Future<CompanyDocuments> getDocuments(
    String symbol, {
    String? fromDate,
    String? toDate,
  }) {
    return _get(
      '/companies/${_symbol(symbol)}/documents',
      (data) => CompanyDocuments.fromJson(_asMap(data)),
      query: {'from_date': fromDate, 'to_date': toDate},
    );
  }

  /// `GET /companies/:symbol/corporate-actions`
  static Future<CompanyCorporateActions> getCorporateActions(String symbol) {
    return _get(
      '/companies/${_symbol(symbol)}/corporate-actions',
      (data) => CompanyCorporateActions.fromJson(_asMap(data)),
    );
  }

  /// `GET /companies/search` — backed by a 24h symbol master, fast enough for
  /// type-ahead once debounced.
  static Future<List<SearchHit>> search(String query, {int limit = 20}) {
    return _get(
      '/companies/search',
      (data) => data is List
          ? data
                .whereType<Map>()
                .map((e) => SearchHit.fromJson(e.cast<String, dynamic>()))
                .toList()
          : <SearchHit>[],
      query: {
        'q': query.trim().substring(0, query.trim().length.clamp(0, 60)),
        'limit': limit,
      },
    );
  }

  /// `GET /companies/classification` — symbols in a sector/industry.
  static Future<List<String>> classification(
    ClassificationGroup group,
    String value,
  ) {
    return _get(
      '/companies/classification',
      (data) =>
          data is List ? data.map((e) => e.toString()).toList() : <String>[],
      query: {'group': group.value, 'value': value},
    );
  }
}
