/// Maps the Finance / Screener API (`finance.shareperks.in`) responses into the
/// existing [CompanyPage] / [FinancialTable] / … models that the company
/// details screen and its components already consume.
///
/// The finance API returns structured data with a different shape than the old
/// `localhost:4003` service:
/// - Statements come as `lineItems` + `annualFinancials[].display` (P&L,
///   quarterly) or `ui.rows` + `annualFinancials[].display` (balance sheet) or
///   `rows[].values` keyed by period (cash flow).
/// - This file pivots those into the flat `columns` + `rows[].values` layout
///   [FinancialTable] expects.
library;

import 'package:shareperks/repository/models/company_data_model.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

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

Consolidation _consolidation(String? value) =>
    value == 's' ? Consolidation.standalone : Consolidation.consolidated;

// ─── structured statement → FinancialTable ──────────────────────────────────

/// Maps a `/profit-loss` or `/quarterly` structured response into a
/// [FinancialTable].
///
/// Uses `lineItems` (P&L) or `ui.rows` (quarterly / balance sheet) for row
/// definitions, and `annualFinancials[].display` / `quarters[].display` for
/// values.
FinancialTable mapStructuredStatement(
  Map<String, dynamic> json, {
  required StatementKind statement,
  required ReportPeriod period,
}) {
  final consolidation = _consolidation(json['consolidationType'] as String?);

  // Row definitions: prefer `lineItems` (P&L), fall back to `ui.rows`.
  final lineItems = _asList(json['lineItems']);
  final uiRows = _asList((json['ui'] as Map?)?['rows']);
  final rowDefs = lineItems.isNotEmpty ? lineItems : uiRows;

  // Period objects: `annualFinancials` (P&L / BS) or `quarters` (quarterly).
  final periodsRaw = _asList(json['annualFinancials']);
  final quartersRaw = _asList(json['quarters']);
  final periods = periodsRaw.isNotEmpty ? periodsRaw : quartersRaw;

  if (rowDefs.isEmpty || periods.isEmpty) {
    return FinancialTable(
      statement: statement,
      period: period,
      consolidation: consolidation,
      columns: const [],
      rows: const [],
    );
  }

  // Column labels: `fiscalYear` (annual) or `period.quarter` (quarterly).
  final columns = <String>[];
  for (final p in periods) {
    final fy = p['fiscalYear'] as String?;
    final quarterPeriod = p['period'];
    final quarterLabel = quarterPeriod is Map
        ? quarterPeriod['quarter'] as String?
        : null;
    columns.add(fy ?? quarterLabel ?? '');
  }

  // Build rows: for each row def, collect values across all periods.
  final rows = <FinancialRow>[];
  for (final def in rowDefs) {
    final key = def['key'] as String? ?? def['id'] as String? ?? '';
    final label = def['label'] as String? ?? '';
    final valueKey = def['valueKey'] as String?;
    // For `lineItems`, the key IS the display key. For `ui.rows`, use
    // `valueKey` (dot-path like `display.revenue`).
    final displayKey = valueKey != null ? valueKey.split('.').last : key;

    final values = <double?>[];
    for (final p in periods) {
      final display = p['display'];
      if (display is Map) {
        values.add(asDouble(display[displayKey]));
      } else {
        values.add(null);
      }
    }

    rows.add(
      FinancialRow(
        key: key,
        label: label,
        values: values,
        unit: FinancialUnit.cr,
      ),
    );
  }

  return FinancialTable(
    statement: statement,
    period: period,
    consolidation: consolidation,
    columns: columns,
    rows: rows,
  );
}

