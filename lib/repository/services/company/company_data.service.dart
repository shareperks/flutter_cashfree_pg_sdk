import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';
import 'package:shareperks/repository/network.dart';
import 'package:shareperks/repository/services/company/finance_api_mapper.dart';

/// Client for the Finance / Screener API (`Host.financeApi`).
///
/// Every endpoint is under `/api/company/:ticker`. The aggregate
/// `/api/company/:ticker` returns profile, quote, raw financials, ratios,
/// shareholding, peers (symbol list), historical prices, dividends, splits,
/// bonuses, rights, and announcements in one call. Structured statement
/// endpoints (`/profit-loss`, `/quarterly`, `/balance-sheet`, `/cash-flow`)
/// return `lineItems` + `annualFinancials[].display` + `ui.rows` which are
/// pivoted into [FinancialTable] by [FinanceApiMapper].
///
/// All responses are mapped into the existing model classes
/// ([CompanyPage], [FinancialTable], …) so the UI layer is unchanged.
class CompanyDataService {
  CompanyDataService._();

  static final Dio _dio = createDio(Host.financeApi)
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 25);

  /// `&` in a symbol (e.g. `M&M`) would start a new query param — encode it.
  static String _symbol(String symbol) =>
      Uri.encodeComponent(symbol.trim().toUpperCase());

  /// Maps [Consolidation] to the finance API's `statement_type` param.
  static String _statementType(Consolidation c) =>
      c == Consolidation.standalone ? 's' : 'c';

  static Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _dio.get<dynamic>(path);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const CompanyApiException(
      status: 500,
      message: 'Empty response body',
    );
  }

  static Future<T> _get<T>(
    String path,
    T Function(Map<String, dynamic> data) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: {
          if (query != null)
            for (final entry in query.entries)
              if (entry.value != null) entry.key: entry.value,
        },
      );
      final body = response.data;
      if (body is! Map) {
        throw const CompanyApiException(
          status: 500,
          message: 'Empty response body',
        );
      }
      return parse(body.cast<String, dynamic>());
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  static CompanyApiException _mapError(DioException e) {
    final data = e.response?.data;
    final status = e.response?.statusCode ?? 0;
    if (data is Map) {
      final error = data['error'];
      if (error is String) {
        return CompanyApiException(status: status, message: error);
      }
      if (error is Map) {
        return CompanyApiException.fromJson(
          error.cast<String, dynamic>(),
          status,
        );
      }
      // The finance API returns `{ "error": "message" }` on failure.
      if (data['error'] is String) {
        return CompanyApiException(
          status: status,
          message: data['error'] as String,
        );
      }
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

  // ─── page ─────────────────────────────────────────────────────────────────

  /// Wraps a future so it returns `null` on any error — used for parallel
  /// section fetches where a single failure should not blank the whole page.
  static Future<T?> _optional<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  /// `GET /api/company/:ticker` (aggregate) + structured statement endpoints
  /// + `/peers` — assembled into a single [CompanyPage].
  ///
  /// The aggregate gives profile, quote, ratios, shareholding, documents and
  /// corporate actions. The structured endpoints give pivoted financial
  /// tables. All calls run in parallel.
  static Future<CompanyPage> getPage(
    String symbol, {
    Consolidation consolidation = Consolidation.consolidated,
  }) async {
    final st = _statementType(consolidation);
    final sym = _symbol(symbol);

    // Fire all requests in parallel — each degrades independently.
    final aggregateFuture = _optional(
      _getJson('/api/company/$sym?statement_type=$st'),
    );
    final plFuture = _optional(
      _get(
        '/api/company/$sym/profit-loss',
        (j) => mapStructuredStatement(
          j,
          statement: StatementKind.pl,
          period: ReportPeriod.annual,
        ),
        query: {'statement_type': st},
      ),
    );
    final quarterlyFuture = _optional(
      _get(
        '/api/company/$sym/quarterly',
        (j) => mapStructuredStatement(
          j,
          statement: StatementKind.pl,
          period: ReportPeriod.quarterly,
        ),
        query: {'statement_type': st},
      ),
    );
    final bsFuture = _optional(
      _get(
        '/api/company/$sym/balance-sheet',
        (j) => mapStructuredStatement(
          j,
          statement: StatementKind.bs,
          period: ReportPeriod.annual,
        ),
        query: {'statement_type': st},
      ),
    );
    final cfFuture = _optional(
      _get(
        '/api/company/$sym/cash-flow',
        (j) => mapCashFlow(j),
        query: {'statement_type': st},
      ),
    );
    final peersFuture = _optional(
      _get('/api/company/$sym/peers', (j) => mapPeers(j, symbol)),
    );

    final aggregate = await aggregateFuture;
    if (aggregate == null) {
      throw const CompanyApiException(
        status: 502,
        message: 'Company data service is unreachable',
      );
    }

    return mapCompanyPage(
      aggregate: aggregate,
      profitAndLoss: await plFuture,
      quarterlyResults: await quarterlyFuture,
      balanceSheet: await bsFuture,
      cashFlow: await cfFuture,
      peers: await peersFuture,
    );
  }

  // ─── overview ─────────────────────────────────────────────────────────────

  /// `GET /api/company/:ticker` — just the overview (profile + quote + basic).
  static Future<CompanyOverview> getOverview(
    String symbol, {
    Consolidation consolidation = Consolidation.consolidated,
  }) async {
    final st = _statementType(consolidation);
    final json = await _getJson(
      '/api/company/${_symbol(symbol)}?statement_type=$st',
    );
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};
    return mapOverview(
      data['profile'] is Map
          ? Map<String, dynamic>.from(data['profile'] as Map)
          : const {},
      data['quote'] is Map
          ? Map<String, dynamic>.from(data['quote'] as Map)
          : const {},
      data['basic'] is Map
          ? Map<String, dynamic>.from(data['basic'] as Map)
          : const {},
      symbol,
    );
  }

  // ─── financials ───────────────────────────────────────────────────────────

  /// `GET /api/company/:ticker/profit-loss|balance-sheet|cash-flow` —
  /// structured statement mapped to [FinancialTable].
  static Future<FinancialTable> getFinancials(
    String symbol, {
    StatementKind statement = StatementKind.pl,
    ReportPeriod period = ReportPeriod.annual,
    Consolidation consolidation = Consolidation.consolidated,
  }) async {
    final st = _statementType(consolidation);
    final endpoint = switch (statement) {
      StatementKind.pl => 'profit-loss',
      StatementKind.bs => 'balance-sheet',
      StatementKind.cf => 'cash-flow',
    };
    final sym = _symbol(symbol);

    if (statement == StatementKind.cf) {
      return _get(
        '/api/company/$sym/cash-flow',
        (j) => mapCashFlow(j),
        query: {'statement_type': st},
      );
    }
    return _get(
      '/api/company/$sym/$endpoint',
      (j) => mapStructuredStatement(j, statement: statement, period: period),
      query: {'statement_type': st},
    );
  }

  /// `GET /api/company/:ticker/quarterly` — quarterly P&L.
  static Future<FinancialTable> getQuarters(
    String symbol, {
    Consolidation consolidation = Consolidation.consolidated,
  }) async {
    final st = _statementType(consolidation);
    return _get(
      '/api/company/${_symbol(symbol)}/quarterly',
      (j) => mapStructuredStatement(
        j,
        statement: StatementKind.pl,
        period: ReportPeriod.quarterly,
      ),
      query: {'statement_type': st},
    );
  }

  /// `GET /api/company/:ticker` — ratios from the aggregate.
  static Future<FinancialTable> getRatios(
    String symbol, {
    Consolidation consolidation = Consolidation.consolidated,
  }) async {
    final st = _statementType(consolidation);
    final json = await _getJson(
      '/api/company/${_symbol(symbol)}?statement_type=$st',
    );
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};
    if (data['ratios'] is! Map) {
      return const FinancialTable(
        statement: StatementKind.pl,
        period: ReportPeriod.annual,
        consolidation: Consolidation.consolidated,
        columns: [],
        rows: [],
      );
    }
    return mapRatios(Map<String, dynamic>.from(data['ratios'] as Map));
  }

  // ─── growth ───────────────────────────────────────────────────────────────

  /// Growth is not directly available from the finance API. Returns `null`
  /// via a [CompanyApiException] so the screen shows the unavailable state.
  static Future<CompanyGrowth> getGrowth(
    String symbol, {
    Consolidation consolidation = Consolidation.consolidated,
  }) async {
    throw const CompanyApiException(
      status: 404,
      message: 'Growth data is not available from this data source.',
    );
  }

  // ─── shareholding ─────────────────────────────────────────────────────────

  /// `GET /api/company/:ticker` — shareholding from the aggregate.
  static Future<CompanyShareholding> getShareholding(
    String symbol, {
    ReportPeriod period = ReportPeriod.quarterly,
  }) async {
    final json = await _getJson('/api/company/${_symbol(symbol)}');
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};
    if (data['shareholding'] is! Map) {
      throw const CompanyApiException(
        status: 404,
        message: 'Shareholding data not available',
      );
    }
    return mapShareholding(
      Map<String, dynamic>.from(data['shareholding'] as Map),
    );
  }

  // ─── peers ────────────────────────────────────────────────────────────────

  /// `GET /api/company/:ticker/peers`.
  static Future<PeerComparison> getPeers(
    String symbol, {
    ClassificationGroup group = ClassificationGroup.sector,
    int limit = 10,
  }) async {
    return _get(
      '/api/company/${_symbol(symbol)}/peers',
      (j) => mapPeers(j, symbol),
    );
  }

  // ─── chart ────────────────────────────────────────────────────────────────

  /// `GET /api/company/:ticker` — `historical-price` filtered by year range.
  /// [from] and [to] are years, not dates.
  static Future<CompanyChart> getChart(String symbol, {int? from, int? to}) {
    return _get('/api/company/${_symbol(symbol)}', (j) {
      final data = j['data'] is Map
          ? Map<String, dynamic>.from(j['data'] as Map)
          : const <String, dynamic>{};
      final chart = mapChart(
        data['historical-price'] is Map
            ? Map<String, dynamic>.from(data['historical-price'] as Map)
            : const {},
        symbol,
      );
      if (from == null && to == null) return chart;
      final filtered = chart.points.where((p) {
        final year = int.tryParse(p.date.substring(0, 4));
        if (year == null) return true;
        if (from != null && year < from) return false;
        if (to != null && year > to) return false;
        return true;
      }).toList();
      return CompanyChart(
        symbol: chart.symbol,
        from: filtered.isNotEmpty ? filtered.first.date : null,
        to: filtered.isNotEmpty ? filtered.last.date : null,
        points: filtered,
      );
    });
  }

  // ─── segments ─────────────────────────────────────────────────────────────

  /// `GET /api/company/:ticker` — revenue segments from the aggregate.
  static Future<List<SegmentPeriod>> getSegments(
    String symbol, {
    Consolidation consolidation = Consolidation.consolidated,
    ReportPeriod period = ReportPeriod.annual,
  }) async {
    final st = _statementType(consolidation);
    final json = await _getJson(
      '/api/company/${_symbol(symbol)}?statement_type=$st',
    );
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};
    final segData = data['revenue-segment'];
    if (segData is! Map) return const <SegmentPeriod>[];

    final segRevenues = segData['segment_revenues'];
    if (segRevenues is! List) return const <SegmentPeriod>[];

    return segRevenues.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      final segments = <SegmentEntry>[];
      for (final key in m.keys) {
        if (key == 'header' || key == 'year' || key == 'symbol') continue;
        final v = m[key];
        if (v is Map) {
          segments.add(
            SegmentEntry(
              name: key,
              revenueCr: asDouble(v['revenue']),
              profitCr: asDouble(v['profit']),
            ),
          );
        } else if (v is num) {
          segments.add(SegmentEntry(name: key, revenueCr: asDouble(v)));
        }
      }
      return SegmentPeriod(
        period: m['header'] as String? ?? m['year']?.toString() ?? '',
        segments: segments,
      );
    }).toList();
  }

  // ─── documents ────────────────────────────────────────────────────────────

  /// `GET /api/company/:ticker` — announcements, transcripts, presentations,
  /// credit ratings from the aggregate.
  static Future<CompanyDocuments> getDocuments(
    String symbol, {
    String? fromDate,
    String? toDate,
  }) async {
    final json = await _getJson('/api/company/${_symbol(symbol)}');
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};
    return mapDocuments(data);
  }

  // ─── corporate actions ────────────────────────────────────────────────────

  /// `GET /api/company/:ticker` — dividends, splits, bonuses, rights.
  static Future<CompanyCorporateActions> getCorporateActions(
    String symbol,
  ) async {
    final json = await _getJson('/api/company/${_symbol(symbol)}');
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};
    return mapCorporateActions(data);
  }

  // ─── search ───────────────────────────────────────────────────────────────

  /// The finance API has no dedicated search endpoint. We attempt a direct
  /// ticker lookup via `/api/company/:ticker/profile` — if it succeeds, the
  /// query is an exact (or near-exact) NSE symbol and we return a single hit.
  /// Fuzzy search is not supported.
  static Future<List<SearchHit>> search(String query, {int limit = 20}) async {
    final sym = query.trim().toUpperCase();
    if (sym.isEmpty) return const <SearchHit>[];
    try {
      final json = await _getJson('/api/company/${_symbol(sym)}/profile');
      final profile = json['profile'] is Map
          ? Map<String, dynamic>.from(json['profile'] as Map)
          : const <String, dynamic>{};
      if (profile.isEmpty) return const <SearchHit>[];
      return [
        SearchHit(
          symbol: profile['symbol'] as String? ?? sym,
          name: profile['name'] as String? ?? sym,
          nseCode: profile['nse_code'] as String?,
          bseCode: profile['bse_code'] as String?,
        ),
      ];
    } catch (_) {
      return const <SearchHit>[];
    }
  }

  // ─── classification ───────────────────────────────────────────────────────

  /// The finance API does not expose a classification listing endpoint.
  /// Returns an empty list so the sector screen degrades gracefully.
  static Future<List<String>> classification(
    ClassificationGroup group,
    String value,
  ) async {
    return const <String>[];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Screener models — native nested structure, no flattening.
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetches the full company page using native screener models.
  ///
  /// Returns a [ScreenerCompanyData] (aggregate) plus structured statements
  /// ([ScreenerStatement] for P&L, quarterly, balance sheet; [ScreenerCashFlow]
  /// for cash flow) and [ScreenerPeers].
  static Future<ScreenerCompanyPage> getScreenerPage(
    String symbol, {
    Consolidation consolidation = Consolidation.consolidated,
  }) async {
    final st = _statementType(consolidation);
    final sym = _symbol(symbol);

    // Fire all requests in parallel — each degrades independently.
    final aggregateFuture = _optional(
      _getJson('/api/company/$sym?statement_type=$st'),
    );
    final plFuture = _optional(
      _get(
        '/api/company/$sym/profit-loss',
        (j) => ScreenerStatement.fromJson(j, isQuarterly: false),
        query: {'statement_type': st},
      ),
    );
    final quarterlyFuture = _optional(
      _get(
        '/api/company/$sym/quarterly',
        (j) => ScreenerStatement.fromJson(j, isQuarterly: true),
        query: {'statement_type': st},
      ),
    );
    final bsFuture = _optional(
      _get(
        '/api/company/$sym/balance-sheet',
        (j) => ScreenerStatement.fromJson(j, isQuarterly: false),
        query: {'statement_type': st},
      ),
    );
    final cfFuture = _optional(
      _get(
        '/api/company/$sym/cash-flow',
        (j) => ScreenerCashFlow.fromJson(j),
        query: {'statement_type': st},
      ),
    );
    final peersFuture = _optional(
      _get('/api/company/$sym/peers', (j) => ScreenerPeers.fromJson(j, symbol)),
    );
    final isinFuture = _optional(
      _get('/api/company/$sym/isin', (j) => ScreenerIsin.fromJson(j)),
    );

    final aggregate = await aggregateFuture;
    if (aggregate == null) {
      throw const CompanyApiException(
        status: 502,
        message: 'Company data service is unreachable',
      );
    }

    final peers =
        await peersFuture ?? ScreenerPeers(ticker: symbol, peers: const []);
    final companyData = ScreenerCompanyData.fromAggregate(
      aggregate,
      peers: peers,
    );
    final isin = await isinFuture;

    return ScreenerCompanyPage(
      data: companyData,
      profitAndLoss: await plFuture,
      quarterly: await quarterlyFuture,
      balanceSheet: await bsFuture,
      cashFlow: await cfFuture,
      isin: isin,
    );
  }
}

/// Full company page using native screener models.
class ScreenerCompanyPage {
  const ScreenerCompanyPage({
    required this.data,
    this.profitAndLoss,
    this.quarterly,
    this.balanceSheet,
    this.cashFlow,
    this.isin,
  });

  final ScreenerCompanyData data;
  final ScreenerStatement? profitAndLoss;
  final ScreenerStatement? quarterly;
  final ScreenerStatement? balanceSheet;
  final ScreenerCashFlow? cashFlow;
  final ScreenerIsin? isin;
}
