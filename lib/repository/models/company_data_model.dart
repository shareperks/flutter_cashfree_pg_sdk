/// Models for the company-data-service (`/api/v1/companies/*`).
///
/// Every numeric field is nullable: `null` means "upstream has no value for
/// this period", never zero. Money is already in ₹ crore and ratios are already
/// percentages — the service normalises both, so never convert again here.
library;

double? asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

List<String> asStringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).toList();
}

/// `standalone` (default) or `consolidated`. Pass the same value to every
/// section of a page or the tables disagree with each other.
enum Consolidation {
  standalone,
  consolidated;

  String get value => name;
}

/// `annual` (default everywhere except shareholding) or `quarterly`.
enum ReportPeriod {
  annual,
  quarterly;

  String get value => name;
}

enum StatementKind {
  pl,
  bs,
  cf;

  String get value => name;

  String get label => switch (this) {
    StatementKind.pl => 'Profit & Loss',
    StatementKind.bs => 'Balance Sheet',
    StatementKind.cf => 'Cash Flow',
  };
}

enum ClassificationGroup {
  sector,
  industry,
  subIndustry,
  macroSector;

  String get value => switch (this) {
    ClassificationGroup.sector => 'sector',
    ClassificationGroup.industry => 'industry',
    ClassificationGroup.subIndustry => 'sub_industry',
    ClassificationGroup.macroSector => 'macro_sector',
  };
}

/// The service's error envelope: `{ "error": { status, message, details } }`.
class CompanyApiException implements Exception {
  const CompanyApiException({
    required this.status,
    required this.message,
    this.details,
  });

  final int status;
  final String message;

  /// Zod issue tree / upstream detail. Log it, never render it.
  final dynamic details;

  bool get isNotFound => status == 404;
  bool get isRateLimited => status == 429;

  /// `401`/`403` mean the service's FinEdge key is missing or rejected — every
  /// company page is broken, not just this one.
  bool get isUpstreamAuthFailure => status == 401 || status == 403;

  /// `502`/`504` are upstream hiccups and worth a retry.
  bool get isRetryable => status == 502 || status == 504 || status == 429;

  /// Message safe to show a user; the raw one can be quite technical.
  String get displayMessage => switch (status) {
    404 => 'We could not find this company.',
    401 || 403 => 'Company data is temporarily unavailable.',
    429 => 'Too many requests right now. Please try again in a minute.',
    502 || 504 => 'Company data is taking too long to load.',
    _ => message.isEmpty ? 'Something went wrong' : message,
  };

  factory CompanyApiException.fromJson(
    Map<String, dynamic> json,
    int fallbackStatus,
  ) {
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      return CompanyApiException(
        status: asInt(error['status']) ?? fallbackStatus,
        message: asString(error['message']) ?? 'Request failed',
        details: error['details'],
      );
    }
    return CompanyApiException(
      status: fallbackStatus,
      message: 'Request failed',
    );
  }

  @override
  String toString() => 'CompanyApiException($status): $message';
}

class CompanyIdentity {
  const CompanyIdentity({
    required this.symbol,
    required this.name,
    this.nseCode,
    this.bseCode,
    this.sector,
    this.industry,
    this.subIndustry,
    this.macroSector,
    this.website,
    this.about,
  });

  final String symbol;
  final String name;
  final String? nseCode;
  final String? bseCode;
  final String? sector;
  final String? industry;
  final String? subIndustry;
  final String? macroSector;
  final String? website;
  final String? about;

  factory CompanyIdentity.fromJson(Map<String, dynamic> json) {
    return CompanyIdentity(
      symbol: asString(json['symbol']) ?? '',
      name: asString(json['name']) ?? asString(json['symbol']) ?? '',
      nseCode: asString(json['nseCode']),
      bseCode: asString(json['bseCode']),
      sector: asString(json['sector']),
      industry: asString(json['industry']),
      subIndustry: asString(json['subIndustry']),
      macroSector: asString(json['macroSector']),
      website: asString(json['website']),
      about: asString(json['about']),
    );
  }
}

class CompanyKeyMetrics {
  const CompanyKeyMetrics({
    this.currentPrice,
    this.changePct,
    this.marketCapCr,
    this.high52,
    this.low52,
    this.stockPe,
    this.priceToBook,
    this.bookValue,
    this.faceValue,
    this.dividendYieldPct,
    this.roePct,
    this.rocePct,
    this.opmPct,
    this.pledgedPct,
    this.promoterHoldingPct,
    this.sharesOutstanding,
    this.lastTradedAt,
  });