/// Maps a `/cash-flow` response into a [FinancialTable].
///
/// Cash flow has a different shape: `annual.rows[].values` is a map keyed by
/// period label, not a flat array. We convert it to positional arrays aligned
/// with `annual.periods`.
FinancialTable mapCashFlow(Map<String, dynamic> json) {
  final consolidation = _consolidation(json['consolidationType'] as String?);
  final annual = _asMap(json['annual']);
  final periods =
      (annual['periods'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];
  final rawRows = _asList(annual['rows']);

  if (periods.isEmpty || rawRows.isEmpty) {
    return FinancialTable(
      statement: StatementKind.cf,
      period: ReportPeriod.annual,
      consolidation: consolidation,
      columns: const [],
      rows: const [],
    );
  }

  final rows = <FinancialRow>[];
  for (final r in rawRows) {
    final valuesMap = r['values'];
    final values = <double?>[];
    if (valuesMap is Map) {
      for (final col in periods) {
        values.add(asDouble(valuesMap[col]));
      }
    }
    rows.add(
      FinancialRow(
        key: r['id'] as String? ?? r['label'] as String? ?? '',
        label: r['label'] as String? ?? '',
        values: values,
        unit: FinancialUnit.cr,
      ),
    );
  }

  return FinancialTable(
    statement: StatementKind.cf,
    period: ReportPeriod.annual,
    consolidation: consolidation,
    columns: periods,
    rows: rows,
  );
}

// ─── aggregate → CompanyOverview ────────────────────────────────────────────

/// Maps `profile` + `quote` + `basic` from the aggregate response into
/// [CompanyOverview].
CompanyOverview mapOverview(
  Map<String, dynamic> profile,
  Map<String, dynamic> quote,
  Map<String, dynamic> basic,
  String ticker,
) {
  // Quote is keyed by symbol: `{ "ITC": { current_price, ... } }`.
  final quoteData = quote[ticker] is Map
      ? _asMap(quote[ticker])
      : quote.isNotEmpty && quote.values.first is Map
      ? _asMap(quote.values.first)
      : const <String, dynamic>{};

  // Basic ratios: first entry is TTM.
  final basicRatios = _asList(basic['ratios']);
  final ttm = basicRatios.isNotEmpty
      ? basicRatios.first
      : const <String, dynamic>{};

  // Parse change percentage from string like "0.02%".
  final changeStr = quoteData['change'] as String?;
  final changePct = changeStr != null
      ? double.tryParse(changeStr.replaceAll('%', ''))
      : null;

  return CompanyOverview(
    identity: CompanyIdentity(
      symbol: profile['symbol'] as String? ?? ticker,
      name: profile['name'] as String? ?? ticker,
      nseCode: profile['nse_code'] as String?,
      bseCode: profile['bse_code'] as String?,
      sector: profile['sector'] as String?,
      industry: profile['industry'] as String?,
      subIndustry: profile['sub_industry'] as String?,
      macroSector: profile['macro_sector'] as String?,
      website: profile['website'] as String?,
      about: profile['description'] as String?,
    ),
    metrics: CompanyKeyMetrics(
      currentPrice: asDouble(quoteData['current_price']),
      changePct: changePct,
      marketCapCr: asDouble(quoteData['market_cap']),
      high52: asDouble(quoteData['high52']),
      low52: asDouble(quoteData['low52']),
      sharesOutstanding: asDouble(quoteData['shares']),
      lastTradedAt: quoteData['tradetime'] as String?,
      // Derived from basic ratios where available.
      stockPe: _safeDiv(
        asDouble(quoteData['current_price']),
        asDouble(ttm['eps']),
      ),
      bookValue: _safeDiv(
        asDouble(ttm['adjustedEquityShareCapital']),
        asDouble(ttm['dilutedSharesOutstanding']),
      ),
      faceValue: asDouble(ttm['adjustedFaceValue']),
    ),
    pros: const [],
    cons: const [],
  );
}

double? _safeDiv(double? a, double? b) {
  if (a == null || b == null || b == 0) return null;
  return a / b;
}

// ─── aggregate → ratios FinancialTable ──────────────────────────────────────

/// Maps `ratios.ratios[]` from the aggregate into a [FinancialTable].
/// Ratio values are decimals (0.27 = 27%) — converted to percentages.
FinancialTable mapRatios(Map<String, dynamic> ratiosData) {
  final entries = _asList(ratiosData['ratios']);
  if (entries.isEmpty) {
    return const FinancialTable(
      statement: StatementKind.pl,
      period: ReportPeriod.annual,
      consolidation: Consolidation.consolidated,
      columns: [],
      rows: [],
    );
  }

  final columns = entries
      .map((e) => e['header'] as String? ?? e['year']?.toString() ?? '')
      .toList();

  // Collect all ratio field names (excluding header/year).
  final ratioKeys = <String>[];
  final seen = <String>{};
  for (final e in entries) {
    for (final key in e.keys) {
      if (key == 'header' || key == 'year') continue;
      if (seen.add(key)) ratioKeys.add(key);
    }
  }

  final rows = <FinancialRow>[];
  for (final rk in ratioKeys) {
    final values = <double?>[];
    for (final e in entries) {
      final v = asDouble(e[rk]);
      // Convert decimal to percentage (0.2711 → 27.11).
      values.add(v != null ? v * 100 : null);
    }
    rows.add(
      FinancialRow(
        key: rk,
        label: _ratioLabel(rk),
        values: values,
        unit: FinancialUnit.pct,
      ),
    );
  }

  return FinancialTable(
    statement: StatementKind.pl,
    period: ReportPeriod.annual,
    consolidation: Consolidation.consolidated,
    columns: columns,
    rows: rows,
  );
}

String _ratioLabel(String key) => switch (key) {
  'operatingMargin' => 'Operating Margin',
  'netMargin' => 'Net Margin',
  'grossMargin' => 'Gross Margin',
  'ebitMargin' => 'EBIT Margin',
  'ebitdaMargin' => 'EBITDA Margin',
  'preTaxMargin' => 'Pre-Tax Margin',
  'returnOnEquity' => 'Return on Equity',
  'returnOnCapital' => 'Return on Capital',
  'returnOnAsset' => 'Return on Asset',
  'returnOnTangibleAssets' => 'Return on Tangible Assets',
  'effectiveTaxRate' => 'Effective Tax Rate',
  _ => key,
};

// ─── aggregate → CompanyShareholding ────────────────────────────────────────

CompanyShareholding mapShareholding(Map<String, dynamic> json) {
  final columns =
      (json['columns'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];
  final rawRows = _asList(json['rows']);

  final categories = <ShareholdingCategory>[];
  for (final r in rawRows) {
    final data = r['data'];
    final values = <String, double?>{};
    if (data is Map) {
      data.forEach((k, v) => values[k.toString()] = asDouble(v));
    }
    final holders = <ShareholdingCategory>[];
    for (final h in _asList(r['shareholders'])) {
      final hData = h['data'];
      final hValues = <String, double?>{};
      if (hData is Map) {
        hData.forEach((k, v) => hValues[k.toString()] = asDouble(v));
      }
      holders.add(
        ShareholdingCategory(
          name: h['name'] as String? ?? '',
          values: hValues,
          holders: const [],
        ),
      );
    }
    categories.add(
      ShareholdingCategory(
        name: r['name'] as String? ?? '',
        category: r['catagory'] as String?,
        values: values,
        holders: holders,
      ),
    );
  }

  return CompanyShareholding(
    period: ReportPeriod.quarterly,
    columns: columns,
    categories: categories,
    pledge: const [],
  );
}

// ─── /peers → PeerComparison ────────────────────────────────────────────────

PeerComparison mapPeers(Map<String, dynamic> json, String ticker) {
  final rawPeers = _asList(json['peers']);
  PeerRow? self;
  final peers = <PeerRow>[];

  for (final p in rawPeers) {
    final symbol = p['symbol'] as String? ?? '';
    final roe = asDouble(p['roe']);
    final opm = asDouble(p['opm']);
    final row = PeerRow(
      symbol: symbol,
      name: p['name'] as String?,
      currentPrice: asDouble(p['cmp']),
      changePct: _parseChangePct(p['change'] as String?),
      marketCapCr: asDouble(p['marketCap']),
      pe: asDouble(p['pe']),
      priceToBook: asDouble(p['pb']),
      // roe / opm are decimals (0.27 = 27%) — convert to percentage.
      roePct: roe != null ? roe * 100 : null,
      opmPct: opm != null ? opm * 100 : null,
    );
    if (symbol.toUpperCase() == ticker.toUpperCase()) {
      self = row;
    } else {
      peers.add(row);
    }
  }

  return PeerComparison(group: 'sector', self: self, peers: peers);
}

double? _parseChangePct(String? change) {
  if (change == null) return null;
  return double.tryParse(change.replaceAll('%', ''));
}

// ─── aggregate → CompanyChart ───────────────────────────────────────────────

CompanyChart mapChart(Map<String, dynamic> json, String symbol) {
  final prices = _asList(json['price']);
  final points = <PricePoint>[];
  for (final p in prices) {
    points.add(
      PricePoint(
        date: p['quote_date'] as String? ?? '',
        open: asDouble(p['open_price']),
        high: asDouble(p['high_price']),
        low: asDouble(p['low_price']),
        close: asDouble(p['close_price']),
        volume: asDouble(p['volume']),
      ),
    );
  }
  // API returns newest-first; chart expects chronological order.
  points.sort((a, b) => a.date.compareTo(b.date));

  return CompanyChart(
    symbol: symbol,
    from: points.isNotEmpty ? points.first.date : null,
    to: points.isNotEmpty ? points.last.date : null,
    points: points,
  );
}

// ─── aggregate → CompanyDocuments ───────────────────────────────────────────

CompanyDocuments mapDocuments(Map<String, dynamic> data) {
  return CompanyDocuments(
    announcements: _mapDocItems(data['announcements']),
    callTranscripts: _mapDocItems(data['transcripts']),
    presentations: _mapDocItems(data['presentations']),
    creditRatings: _mapDocItems(data['credit-ratings']),
  );
}

List<DocumentItem> _mapDocItems(dynamic value) {
  final items = _asList(value);
  return items
      .map(
        (e) => DocumentItem(
          title: e['description'] as String? ?? e['category'] as String? ?? '',
          category: e['category'] as String?,
          date: e['announcement_date'] as String?,
          url: e['pdf_file_link'] as String?,
        ),
      )
      .toList();
}

// ─── aggregate → CompanyCorporateActions ────────────────────────────────────

CompanyCorporateActions mapCorporateActions(Map<String, dynamic> data) {
  return CompanyCorporateActions(
    dividends: _mapActions(data['dividends']?['dividend']),
    splits: _mapActions(data['splits']?['split']),
    bonuses: _mapActions(data['bonuses']?['bonus']),
    rights: _mapActions(data['rights']?['rights']),
  );
}

List<CorporateActionItem> _mapActions(dynamic value) {
  final items = _asList(value);
  return items
      .map(
        (e) => CorporateActionItem(
          type:
              e['dividend_type'] as String? ??
              e['split_type'] as String? ??
              e['bonus_type'] as String? ??
              e['rights_type'] as String? ??
              '',
          detail: e['subject'] as String?,
          date: e['date'] as String?,
          amount: asDouble(e['adj_amount'] ?? e['amount']),
        ),
      )
      .toList();
}

// ─── aggregate → CompanyPage ────────────────────────────────────────────────

/// Builds a [CompanyPage] from the aggregate `/api/company/:ticker` response
/// plus separately-fetched structured statements and peers.
CompanyPage mapCompanyPage({
  required Map<String, dynamic> aggregate,
  required FinancialTable? profitAndLoss,
  required FinancialTable? quarterlyResults,
  required FinancialTable? balanceSheet,
  required FinancialTable? cashFlow,
  required PeerComparison? peers,
}) {
  final data = _asMap(aggregate['data']);
  final ticker = aggregate['ticker'] as String? ?? '';

  final overview = mapOverview(
    _asMap(data['profile']),
    _asMap(data['quote']),
    _asMap(data['basic']),
    ticker,
  );

  final ratiosTable = data['ratios'] is Map
      ? mapRatios(_asMap(data['ratios']))
      : null;
  final shareholding = data['shareholding'] is Map
      ? mapShareholding(_asMap(data['shareholding']))
      : null;

  return CompanyPage(
    overview: overview,
    profitAndLoss: profitAndLoss,
    quarterlyResults: quarterlyResults,
    balanceSheet: balanceSheet,
    cashFlow: cashFlow,
    ratios: ratiosTable,
    growth: null, // Not directly available in the finance API.
    shareholding: shareholding,
    peers: peers,
    unavailable: const [],
  );
}
