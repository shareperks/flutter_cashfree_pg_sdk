/// Models matching the Finance / Screener API's native response structure.
///
/// Unlike the legacy [CompanyPage] models which flatten the API's nested
/// `ui.rows` into positional arrays, these preserve the full nested
/// hierarchy so the UI can render expandable tables with `valueKey`
/// dot-paths, row types, and child rows exactly as the web app does.
library;

import 'dart:math' as math;

// ─── helpers ────────────────────────────────────────────────────────────────

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _asMap(dynamic value) => value is Map<String, dynamic>
    ? value
    : value is Map
    ? Map<String, dynamic>.from(value)
    : const <String, dynamic>{};

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// Resolves a dot-path like `display.revenue` against a period object.
double? _resolvePath(Map<String, dynamic> period, String path) {
  final segments = path.split('.');
  dynamic current = period;
  for (final seg in segments) {
    if (current is! Map) return null;
    current = current[seg];
  }
  return _asDouble(current);
}

// ─── profile ────────────────────────────────────────────────────────────────

class ScreenerProfile {
  const ScreenerProfile({
    required this.symbol,
    required this.name,
    this.nseCode,
    this.bseCode,
    this.sector,
    this.industry,
    this.subIndustry,
    this.macroSector,
    this.website,
    this.description,
    this.marketCap,
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
  final String? description;
  final double? marketCap;

  factory ScreenerProfile.fromJson(Map<String, dynamic> json) {
    return ScreenerProfile(
      symbol: _asString(json['symbol']) ?? _asString(json['nse_code']) ?? '',
      name: _asString(json['name']) ?? _asString(json['symbol']) ?? '',
      nseCode: _asString(json['nse_code']),
      bseCode: _asString(json['bse_code']),
      sector: _asString(json['sector']),
      industry: _asString(json['industry']),
      subIndustry: _asString(json['sub_industry']),
      macroSector: _asString(json['macro_sector']),
      website: _asString(json['website']),
      description: _asString(json['description']),
      marketCap: _asDouble(json['market_cap']),
    );
  }

  String get initials {
    final words = name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .trim()
        .split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return words.isNotEmpty && words[0].isNotEmpty
        ? words[0].substring(0, math.min(2, words[0].length)).toUpperCase()
        : '?';
  }
}

// ─── quote ──────────────────────────────────────────────────────────────────

class ScreenerQuote {
  const ScreenerQuote({
    this.currentPrice,
    this.change,
    this.changePct,
    this.high52,
    this.low52,
    this.highPrice,
    this.lowPrice,
    this.openPrice,
    this.marketCap,
    this.shares,
    this.tradetime,
    this.volume,
  });

  final double? currentPrice;
  final String? change;
  final double? changePct;
  final double? high52;
  final double? low52;
  final double? highPrice;
  final double? lowPrice;
  final double? openPrice;
  final double? marketCap;
  final double? shares;
  final String? tradetime;
  final double? volume;

  /// 52-week range position as a percentage (0–100).
  double? get rangePct {
    if (currentPrice == null ||
        low52 == null ||
        high52 == null ||
        high52! <= low52!) {
      return null;
    }
    final pct = ((currentPrice! - low52!) / (high52! - low52!) * 100);
    return pct.clamp(0, 100);
  }

  factory ScreenerQuote.fromJson(Map<String, dynamic> json) {
    final changeStr = _asString(json['change']);
    return ScreenerQuote(
      currentPrice: _asDouble(json['current_price']),
      change: changeStr,
      changePct: changeStr != null
          ? double.tryParse(changeStr.replaceAll('%', ''))
          : null,
      high52: _asDouble(json['high52']),
      low52: _asDouble(json['low52']),
      highPrice: _asDouble(json['high_price']),
      lowPrice: _asDouble(json['low_price']),
      openPrice: _asDouble(json['open_price']),
      marketCap: _asDouble(json['market_cap']),
      shares: _asDouble(json['shares']),
      tradetime: _asString(json['tradetime']),
      volume: _asDouble(json['volume']),
    );
  }

  /// The aggregate response keys quote by symbol: `{ "ITC": { ... } }`.
  factory ScreenerQuote.fromAggregate(
    Map<String, dynamic> json,
    String ticker,
  ) {
    final bySymbol = _asMap(json);
    final data = bySymbol[ticker] is Map
        ? _asMap(bySymbol[ticker])
        : (bySymbol.values.whereType<Map>().firstOrNull != null
              ? _asMap(bySymbol.values.whereType<Map>().first)
              : null);
    if (data == null || data.isEmpty) return const ScreenerQuote();
    return ScreenerQuote.fromJson(data);
  }
}

// ─── basic ratios ───────────────────────────────────────────────────────────

class ScreenerBasicRatio {
  const ScreenerBasicRatio({
    required this.header,
    required this.year,
    this.adjustedFaceValue,
    this.dilutedSharesOutstanding,
    this.dividendPayout,
    this.eps,
    this.ebit,
    this.ebitda,
    this.operatingProfit,
    this.operatingRevenue,
    this.salesPerShare,
    this.sharesOutstanding,
    this.tax,
  });

  final String header;
  final int year;
  final double? adjustedFaceValue;
  final double? dilutedSharesOutstanding;
  final double? dividendPayout;
  final double? eps;
  final double? ebit;
  final double? ebitda;
  final double? operatingProfit;
  final double? operatingRevenue;
  final double? salesPerShare;
  final double? sharesOutstanding;
  final double? tax;

  bool get isTtm => header == 'TTM';

  factory ScreenerBasicRatio.fromJson(Map<String, dynamic> json) {
    return ScreenerBasicRatio(
      header: _asString(json['header']) ?? '',
      year: _asInt(json['year']) ?? 0,
      adjustedFaceValue: _asDouble(json['adjustedFaceValue']),
      dilutedSharesOutstanding: _asDouble(json['dilutedSharesOutstanding']),
      dividendPayout: _asDouble(json['dividendPayout']),
      eps: _asDouble(json['eps']),
      ebit: _asDouble(json['ebit']),
      ebitda: _asDouble(json['ebitda']),
      operatingProfit: _asDouble(json['operatingProfit']),
      operatingRevenue: _asDouble(json['operatingRevenue']),
      salesPerShare: _asDouble(json['salesPerShare']),
      sharesOutstanding: _asDouble(json['sharesOutstanding']),
      tax: _asDouble(json['tax']),
    );
  }
}

class ScreenerBasic {
  const ScreenerBasic({required this.ratios});

  final List<ScreenerBasicRatio> ratios;

  /// TTM entry (first in the list).
  ScreenerBasicRatio? get ttm => ratios.isNotEmpty ? ratios.first : null;

  /// Annual entries (excluding TTM), deduplicated by year, preferring "Mar" headers.
  List<ScreenerBasicRatio> get annual {
    final seen = <int, ScreenerBasicRatio>{};
    for (final r in ratios) {
      if (r.isTtm) continue;
      final year = r.year;
      if (!seen.containsKey(year)) {
        seen[year] = r;
      } else {
        final existing = seen[year]!;
        final rIsMar = r.header.startsWith('Mar');
        final existingIsMar = existing.header.startsWith('Mar');
        if (rIsMar && !existingIsMar) seen[year] = r;
      }
    }
    final list = seen.values.toList()..sort((a, b) => b.year.compareTo(a.year));
    return list;
  }

  factory ScreenerBasic.fromJson(Map<String, dynamic> json) {
    return ScreenerBasic(
      ratios: _asList(json['ratios']).map(ScreenerBasicRatio.fromJson).toList(),
    );
  }
}

// ─── financial ratios ───────────────────────────────────────────────────────

class ScreenerRatioEntry {
  const ScreenerRatioEntry({
    required this.header,
    required this.year,
    this.ebitMargin,
    this.ebitdaMargin,
    this.effectiveTaxRate,
    this.grossMargin,
    this.netMargin,
    this.operatingMargin,
    this.preTaxMargin,
    this.returnOnAsset,
    this.returnOnCapital,
    this.returnOnEquity,
    this.returnOnTangibleAssets,
  });

  final String header;
  final int year;
  final double? ebitMargin;
  final double? ebitdaMargin;
  final double? effectiveTaxRate;
  final double? grossMargin;
  final double? netMargin;
  final double? operatingMargin;
  final double? preTaxMargin;
  final double? returnOnAsset;
  final double? returnOnCapital;
  final double? returnOnEquity;
  final double? returnOnTangibleAssets;

  bool get isTtm => header == 'TTM';

  /// All ratio fields as a map (for iteration).
  Map<String, double?> get allRatios => {
    'grossMargin': grossMargin,
    'operatingMargin': operatingMargin,
    'ebitdaMargin': ebitdaMargin,
    'ebitMargin': ebitMargin,
    'preTaxMargin': preTaxMargin,
    'netMargin': netMargin,
    'effectiveTaxRate': effectiveTaxRate,
    'returnOnEquity': returnOnEquity,
    'returnOnCapital': returnOnCapital,
    'returnOnAsset': returnOnAsset,
    'returnOnTangibleAssets': returnOnTangibleAssets,
  };

  factory ScreenerRatioEntry.fromJson(Map<String, dynamic> json) {
    return ScreenerRatioEntry(
      header: _asString(json['header']) ?? '',
      year: _asInt(json['year']) ?? 0,
      ebitMargin: _asDouble(json['ebitMargin']),
      ebitdaMargin: _asDouble(json['ebitdaMargin']),
      effectiveTaxRate: _asDouble(json['effectiveTaxRate']),
      grossMargin: _asDouble(json['grossMargin']),
      netMargin: _asDouble(json['netMargin']),
      operatingMargin: _asDouble(json['operatingMargin']),
      preTaxMargin: _asDouble(json['preTaxMargin']),
      returnOnAsset: _asDouble(json['returnOnAsset']),
      returnOnCapital: _asDouble(json['returnOnCapital']),
      returnOnEquity: _asDouble(json['returnOnEquity']),
      returnOnTangibleAssets: _asDouble(json['returnOnTangibleAssets']),
    );
  }
}

class ScreenerRatios {
  const ScreenerRatios({required this.entries});

  final List<ScreenerRatioEntry> entries;

  /// Annual entries (excluding TTM), newest first.
  List<ScreenerRatioEntry> get annual {
    final seen = <int, ScreenerRatioEntry>{};
    for (final r in entries) {
      if (r.isTtm) continue;
      if (!seen.containsKey(r.year)) {
        seen[r.year] = r;
      } else {
        final existing = seen[r.year]!;
        final rIsMar = r.header.startsWith('Mar');
        final existingIsMar = existing.header.startsWith('Mar');
        if (rIsMar && !existingIsMar) seen[r.year] = r;
      }
    }
    return seen.values.toList()..sort((a, b) => b.year.compareTo(a.year));
  }

  /// TTM entry.
  ScreenerRatioEntry? get ttm => entries.where((e) => e.isTtm).firstOrNull;

  factory ScreenerRatios.fromJson(Map<String, dynamic> json) {
    return ScreenerRatios(
      entries: _asList(
        json['ratios'],
      ).map(ScreenerRatioEntry.fromJson).toList(),
    );
  }
}

// ─── price ratios (analysis) ────────────────────────────────────────────────

class ScreenerPriceRatio {
  const ScreenerPriceRatio({
    required this.header,
    required this.year,
    this.pe,
    this.pb,
    this.ps,
    this.pfcf,
    this.averagePrice,
  });

  final String header;
  final int year;
  final double? pe;
  final double? pb;
  final double? ps;
  final double? pfcf;
  final double? averagePrice;

  bool get isTtm => header == 'TTM';

  factory ScreenerPriceRatio.fromJson(Map<String, dynamic> json) {
    return ScreenerPriceRatio(
      header: _asString(json['header']) ?? '',
      year: _asInt(json['year']) ?? 0,
      pe: _asDouble(json['pe']),
      pb: _asDouble(json['pb']),
      ps: _asDouble(json['ps']),
      pfcf: _asDouble(json['pfcf']),
      averagePrice: _asDouble(json['average_price']),
    );
  }
}

class ScreenerPriceRatios {
  const ScreenerPriceRatios({required this.entries});

  final List<ScreenerPriceRatio> entries;

  /// Annual entries (excluding TTM), deduplicated, newest first.
  List<ScreenerPriceRatio> get annual {
    final seen = <int, ScreenerPriceRatio>{};
    for (final r in entries) {
      if (r.isTtm) continue;
      if (!seen.containsKey(r.year)) {
        seen[r.year] = r;
      } else {
        final existing = seen[r.year]!;
        final rIsMar = r.header.startsWith('Mar');
        final existingIsMar = existing.header.startsWith('Mar');
        if (rIsMar && !existingIsMar) seen[r.year] = r;
      }
    }
    return seen.values.toList()..sort((a, b) => b.year.compareTo(a.year));
  }

  factory ScreenerPriceRatios.fromJson(Map<String, dynamic> json) {
    return ScreenerPriceRatios(
      entries: _asList(
        json['price_ratios'],
      ).map(ScreenerPriceRatio.fromJson).toList(),
    );
  }
}

// ─── financial metrics (analysis) ───────────────────────────────────────────

class ScreenerFinancialMetrics {
  const ScreenerFinancialMetrics({
    this.operatingCashFlow3yr,
    this.freeCashFlow3yr,
    this.investingCashFlow3yr,
    this.financingCashFlow3yr,
  });

  final double? operatingCashFlow3yr;
  final double? freeCashFlow3yr;
  final double? investingCashFlow3yr;
  final double? financingCashFlow3yr;

  factory ScreenerFinancialMetrics.fromJson(Map<String, dynamic> json) {
    final fm = _asMap(json['financial_metrics']);
    return ScreenerFinancialMetrics(
      operatingCashFlow3yr: _asDouble(fm['operatingCashFlow3yearsTotal']),
      freeCashFlow3yr: _asDouble(fm['freeCashFlow3yearsTotal']),
      investingCashFlow3yr: _asDouble(fm['investingCashFlow3yearsTotal']),
      financingCashFlow3yr: _asDouble(fm['financingCashFlow3yearsTotal']),
    );
  }
}

// ─── row definitions (ui.rows) ──────────────────────────────────────────────

/// Row type controls styling and value formatting.
enum ScreenerRowType {
  section,
  line,
  total,
  profit,
  ratio,
  perShare;

  static ScreenerRowType parse(String? value) => switch (value) {
    'section' => ScreenerRowType.section,
    'total' => ScreenerRowType.total,
    'profit' => ScreenerRowType.profit,
    'ratio' => ScreenerRowType.ratio,
    'per_share' => ScreenerRowType.perShare,
    _ => ScreenerRowType.line,
  };

  bool get isBold =>
      this == ScreenerRowType.total ||
      this == ScreenerRowType.profit ||
      this == ScreenerRowType.section;

  bool get isPercentage => this == ScreenerRowType.ratio;
  bool get isPerShare => this == ScreenerRowType.perShare;
}

/// A row definition from `ui.rows` — may have nested `children`.
class ScreenerRowDef {
  const ScreenerRowDef({
    required this.id,
    required this.label,
    required this.type,
    required this.level,
    this.expandable = false,
    this.defaultExpanded = false,
    this.highlight = false,
    this.valueKey,
    this.calculation,
    this.children = const [],
  });

  final String id;
  final String label;
  final ScreenerRowType type;
  final int level;
  final bool expandable;
  final bool defaultExpanded;
  final bool highlight;
  final String? valueKey;
  final String? calculation;
  final List<ScreenerRowDef> children;

  factory ScreenerRowDef.fromJson(Map<String, dynamic> json) {
    return ScreenerRowDef(
      id: _asString(json['id']) ?? _asString(json['key']) ?? '',
      label: _asString(json['label']) ?? '',
      type: ScreenerRowType.parse(_asString(json['type'])),
      level: _asInt(json['level']) ?? 0,
      expandable: json['expandable'] == true,
      defaultExpanded: json['defaultExpanded'] == true,
      highlight: json['highlight'] == true,
      valueKey: _asString(json['valueKey']),
      calculation: _asString(json['calculation']),
      children: _asList(json['children']).map(ScreenerRowDef.fromJson).toList(),
    );
  }
}

// ─── statement (P&L, quarterly, balance sheet) ──────────────────────────────

/// A period within a structured statement — has `display`, `yoy`, `metrics`.
class ScreenerPeriod {
  const ScreenerPeriod({
    required this.label,
    required this.year,
    required this.data,
  });

  /// Column header: `fiscalYear` (annual) or `period.monthLabel` (quarterly).
  final String label;
  final int year;

  /// The raw period object — `display`, `yoy`, `metrics` are accessed via
  /// dot-paths from [ScreenerRowDef.valueKey].
  final Map<String, dynamic> data;

  /// Resolves a dot-path like `display.revenue` against this period.
  double? value(String? path) => path == null ? null : _resolvePath(data, path);

  factory ScreenerPeriod.fromAnnual(Map<String, dynamic> json) {
    return ScreenerPeriod(
      label: _asString(json['fiscalYear']) ?? '',
      year: _asInt(json['year']) ?? 0,
      data: json,
    );
  }

  factory ScreenerPeriod.fromQuarter(Map<String, dynamic> json) {
    final period = _asMap(json['period']);
    return ScreenerPeriod(
      label:
          _asString(period['monthLabel']) ??
          _asString(period['shortLabel']) ??
          _asString(period['quarter']) ??
          '',
      year: _asInt(period['fiscalYear']) ?? _asInt(json['year']) ?? 0,
      data: json,
    );
  }
}

/// A structured statement: P&L, quarterly, or balance sheet.
class ScreenerStatement {
  const ScreenerStatement({
    required this.symbol,
    required this.companyName,
    required this.consolidationType,
    required this.periods,
    required this.rows,
    required this.isQuarterly,
    this.longTermMetrics,
  });

  final String symbol;
  final String? companyName;

  /// `'c'` or `'s'`.
  final String consolidationType;
  final List<ScreenerPeriod> periods;
  final List<ScreenerRowDef> rows;
  final bool isQuarterly;
  final ScreenerLongTermMetrics? longTermMetrics;

  bool get isStandalone => consolidationType == 's';
  bool get isEmpty => rows.isEmpty || periods.isEmpty;

  /// `FY26` or `Q1 FY26-27`.
  String get latestLabel => periods.isNotEmpty ? periods.last.label : '';

  factory ScreenerStatement.fromJson(
    Map<String, dynamic> json, {
    bool isQuarterly = false,
  }) {
    final periodsRaw = _asList(json['annualFinancials']);
    final quartersRaw = _asList(json['quarters']);
    final periods = isQuarterly
        ? quartersRaw.map(ScreenerPeriod.fromQuarter).toList()
        : periodsRaw.map(ScreenerPeriod.fromAnnual).toList();

    // Row definitions: prefer `ui.rows`, fall back to `lineItems`.
    final uiRows = _asList(_asMap(json['ui'])['rows']);
    final lineItems = _asList(json['lineItems']);
    final rows = uiRows.isNotEmpty
        ? uiRows.map(ScreenerRowDef.fromJson).toList()
        : lineItems
              .map(
                (item) => ScreenerRowDef(
                  id: _asString(item['key']) ?? '',
                  label: _asString(item['label']) ?? '',
                  type: ScreenerRowType.parse(_asString(item['type'])),
                  level: 0,
                  valueKey: 'display.${item['key']}',
                ),
              )
              .toList();

    return ScreenerStatement(
      symbol: _asString(json['symbol']) ?? '',
      companyName: _asString(json['companyName']),
      consolidationType: _asString(json['consolidationType']) ?? 'c',
      periods: periods,
      rows: rows,
      isQuarterly: isQuarterly,
      longTermMetrics: json['longTermMetrics'] is Map
          ? ScreenerLongTermMetrics.fromJson(_asMap(json['longTermMetrics']))
          : null,
    );
  }
}

/// Long-term CAGR metrics from the P&L endpoint.
class ScreenerLongTermMetrics {
  const ScreenerLongTermMetrics({
    this.fromFiscalYear,
    this.toFiscalYear,
    this.periods,
    this.revenueCagr,
    this.patCagr,
    this.epsCagr,
    this.patMarginExpansionPp,
  });

  final String? fromFiscalYear;
  final String? toFiscalYear;
  final int? periods;
  final double? revenueCagr;
  final double? patCagr;
  final double? epsCagr;
  final double? patMarginExpansionPp;

  factory ScreenerLongTermMetrics.fromJson(Map<String, dynamic> json) {
    return ScreenerLongTermMetrics(
      fromFiscalYear: _asString(json['fromFiscalYear']),
      toFiscalYear: _asString(json['toFiscalYear']),
      periods: _asInt(json['periods']),
      revenueCagr: _asDouble(json['revenueCagr']),
      patCagr: _asDouble(json['patCagr']),
      epsCagr: _asDouble(json['epsCagr']),
      patMarginExpansionPp: _asDouble(json['patMarginExpansionPp']),
    );
  }
}

// ─── cash flow ──────────────────────────────────────────────────────────────

/// A cash flow row — values keyed by period label.
class ScreenerCashFlowRow {
  const ScreenerCashFlowRow({
    required this.id,
    required this.label,
    required this.section,
    required this.level,
    this.expandable = false,
    this.highlight = false,
    required this.values,
  });

  final String id;
  final String label;
  final String section;
  final int level;
  final bool expandable;
  final bool highlight;

  /// `{ "FY19": 123456, "FY20": 234567, ... }` — values in **rupees**.
  final Map<String, double?> values;

  /// True if all values are null or zero.
  bool get isAllZero => values.values.every((v) => v == null || v == 0);

  /// Always-shown rows per the guide.
  static const _alwaysShown = {
    'operating-cf',
    'investing-cf',
    'financing-cf',
    'free-cash-flow',
    'net-cash-flow',
  };

  bool get alwaysShown => _alwaysShown.contains(id);

  factory ScreenerCashFlowRow.fromJson(Map<String, dynamic> json) {
    final rawValues = _asMap(json['values']);
    return ScreenerCashFlowRow(
      id: _asString(json['id']) ?? '',
      label: _asString(json['label']) ?? '',
      section: _asString(json['section']) ?? '',
      level: _asInt(json['level']) ?? 0,
      expandable: json['expandable'] == true,
      highlight: json['highlight'] == true,
      values: rawValues.map((k, v) => MapEntry(k, _asDouble(v))),
    );
  }
}

class ScreenerCashFlow {
  const ScreenerCashFlow({
    required this.symbol,
    required this.consolidationType,
    required this.annualPeriods,
    required this.annualRows,
    required this.quarterlyPeriods,
    required this.quarterlyRows,
  });

  final String symbol;
  final String consolidationType;
  final List<String> annualPeriods;
  final List<ScreenerCashFlowRow> annualRows;
  final List<String> quarterlyPeriods;
  final List<ScreenerCashFlowRow> quarterlyRows;

  bool get isStandalone => consolidationType == 's';
  bool get isEmpty => annualRows.isEmpty || annualPeriods.isEmpty;

  /// Visible rows: hide all-zero rows except always-shown ones.
  List<ScreenerCashFlowRow> visibleRows(bool quarterly) {
    final rows = quarterly ? quarterlyRows : annualRows;
    return rows.where((r) => r.alwaysShown || !r.isAllZero).toList();
  }

  factory ScreenerCashFlow.fromJson(Map<String, dynamic> json) {
    final annual = _asMap(json['annual']);
    final quarterly = _asMap(json['quarterly']);
    return ScreenerCashFlow(
      symbol: _asString(json['symbol']) ?? '',
      consolidationType: _asString(json['consolidationType']) ?? 'c',
      annualPeriods:
          (annual['periods'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      annualRows: _asList(
        annual['rows'],
      ).map(ScreenerCashFlowRow.fromJson).toList(),
      quarterlyPeriods:
          (quarterly['periods'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      quarterlyRows: _asList(
        quarterly['rows'],
      ).map(ScreenerCashFlowRow.fromJson).toList(),
    );
  }
}

// ─── shareholding ───────────────────────────────────────────────────────────

/// Maps the API's `catagory` field (note: misspelled in the API) to a clean
/// display label. Also fixes common misspellings like `Goverments`.
const _shareholdingCategoryLabels = <String, String>{
  'promoterIndian': 'Promoters (Indian)',
  'PromoterIndian': 'Promoters (Indian)',
  'PromoterForeign': 'Promoters (Foreign)',
  'promoterForeign': 'Promoters (Foreign)',
  'InstitutionsDomestic': 'DIIs',
  'institutionsDomestic': 'DIIs',
  'DIIs': 'DIIs',
  'InstitutionsForeign': 'FIIs',
  'institutionsForeign': 'FIIs',
  'FIIs': 'FIIs',
  'Government': 'Government',
  'government': 'Government',
  'Goverments': 'Government',
  'goverments': 'Government',
  'Goverment': 'Government',
  'goverment': 'Government',
  'NonInstitutions': 'Non-Institutions',
  'nonInstitutions': 'Non-Institutions',
  'NonInstitution': 'Non-Institutions',
  'Non-institutions': 'Non-Institutions',
  'SharesHeldByNonPromoterNonPublicShareholders': 'Non-Promoter Non-Public',
  'Public': 'Public',
};

class ScreenerShareholdingCategory {
  const ScreenerShareholdingCategory({
    required this.name,
    this.category,
    required this.values,
    required this.holders,
  });

  final String name;
  final String? category;

  /// Keyed by column label (e.g. `Mar 2025`).
  final Map<String, double?> values;
  final List<ScreenerShareholdingCategory> holders;

  /// Normalized display label derived from the `catagory` field, falling
  /// back to the raw `name` if no mapping is found.
  String get displayName {
    if (category != null && _shareholdingCategoryLabels.containsKey(category)) {
      return _shareholdingCategoryLabels[category]!;
    }
    return name;
  }

  /// True if any of the visible columns has a non-zero, non-null value.
  bool hasNonZeroValues(List<String> visibleCols) {
    for (final col in visibleCols) {
      final v = values[col];
      if (v != null && v != 0) return true;
    }
    return false;
  }

  /// Returns holders filtered to those with at least one non-zero value in
  /// the visible columns.
  List<ScreenerShareholdingCategory> filteredHolders(List<String> visibleCols) {
    return holders.where((h) => h.hasNonZeroValues(visibleCols)).toList();
  }

  factory ScreenerShareholdingCategory.fromJson(Map<String, dynamic> json) {
    final rawValues = _asMap(json['data']);
    final rawHolders = _asList(json['shareholders']);
    return ScreenerShareholdingCategory(
      name: _asString(json['name']) ?? '',
      category: _asString(json['catagory']),
      values: rawValues.map((k, v) => MapEntry(k, _asDouble(v))),
      holders: rawHolders.map(ScreenerShareholdingCategory.fromJson).toList(),
    );
  }
}

class ScreenerShareholding {
  const ScreenerShareholding({required this.columns, required this.categories});

  final List<String> columns;
  final List<ScreenerShareholdingCategory> categories;

  /// Last 6 columns (per the guide).
  List<String> get visibleColumns =>
      columns.length > 6 ? columns.sublist(columns.length - 6) : columns;

  bool get isEmpty => categories.isEmpty || columns.isEmpty;

  /// Preferred row order per the guide, matched case-insensitively against
  /// the normalized display name.
  static const _preferredOrder = [
    'promoters',
    'diis',
    'fiis',
    'government',
    'non-institutions',
    'non-promoter non-public',
    'public',
  ];

  /// Categories sorted by the preferred order, with zero-only categories
  /// filtered out. Matching is case-insensitive and uses the normalized
  /// `displayName` (which maps the `catagory` field to a clean label).
  List<ScreenerShareholdingCategory> get sortedCategories {
    final cols = visibleColumns;
    // Filter out zero-only categories.
    final nonZero = categories.where((c) => c.hasNonZeroValues(cols)).toList();

    // Sort by preferred order using case-insensitive displayName matching.
    int sortOrder(ScreenerShareholdingCategory c) {
      final label = c.displayName.toLowerCase();
      for (var i = 0; i < _preferredOrder.length; i++) {
        if (label.contains(_preferredOrder[i])) return i;
      }
      return _preferredOrder.length;
    }

    nonZero.sort((a, b) {
      final sa = sortOrder(a);
      final sb = sortOrder(b);
      if (sa != sb) return sa.compareTo(sb);
      return a.displayName.compareTo(b.displayName);
    });
    return nonZero;
  }

  factory ScreenerShareholding.fromJson(Map<String, dynamic> json) {
    return ScreenerShareholding(
      columns:
          (json['columns'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      categories: _asList(
        json['rows'],
      ).map(ScreenerShareholdingCategory.fromJson).toList(),
    );
  }
}

// ─── peers ──────────────────────────────────────────────────────────────────

class ScreenerPeer {
  const ScreenerPeer({
    required this.symbol,
    this.name,
    this.nseCode,
    this.cmp,
    this.change,
    this.changePct,
    this.marketCap,
    this.pe,
    this.pb,
    this.roe,
    this.opm,
  });

  final String symbol;
  final String? name;
  final String? nseCode;
  final double? cmp;
  final String? change;
  final double? changePct;
  final double? marketCap;
  final double? pe;
  final double? pb;
  final double? roe;
  final double? opm;

  /// Data completeness score for sorting.
  int get completeness {
    const fields = ['cmp', 'change', 'marketCap', 'pe', 'pb', 'roe', 'opm'];
    var score = 0;
    for (final f in fields) {
      final v = switch (f) {
        'cmp' => cmp,
        'change' => change,
        'marketCap' => marketCap,
        'pe' => pe,
        'pb' => pb,
        'roe' => roe,
        'opm' => opm,
        _ => null,
      };
      if (v != null && v.toString().isNotEmpty) score++;
    }
    return score;
  }

  factory ScreenerPeer.fromJson(Map<String, dynamic> json) {
    final changeStr = _asString(json['change']);
    return ScreenerPeer(
      symbol: _asString(json['symbol']) ?? '',
      name: _asString(json['name']),
      nseCode: _asString(json['nseCode']),
      cmp: _asDouble(json['cmp']),
      change: changeStr,
      changePct: changeStr != null
          ? double.tryParse(changeStr.replaceAll('%', ''))
          : null,
      marketCap: _asDouble(json['marketCap']),
      pe: _asDouble(json['pe']),
      pb: _asDouble(json['pb']),
      roe: _asDouble(json['roe']),
      opm: _asDouble(json['opm']),
    );
  }
}

class ScreenerPeers {
  const ScreenerPeers({required this.ticker, required this.peers});

  final String ticker;
  final List<ScreenerPeer> peers;

  /// The requested company.
  ScreenerPeer? get self {
    final upper = ticker.toUpperCase();
    return peers.where((p) => p.symbol.toUpperCase() == upper).firstOrNull;
  }

  /// Other peers, sorted by data completeness (most complete first).
  List<ScreenerPeer> get others {
    final upper = ticker.toUpperCase();
    final list = peers.where((p) => p.symbol.toUpperCase() != upper).toList();
    list.sort((a, b) => b.completeness.compareTo(a.completeness));
    return list;
  }

  factory ScreenerPeers.fromJson(Map<String, dynamic> json, String ticker) {
    final rawPeers = json['peers'];
    // Peers can be a list of strings (symbols) or a list of objects.
    List<ScreenerPeer> peerList;
    if (rawPeers is List) {
      peerList = rawPeers.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        return ScreenerPeer.fromJson(m);
      }).toList();
    } else {
      peerList = const [];
    }
    return ScreenerPeers(ticker: ticker, peers: peerList);
  }
}

// ─── historical price ───────────────────────────────────────────────────────

class ScreenerPricePoint {
  const ScreenerPricePoint({
    required this.date,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
  });

  final String date;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final double? volume;

  factory ScreenerPricePoint.fromJson(Map<String, dynamic> json) {
    return ScreenerPricePoint(
      date: _asString(json['quote_date']) ?? '',
      open: _asDouble(json['open_price']),
      high: _asDouble(json['high_price']),
      low: _asDouble(json['low_price']),
      close: _asDouble(json['close_price']),
      volume: _asDouble(json['volume']),
    );
  }
}

class ScreenerChart {
  const ScreenerChart({required this.symbol, required this.points});

  final String symbol;
  final List<ScreenerPricePoint> points;

  bool get isEmpty => points.isEmpty;

  /// Filtered by time frame (days count).
  /// API returns newest-first; we sort to chronological.
  ScreenerChart filtered(int days) {
    final sorted = List<ScreenerPricePoint>.from(points)
      ..sort((a, b) => a.date.compareTo(b.date));
    // Filter out invalid points.
    final valid = sorted.where((p) => p.close != null && p.close! > 0).toList();
    if (days >= valid.length || days <= 0) {
      return ScreenerChart(symbol: symbol, points: valid);
    }
    return ScreenerChart(
      symbol: symbol,
      points: valid.sublist(valid.length - days),
    );
  }

  /// 50-day moving average (partial for first 49 points).
  List<double> dma50() =>
      _computeMA(points.map((p) => p.close ?? 0).toList(), 50);

  /// 200-day moving average (partial for first 199 points).
  List<double> dma200() =>
      _computeMA(points.map((p) => p.close ?? 0).toList(), 200);

  /// Change % from first to last point.
  double? get changePct {
    if (points.length < 2) return null;
    final first = points.first.close;
    final last = points.last.close;
    if (first == null || last == null || first == 0) return null;
    return ((last - first) / first) * 100;
  }

  static List<double> _computeMA(List<double> values, int period) {
    final result = <double>[];
    for (var i = 0; i < values.length; i++) {
      final start = math.max(0, i - period + 1);
      var sum = 0.0;
      for (var j = start; j <= i; j++) {
        sum += values[j];
      }
      result.add(sum / (i - start + 1));
    }
    return result;
  }

  factory ScreenerChart.fromJson(Map<String, dynamic> json, String symbol) {
    final prices = _asList(json['price']);
    final points = prices.map(ScreenerPricePoint.fromJson).toList();
    // Sort to chronological order.
    points.sort((a, b) => a.date.compareTo(b.date));
    return ScreenerChart(symbol: symbol, points: points);
  }
}

// ─── corporate actions ──────────────────────────────────────────────────────

class ScreenerDividend {
  const ScreenerDividend({
    this.date,
    this.type,
    this.amount,
    this.adjAmount,
    this.subject,
  });

  final String? date;
  final String? type;
  final double? amount;
  final double? adjAmount;
  final String? subject;

  factory ScreenerDividend.fromJson(Map<String, dynamic> json) {
    return ScreenerDividend(
      date: _asString(json['date']),
      type: _asString(json['dividend_type']),
      amount: _asDouble(json['amount']),
      adjAmount: _asDouble(json['adj_amount']),
      subject: _asString(json['subject']),
    );
  }
}

class ScreenerCorporateAction {
  const ScreenerCorporateAction({
    this.date,
    this.action,
    this.subject,
    this.ratio,
    this.oldFv,
    this.newFv,
  });

  final String? date;
  final String? action;
  final String? subject;
  final String? ratio;
  final double? oldFv;
  final double? newFv;

  String get description {
    if (action != null) return action!;
    if (subject != null) return subject!;
    if (ratio != null) return 'Ratio: $ratio';
    if (oldFv != null && newFv != null) {
      return 'Face Value: ₹$oldFv → ₹$newFv';
    }
    return '';
  }

  factory ScreenerCorporateAction.fromJson(Map<String, dynamic> json) {
    return ScreenerCorporateAction(
      date: _asString(json['date']),
      action: _asString(json['action']),
      subject: _asString(json['subject']),
      ratio: _asString(json['ratio']),
      oldFv: _asDouble(json['old_fv']),
      newFv: _asDouble(json['new_fv']),
    );
  }
}

class ScreenerCorporateActions {
  const ScreenerCorporateActions({
    required this.dividends,
    required this.splits,
    required this.bonuses,
    required this.rights,
  });

  final List<ScreenerDividend> dividends;
  final List<ScreenerCorporateAction> splits;
  final List<ScreenerCorporateAction> bonuses;
  final List<ScreenerCorporateAction> rights;

  bool get isEmpty =>
      dividends.isEmpty && splits.isEmpty && bonuses.isEmpty && rights.isEmpty;

  static List<ScreenerCorporateAction> _actions(dynamic value, String key) {
    final list = _asList(value);
    return list.map((e) {
      final m = Map<String, dynamic>.from(e);
      // For splits/bonuses/rights, the description fields differ.
      return ScreenerCorporateAction.fromJson(m);
    }).toList();
  }

  factory ScreenerCorporateActions.fromAggregate(Map<String, dynamic> data) {
    return ScreenerCorporateActions(
      dividends: _asList(
        data['dividends']?['dividend'],
      ).map(ScreenerDividend.fromJson).toList(),
      splits: _actions(data['splits']?['split'], 'split'),
      bonuses: _actions(data['bonuses']?['bonus'], 'bonus'),
      rights: _actions(data['rights']?['rights'], 'rights'),
    );
  }
}

// ─── documents ──────────────────────────────────────────────────────────────

class ScreenerDocument {
  const ScreenerDocument({
    required this.description,
    this.category,
    this.date,
    this.pdfUrl,
  });

  final String description;
  final String? category;
  final String? date;
  final String? pdfUrl;

  factory ScreenerDocument.fromJson(Map<String, dynamic> json) {
    return ScreenerDocument(
      description:
          _asString(json['description']) ?? _asString(json['category']) ?? '',
      category: _asString(json['category']),
      date: _asString(json['announcement_date']),
      pdfUrl: _asString(json['pdf_file_link']),
    );
  }
}

class ScreenerDocuments {
  const ScreenerDocuments({
    required this.announcements,
    required this.creditRatings,
    required this.transcripts,
    required this.presentations,
  });

  final List<ScreenerDocument> announcements;
  final List<ScreenerDocument> creditRatings;
  final List<ScreenerDocument> transcripts;
  final List<ScreenerDocument> presentations;

  bool get isEmpty =>
      announcements.isEmpty &&
      creditRatings.isEmpty &&
      transcripts.isEmpty &&
      presentations.isEmpty;

  factory ScreenerDocuments.fromAggregate(Map<String, dynamic> data) {
    return ScreenerDocuments(
      announcements: _asList(
        data['announcements'],
      ).map(ScreenerDocument.fromJson).toList(),
      creditRatings: _asList(
        data['credit-ratings'],
      ).map(ScreenerDocument.fromJson).toList(),
      transcripts: _asList(
        data['transcripts'],
      ).map(ScreenerDocument.fromJson).toList(),
      presentations: _asList(
        data['presentations'],
      ).map(ScreenerDocument.fromJson).toList(),
    );
  }
}

// ─── revenue segments ───────────────────────────────────────────────────────

class ScreenerSegmentEntry {
  const ScreenerSegmentEntry({required this.name, this.revenue, this.profit});

  final String name;
  final double? revenue;
  final double? profit;

  factory ScreenerSegmentEntry.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ScreenerSegmentEntry(
      name: _asString(json['name']) ?? '',
      revenue: data is Map
          ? _asDouble(data['segmentRevenue'])
          : _asDouble(json['revenue']),
      profit: data is Map
          ? _asDouble(data['segmentProfitLossBeforeTaxAndFinanceCosts'])
          : _asDouble(json['profit']),
    );
  }
}

class ScreenerSegmentPeriod {
  const ScreenerSegmentPeriod({required this.period, required this.segments});

  final String period;
  final List<ScreenerSegmentEntry> segments;

  factory ScreenerSegmentPeriod.fromJson(Map<String, dynamic> json) {
    final segments = <ScreenerSegmentEntry>[];
    // The API nests segment entries under a `segments` array, each with
    // `name` and `data` (containing segmentRevenue / segmentProfit...).
    for (final s in _asList(json['segments'])) {
      segments.add(ScreenerSegmentEntry.fromJson(s));
    }
    // Fallback: some responses may use flat key→value pairs.
    if (segments.isEmpty) {
      for (final key in json.keys) {
        if (key == 'header' ||
            key == 'year' ||
            key == 'symbol' ||
            key == 'data' ||
            key == 'segments') {
          continue;
        }
        final v = json[key];
        if (v is Map) {
          segments.add(
            ScreenerSegmentEntry(
              name: key,
              revenue: _asDouble(v['segmentRevenue'] ?? v['revenue']),
              profit: _asDouble(
                v['segmentProfitLossBeforeTaxAndFinanceCosts'] ?? v['profit'],
              ),
            ),
          );
        } else if (v is num) {
          segments.add(ScreenerSegmentEntry(name: key, revenue: _asDouble(v)));
        }
      }
    }
    return ScreenerSegmentPeriod(
      period: _asString(json['header']) ?? _asString(json['year']) ?? '',
      segments: segments,
    );
  }
}

class ScreenerSegments {
  const ScreenerSegments({required this.periods});

  final List<ScreenerSegmentPeriod> periods;

  bool get isEmpty => periods.isEmpty;

  /// Normalize a segment name for deduplication.
  /// Lowercases, replaces `&` with `and`, strips trailing/leading symbols
  /// (`*`, `^`, `#`, `~`, `@`, `!`, `?`), and collapses whitespace.
  static String normalizeSegmentName(String name) {
    return name
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[-_]'), ' ')
        .replaceAll(RegExp(r'[*^#~@!?]+$|^[*^#~@!?]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _hasTrailingSymbol(String s) {
    return RegExp(r'[*^#~@!?]+$').hasMatch(s.trim());
  }

  /// All unique segment names across all periods, preserving first-appearance
  /// order. Duplicate variants (e.g. `Chemicals` and `Chemicals*`) are merged
  /// into a single row, preferring the cleanest label.
  List<String> get segmentNames {
    final normalizedToLabel = <String, String>{};
    final seen = <String>{};
    final orderedKeys = <String>[];
    for (final p in periods) {
      for (final s in p.segments) {
        final key = normalizeSegmentName(s.name);
        if (!seen.contains(key)) {
          seen.add(key);
          orderedKeys.add(key);
          normalizedToLabel[key] = s.name;
        } else {
          final existing = normalizedToLabel[key]!;
          final existingDirty = _hasTrailingSymbol(existing);
          final newDirty = _hasTrailingSymbol(s.name);
          if (existingDirty && !newDirty) {
            normalizedToLabel[key] = s.name;
          } else if (existingDirty == newDirty &&
              s.name.length < existing.length) {
            normalizedToLabel[key] = s.name;
          }
        }
      }
    }
    return orderedKeys.map((k) => normalizedToLabel[k]!).toList();
  }

  /// Find a segment's revenue for a given period, merging duplicate variants
  /// by summing their values.
  double? segmentRevenue(ScreenerSegmentPeriod period, String displayName) {
    final key = normalizeSegmentName(displayName);
    var total = 0.0;
    var found = false;
    for (final s in period.segments) {
      if (normalizeSegmentName(s.name) == key) {
        if (s.revenue != null) {
          total += s.revenue!;
          found = true;
        }
      }
    }
    return found ? total : null;
  }

  /// Find a segment's profit for a given period, merging duplicate variants
  /// by summing their values.
  double? segmentProfit(ScreenerSegmentPeriod period, String displayName) {
    final key = normalizeSegmentName(displayName);
    var total = 0.0;
    var found = false;
    for (final s in period.segments) {
      if (normalizeSegmentName(s.name) == key) {
        if (s.profit != null) {
          total += s.profit!;
          found = true;
        }
      }
    }
    return found ? total : null;
  }

  factory ScreenerSegments.fromJson(Map<String, dynamic> json) {
    return ScreenerSegments(
      periods: _asList(
        json['segment_revenues'],
      ).map(ScreenerSegmentPeriod.fromJson).toList(),
    );
  }
}

// ─── ISIN ───────────────────────────────────────────────────────────────────

class ScreenerIsin {
  const ScreenerIsin({this.isin});

  final String? isin;

  /// Logo URL: `https://company-logo.shareperks.in/logo/{ISIN}/icon.svg`
  String? get logoUrl => isin != null && isin!.isNotEmpty
      ? 'https://company-logo.shareperks.in/logo/$isin/icon.svg'
      : null;

  factory ScreenerIsin.fromJson(Map<String, dynamic> json) {
    return ScreenerIsin(isin: _asString(json['isin']));
  }
}

// ─── aggregate company data ─────────────────────────────────────────────────

/// The aggregate `/api/company/:ticker` response, with all sections.
class ScreenerCompanyData {
  const ScreenerCompanyData({
    required this.ticker,
    required this.statementType,
    required this.profile,
    required this.quote,
    required this.basic,
    required this.ratios,
    required this.priceRatios,
    required this.financialMetrics,
    required this.chart,
    required this.shareholding,
    required this.peers,
    required this.corporateActions,
    required this.documents,
    required this.segments,
  });

  final String ticker;
  final String statementType;
  final ScreenerProfile profile;
  final ScreenerQuote quote;
  final ScreenerBasic basic;
  final ScreenerRatios ratios;
  final ScreenerPriceRatios priceRatios;
  final ScreenerFinancialMetrics financialMetrics;
  final ScreenerChart chart;
  final ScreenerShareholding shareholding;
  final ScreenerPeers peers;
  final ScreenerCorporateActions corporateActions;
  final ScreenerDocuments documents;
  final ScreenerSegments segments;

  bool get isStandalone => statementType == 's';

  /// Book value = currentPrice / pb (if pb > 0).
  double? get bookValue {
    final price = quote.currentPrice;
    final pb = priceRatios.annual.isNotEmpty
        ? priceRatios.annual.first.pb
        : priceRatios.entries.firstOrNull?.pb;
    if (price == null || pb == null || pb <= 0) return null;
    return price / pb;
  }

  /// Dividend yield = (last 12 months dividends / currentPrice) × 100.
  double? dividendYield(List<ScreenerDividend> dividends) {
    final price = quote.currentPrice;
    if (price == null || price <= 0) return null;
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    var total = 0.0;
    for (final d in dividends) {
      if (d.date == null || d.amount == null) continue;
      // Parse "DD-MMM-YY" format.
      final parsed = _parseDividendDate(d.date!);
      if (parsed != null && parsed.isAfter(oneYearAgo)) {
        total += d.amount!;
      }
    }
    if (total <= 0) return null;
    return (total / price) * 100;
  }

  static DateTime? _parseDividendDate(String dateStr) {
    const monthMap = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = monthMap[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final fullYear = year < 100 ? 2000 + year : year;
    return DateTime(fullYear, month, day);
  }

  factory ScreenerCompanyData.fromAggregate(
    Map<String, dynamic> json, {
    required ScreenerPeers peers,
  }) {
    final data = _asMap(json['data']);
    final ticker = _asString(json['ticker']) ?? '';

    return ScreenerCompanyData(
      ticker: ticker,
      statementType: _asString(json['statementType']) ?? 'c',
      profile: ScreenerProfile.fromJson(_asMap(data['profile'])),
      quote: ScreenerQuote.fromAggregate(_asMap(data['quote']), ticker),
      basic: ScreenerBasic.fromJson(_asMap(data['basic'])),
      ratios: ScreenerRatios.fromJson(_asMap(data['ratios'])),
      priceRatios: ScreenerPriceRatios.fromJson(_asMap(data['price-ratios'])),
      financialMetrics: ScreenerFinancialMetrics.fromJson(
        _asMap(data['metrics']),
      ),
      chart: ScreenerChart.fromJson(_asMap(data['historical-price']), ticker),
      shareholding: ScreenerShareholding.fromJson(_asMap(data['shareholding'])),
      peers: peers,
      corporateActions: ScreenerCorporateActions.fromAggregate(data),
      documents: ScreenerDocuments.fromAggregate(data),
      segments: ScreenerSegments.fromJson(_asMap(data['revenue-segment'])),
    );
  }
}