  final double? currentPrice;
  final double? changePct;
  final double? marketCapCr;
  final double? high52;
  final double? low52;
  final double? stockPe;
  final double? priceToBook;
  final double? bookValue;
  final double? faceValue;
  final double? dividendYieldPct;
  final double? roePct;
  final double? rocePct;
  final double? opmPct;

  /// Share of the promoter holding that is pledged.
  final double? pledgedPct;
  final double? promoterHoldingPct;
  final double? sharesOutstanding;

  /// ISO date, e.g. `2026-08-21`.
  final String? lastTradedAt;

  factory CompanyKeyMetrics.fromJson(Map<String, dynamic> json) {
    return CompanyKeyMetrics(
      currentPrice: asDouble(json['currentPrice']),
      changePct: asDouble(json['changePct']),
      marketCapCr: asDouble(json['marketCapCr']),
      high52: asDouble(json['high52']),
      low52: asDouble(json['low52']),
      stockPe: asDouble(json['stockPe']),
      priceToBook: asDouble(json['priceToBook']),
      bookValue: asDouble(json['bookValue']),
      faceValue: asDouble(json['faceValue']),
      dividendYieldPct: asDouble(json['dividendYieldPct']),
      roePct: asDouble(json['roePct']),
      rocePct: asDouble(json['rocePct']),
      opmPct: asDouble(json['opmPct']),
      pledgedPct: asDouble(json['pledgedPct']),
      promoterHoldingPct: asDouble(json['promoterHoldingPct']),
      sharesOutstanding: asDouble(json['sharesOutstanding']),
      lastTradedAt: asString(json['lastTradedAt']),
    );
  }
}

class CompanyOverview {
  const CompanyOverview({
    required this.identity,
    required this.metrics,
    required this.pros,
    required this.cons,
  });

  final CompanyIdentity identity;
  final CompanyKeyMetrics metrics;

  /// Rule-based and often empty — do not treat an empty list as a failure.
  final List<String> pros;
  final List<String> cons;

  factory CompanyOverview.fromJson(Map<String, dynamic> json) {
    return CompanyOverview(
      identity: CompanyIdentity.fromJson(
        (json['identity'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      metrics: CompanyKeyMetrics.fromJson(
        (json['metrics'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      pros: asStringList(json['pros']),
      cons: asStringList(json['cons']),
    );
  }
}

/// `cr` — ₹ crore, `pct` — already multiplied by 100, `ratio`, `count`.
enum FinancialUnit {
  cr,
  pct,
  ratio,
  count;

  static FinancialUnit parse(dynamic value) => switch (value?.toString()) {
    'pct' => FinancialUnit.pct,
    'ratio' => FinancialUnit.ratio,
    'count' => FinancialUnit.count,
    _ => FinancialUnit.cr,
  };
}

class FinancialRow {
  const FinancialRow({
    required this.key,
    required this.label,
    required this.values,
    required this.unit,
  });

  /// Stable upstream key — safe to use as a widget key.
  final String key;
  final String label;

  /// Aligned with [FinancialTable.columns] by index; `null` where the period
  /// has no figure.
  final List<double?> values;
  final FinancialUnit unit;

  factory FinancialRow.fromJson(Map<String, dynamic> json) {
    final raw = json['values'];
    return FinancialRow(
      key: asString(json['key']) ?? asString(json['label']) ?? '',
      label: asString(json['label']) ?? '',
      values: raw is List ? raw.map(asDouble).toList() : const <double?>[],
      unit: FinancialUnit.parse(json['unit']),
    );
  }
}

class FinancialTable {
  const FinancialTable({
    required this.statement,
    required this.period,
    required this.consolidation,
    required this.columns,
    required this.rows,
  });

  final StatementKind statement;
  final ReportPeriod period;
  final Consolidation consolidation;

  /// `["2018", …]` or `["Mar 2025", "TTM", …]`. Quarterly labels repeat, so key
  /// cells by index, never by label.
  final List<String> columns;
  final List<FinancialRow> rows;

  bool get isEmpty => rows.isEmpty || columns.isEmpty;

  bool get hasCroreRows => rows.any((r) => r.unit == FinancialUnit.cr);

  /// True when every row is a percentage — the ratios table. Such a table
  /// declares its unit once rather than on each row.
  bool get isAllPercent =>
      rows.isNotEmpty && rows.every((r) => r.unit == FinancialUnit.pct);

  factory FinancialTable.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'];
    return FinancialTable(
      statement: switch (asString(json['statement'])) {
        'bs' => StatementKind.bs,
        'cf' => StatementKind.cf,
        _ => StatementKind.pl,
      },
      period: asString(json['period']) == 'quarterly'
          ? ReportPeriod.quarterly
          : ReportPeriod.annual,
      consolidation: asString(json['consolidation']) == 'consolidated'
          ? Consolidation.consolidated
          : Consolidation.standalone,
      columns: asStringList(json['columns']),
      rows: rows is List
          ? rows
                .whereType<Map>()
                .map((e) => FinancialRow.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const <FinancialRow>[],
    );
  }
}

/// `{ "10 Years": 12.4, "1 Year": … }` — a window is `null` when history is too
/// short or the signs make a CAGR meaningless.
typedef GrowthBlock = Map<String, double?>;

GrowthBlock _growthBlock(dynamic value) {
  if (value is! Map) return <String, double?>{};
  return value.map((key, v) => MapEntry(key.toString(), asDouble(v)));
}

class CompanyGrowth {
  const CompanyGrowth({
    required this.sales,
    required this.profit,
    required this.stockPrice,
    required this.returnOnEquity,
  });

  final GrowthBlock sales;
  final GrowthBlock profit;
  final GrowthBlock stockPrice;

  /// The average ROE over each window, not a CAGR.
  final GrowthBlock returnOnEquity;

  factory CompanyGrowth.fromJson(Map<String, dynamic> json) {
    return CompanyGrowth(
      sales: _growthBlock(json['sales']),
      profit: _growthBlock(json['profit']),
      stockPrice: _growthBlock(json['stockPrice']),
      returnOnEquity: _growthBlock(json['returnOnEquity']),
    );
  }
}

class ShareholdingCategory {
  const ShareholdingCategory({
    required this.name,
    this.category,
    required this.values,
    required this.holders,
  });

  final String name;
  final String? category;

  /// Keyed by column label, *not* positional like [FinancialRow.values].
  final Map<String, double?> values;
  final List<ShareholdingCategory> holders;

  factory ShareholdingCategory.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    final rawHolders = json['holders'];
    return ShareholdingCategory(
      name: asString(json['name']) ?? '',
      category: asString(json['category']),
      values: rawValues is Map
          ? rawValues.map((k, v) => MapEntry(k.toString(), asDouble(v)))
          : <String, double?>{},
      holders: rawHolders is List
          ? rawHolders
                .whereType<Map>()
                .map(
                  (e) =>
                      ShareholdingCategory.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
          : const <ShareholdingCategory>[],
    );
  }
}

class PledgeSummary {
  const PledgeSummary({
    required this.period,
    this.pledgedShares,
    this.pledgedPct,
    this.promoterShareholding,
    this.lockedInShares,
    this.lockedInPct,
    this.totalShares,
    this.totalShareholders,
  });

  /// A label such as `Mar 2018`, not a date.
  final String period;
  final double? pledgedShares;
  final double? pledgedPct;
  final double? promoterShareholding;
  final double? lockedInShares;
  final double? lockedInPct;
  final double? totalShares;
  final double? totalShareholders;

  factory PledgeSummary.fromJson(Map<String, dynamic> json) {
    return PledgeSummary(
      period: asString(json['period']) ?? '',
      pledgedShares: asDouble(json['pledgedShares']),
      pledgedPct: asDouble(json['pledgedPct']),
      promoterShareholding: asDouble(json['promoterShareholding']),
      lockedInShares: asDouble(json['lockedInShares']),
      lockedInPct: asDouble(json['lockedInPct']),
      totalShares: asDouble(json['totalShares']),
      totalShareholders: asDouble(json['totalShareholders']),
    );
  }
}

class CompanyShareholding {
  const CompanyShareholding({
    required this.period,
    required this.columns,
    required this.categories,
    required this.pledge,
  });

  final ReportPeriod period;
  final List<String> columns;
  final List<ShareholdingCategory> categories;

  /// Arrives in upstream order, which is *not* chronological.
  final List<PledgeSummary> pledge;

  factory CompanyShareholding.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'];
    final pledge = json['pledge'];
    return CompanyShareholding(
      period: asString(json['period']) == 'annual'
          ? ReportPeriod.annual
          : ReportPeriod.quarterly,
      columns: asStringList(json['columns']),
      categories: categories is List
          ? categories
                .whereType<Map>()
                .map(
                  (e) =>
                      ShareholdingCategory.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
          : const <ShareholdingCategory>[],
      pledge: pledge is List
          ? pledge
                .whereType<Map>()
                .map((e) => PledgeSummary.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const <PledgeSummary>[],
    );
  }
}

class PeerRow {
  const PeerRow({
    required this.symbol,
    this.name,
    this.currentPrice,
    this.changePct,
    this.marketCapCr,
    this.pe,
    this.priceToBook,
    this.roePct,
    this.opmPct,
  });

  final String symbol;
  final String? name;
  final double? currentPrice;
  final double? changePct;
  final double? marketCapCr;
  final double? pe;
  final double? priceToBook;
  final double? roePct;
  final double? opmPct;

  factory PeerRow.fromJson(Map<String, dynamic> json) {
    return PeerRow(
      symbol: asString(json['symbol']) ?? '',
      name: asString(json['name']),
      currentPrice: asDouble(json['currentPrice']),
      changePct: asDouble(json['changePct']),
      marketCapCr: asDouble(json['marketCapCr']),
      pe: asDouble(json['pe']),
      priceToBook: asDouble(json['priceToBook']),
      roePct: asDouble(json['roePct']),
      opmPct: asDouble(json['opmPct']),
    );
  }
}

class PeerComparison {
  const PeerComparison({required this.group, this.self, required this.peers});

  final String group;

  /// The requested company; render it as the first, highlighted row.
  final PeerRow? self;
  final List<PeerRow> peers;

  factory PeerComparison.fromJson(Map<String, dynamic> json) {
    final peers = json['peers'];
    return PeerComparison(
      group: asString(json['group']) ?? 'sector',
      self: json['self'] is Map
          ? PeerRow.fromJson((json['self'] as Map).cast<String, dynamic>())
          : null,
      peers: peers is List
          ? peers
                .whereType<Map>()
                .map((e) => PeerRow.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const <PeerRow>[],
    );
  }
}

class PricePoint {
  const PricePoint({
    required this.date,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
    this.dma50,
    this.dma200,
  });

  final String date;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final double? volume;

  /// `null` until there is enough history — skip those points, never plot zero.
  final double? dma50;
  final double? dma200;

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      date: asString(json['date']) ?? '',
      open: asDouble(json['open']),
      high: asDouble(json['high']),
      low: asDouble(json['low']),
      close: asDouble(json['close']),
      volume: asDouble(json['volume']),
      dma50: asDouble(json['dma50']),
      dma200: asDouble(json['dma200']),
    );
  }
}

class CompanyChart {
  const CompanyChart({
    required this.symbol,
    this.from,
    this.to,
    required this.points,
  });

  final String symbol;

  /// ISO dates of the first and last point actually returned — the request
  /// takes years, the response reports dates.
  final String? from;
  final String? to;
  final List<PricePoint> points;

  factory CompanyChart.fromJson(Map<String, dynamic> json) {
    final points = json['points'];
    return CompanyChart(
      symbol: asString(json['symbol']) ?? '',
      from: asString(json['from']),
      to: asString(json['to']),
      points: points is List
          ? points
                .whereType<Map>()
                .map((e) => PricePoint.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const <PricePoint>[],
    );
  }
}

class DocumentItem {
  const DocumentItem({required this.title, this.category, this.date, this.url});

  /// Upstream text — render as text, never as HTML.
  final String title;
  final String? category;
  final String? date;
  final String? url;

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      title: asString(json['title']) ?? '',
      category: asString(json['category']),
      date: asString(json['date']),
      url: asString(json['url']),
    );
  }
}

List<DocumentItem> _documents(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => DocumentItem.fromJson(e.cast<String, dynamic>()))
      .toList();
}

class CompanyDocuments {
  const CompanyDocuments({
    required this.announcements,
    required this.callTranscripts,
    required this.presentations,
    required this.creditRatings,
  });

  final List<DocumentItem> announcements;
  final List<DocumentItem> callTranscripts;
  final List<DocumentItem> presentations;
  final List<DocumentItem> creditRatings;

  /// Each list degrades to empty independently; empty means "nothing to show".
  bool get isEmpty =>
      announcements.isEmpty &&
      callTranscripts.isEmpty &&
      presentations.isEmpty &&
      creditRatings.isEmpty;

  factory CompanyDocuments.fromJson(Map<String, dynamic> json) {
    return CompanyDocuments(
      announcements: _documents(json['announcements']),
      callTranscripts: _documents(json['callTranscripts']),
      presentations: _documents(json['presentations']),
      creditRatings: _documents(json['creditRatings']),
    );
  }
}

class CorporateActionItem {
  const CorporateActionItem({
    required this.type,
    this.detail,
    this.date,
    this.amount,
  });

  final String type;
  final String? detail;
  final String? date;
  final double? amount;

  factory CorporateActionItem.fromJson(Map<String, dynamic> json) {
    return CorporateActionItem(
      type: asString(json['type']) ?? '',
      detail: asString(json['detail']),
      date: asString(json['date']),
      amount: asDouble(json['amount']),
    );
  }
}

List<CorporateActionItem> _actions(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => CorporateActionItem.fromJson(e.cast<String, dynamic>()))
      .toList();
}

class CompanyCorporateActions {
  const CompanyCorporateActions({
    required this.dividends,
    required this.splits,
    required this.bonuses,
    required this.rights,
  });

  final List<CorporateActionItem> dividends;
  final List<CorporateActionItem> splits;
  final List<CorporateActionItem> bonuses;
  final List<CorporateActionItem> rights;

  bool get isEmpty =>
      dividends.isEmpty && splits.isEmpty && bonuses.isEmpty && rights.isEmpty;

  factory CompanyCorporateActions.fromJson(Map<String, dynamic> json) {
    return CompanyCorporateActions(
      dividends: _actions(json['dividends']),
      splits: _actions(json['splits']),
      bonuses: _actions(json['bonuses']),
      rights: _actions(json['rights']),
    );
  }
}

class SegmentEntry {
  const SegmentEntry({required this.name, this.revenueCr, this.profitCr});

  final String name;
  final double? revenueCr;
  final double? profitCr;

  factory SegmentEntry.fromJson(Map<String, dynamic> json) {
    return SegmentEntry(
      name: asString(json['name']) ?? '',
      revenueCr: asDouble(json['revenueCr']),
      profitCr: asDouble(json['profitCr']),
    );
  }
}

class SegmentPeriod {
  const SegmentPeriod({required this.period, required this.segments});

  final String period;
  final List<SegmentEntry> segments;

  factory SegmentPeriod.fromJson(Map<String, dynamic> json) {
    final segments = json['segments'];
    return SegmentPeriod(
      period: asString(json['period']) ?? '',
      segments: segments is List
          ? segments
                .whereType<Map>()
                .map((e) => SegmentEntry.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const <SegmentEntry>[],
    );
  }
}

class SearchHit {
  const SearchHit({
    required this.symbol,
    required this.name,
    this.nseCode,
    this.bseCode,
  });

  final String symbol;
  final String name;
  final String? nseCode;
  final String? bseCode;

  factory SearchHit.fromJson(Map<String, dynamic> json) {
    return SearchHit(
      symbol: asString(json['symbol']) ?? '',
      name: asString(json['name']) ?? '',
      nseCode: asString(json['nseCode']),
      bseCode: asString(json['bseCode']),
    );
  }
}

/// `GET /companies/:symbol` — every section in one call. A section that failed
/// upstream is `null` and named in [unavailable]; [overview] is never null
/// because the whole request fails with it.
class CompanyPage {
  const CompanyPage({
    required this.overview,
    this.profitAndLoss,
    this.quarterlyResults,
    this.balanceSheet,
    this.cashFlow,
    this.ratios,
    this.growth,
    this.shareholding,
    this.peers,
    required this.unavailable,
  });

  final CompanyOverview overview;
  final FinancialTable? profitAndLoss;
  final FinancialTable? quarterlyResults;
  final FinancialTable? balanceSheet;
  final FinancialTable? cashFlow;
  final FinancialTable? ratios;
  final CompanyGrowth? growth;
  final CompanyShareholding? shareholding;
  final PeerComparison? peers;
  final List<String> unavailable;

  static FinancialTable? _table(dynamic value) => value is Map
      ? FinancialTable.fromJson(value.cast<String, dynamic>())
      : null;

  factory CompanyPage.fromJson(Map<String, dynamic> json) {
    return CompanyPage(
      overview: CompanyOverview.fromJson(
        (json['overview'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      profitAndLoss: _table(json['profitAndLoss']),
      quarterlyResults: _table(json['quarterlyResults']),
      balanceSheet: _table(json['balanceSheet']),
      cashFlow: _table(json['cashFlow']),
      ratios: _table(json['ratios']),
      growth: json['growth'] is Map
          ? CompanyGrowth.fromJson(
              (json['growth'] as Map).cast<String, dynamic>(),
            )
          : null,
      shareholding: json['shareholding'] is Map
          ? CompanyShareholding.fromJson(
              (json['shareholding'] as Map).cast<String, dynamic>(),
            )
          : null,
      peers: json['peers'] is Map
          ? PeerComparison.fromJson(
              (json['peers'] as Map).cast<String, dynamic>(),
            )
          : null,
      unavailable: asStringList(json['unavailable']),
    );
  }
}
