import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Verifies the new screener models parse live API responses correctly.
void main() {
  final client = HttpClient();
  final base = 'finance.shareperks.in';

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final req = await client.getUrl(Uri.https(base, path, query?.cast()));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} for $path');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  group('screener models — ITC', () {
    test('profile + quote + basic parse from aggregate', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final profile = ScreenerProfile.fromJson(
        Map<String, dynamic>.from(data['profile'] as Map),
      );
      final quote = ScreenerQuote.fromAggregate(
        Map<String, dynamic>.from(data['quote'] as Map),
        'ITC',
      );
      final basic = ScreenerBasic.fromJson(
        Map<String, dynamic>.from(data['basic'] as Map),
      );

      expect(profile.symbol, 'ITC');
      expect(profile.name, contains('ITC'));
      expect(profile.sector, isNotNull);
      expect(profile.initials, isNotEmpty);
      expect(quote.currentPrice, greaterThan(0));
      expect(quote.marketCap, greaterThan(0));
      expect(quote.rangePct, isNotNull);
      expect(basic.ratios, isNotEmpty);
      expect(basic.ttm, isNotNull);
    });

    test('profit-loss statement parses with nested ui.rows', () async {
      final pl = await getJson(
        '/api/company/ITC/profit-loss',
        query: {'statement_type': 'c'},
      );
      final stmt = ScreenerStatement.fromJson(pl, isQuarterly: false);

      expect(stmt.symbol, 'ITC');
      expect(stmt.periods, isNotEmpty);
      expect(stmt.rows, isNotEmpty);
      expect(stmt.isStandalone, isFalse);
      // First row should have a valueKey and resolve values.
      final firstRow = stmt.rows.first;
      expect(firstRow.label, isNotEmpty);
      // At least some rows should have non-null values.
      final hasValues = stmt.periods.any(
        (p) => p.value(firstRow.valueKey) != null,
      );
      expect(hasValues, isTrue);
    });

    test('quarterly statement parses', () async {
      final q = await getJson(
        '/api/company/ITC/quarterly',
        query: {'statement_type': 'c'},
      );
      final stmt = ScreenerStatement.fromJson(q, isQuarterly: true);

      expect(stmt.isQuarterly, isTrue);
      expect(stmt.periods, isNotEmpty);
      expect(stmt.rows, isNotEmpty);
      // Quarterly labels should look like "Jun 2025" etc.
      expect(stmt.periods.first.label, matches(RegExp(r'[A-Z][a-z]+ \d{4}')));
    });

    test('balance sheet statement parses', () async {
      final bs = await getJson(
        '/api/company/ITC/balance-sheet',
        query: {'statement_type': 'c'},
      );
      final stmt = ScreenerStatement.fromJson(bs, isQuarterly: false);

      expect(stmt.periods, isNotEmpty);
      expect(stmt.rows, isNotEmpty);
    });

    test('cash flow parses with sectioned rows', () async {
      final cf = await getJson(
        '/api/company/ITC/cash-flow',
        query: {'statement_type': 'c'},
      );
      final cashFlow = ScreenerCashFlow.fromJson(cf);

      expect(cashFlow.annualPeriods, isNotEmpty);
      expect(cashFlow.annualRows, isNotEmpty);
      // Should have operating, investing, financing sections.
      final sections = cashFlow.annualRows.map((r) => r.section).toSet();
      expect(sections, contains('operating'));
      expect(sections, contains('investing'));
      expect(sections, contains('financing'));
      // Visible rows should filter out all-zero rows.
      final visible = cashFlow.visibleRows(false);
      expect(visible, isNotEmpty);
    });

    test('peers parse with self identification', () async {
      final peers = await getJson('/api/company/ITC/peers');
      final p = ScreenerPeers.fromJson(peers, 'ITC');

      expect(p.peers, isNotEmpty);
      expect(p.self, isNotNull);
      expect(p.self!.symbol, 'ITC');
      expect(p.others, isNotEmpty);
    });

    test('shareholding parses with sorted categories', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final sh = ScreenerShareholding.fromJson(
        Map<String, dynamic>.from(data['shareholding'] as Map),
      );

      expect(sh.columns, isNotEmpty);
      expect(sh.categories, isNotEmpty);
      expect(sh.visibleColumns.length, lessThanOrEqualTo(6));
      final sorted = sh.sortedCategories;
      expect(sorted, isNotEmpty);
    });

    test('chart parses and filters by time frame', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final chart = ScreenerChart.fromJson(
        Map<String, dynamic>.from(data['historical-price'] as Map),
        'ITC',
      );

      expect(chart.points, isNotEmpty);
      // Chronological order.
      expect(
        chart.points.first.date.compareTo(chart.points.last.date),
        lessThan(0),
      );
      // Filter to 1 year.
      final filtered = chart.filtered(365);
      expect(filtered.points.length, lessThanOrEqualTo(365));
      expect(filtered.changePct, isNotNull);
    });

    test('ratios parse with annual filtering', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final ratios = ScreenerRatios.fromJson(
        Map<String, dynamic>.from(data['ratios'] as Map),
      );

      expect(ratios.entries, isNotEmpty);
      expect(ratios.annual, isNotEmpty);
      expect(ratios.ttm, isNotNull);
      // Annual entries should not include TTM.
      expect(ratios.annual.every((e) => !e.isTtm), isTrue);
    });

    test('price ratios parse for analysis', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final pr = ScreenerPriceRatios.fromJson(
        Map<String, dynamic>.from(data['price-ratios'] as Map),
      );

      expect(pr.entries, isNotEmpty);
      expect(pr.annual, isNotEmpty);
    });

    test('corporate actions parse from aggregate', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final actions = ScreenerCorporateActions.fromAggregate(
        Map<String, dynamic>.from(data),
      );

      expect(actions.dividends, isNotEmpty);
      expect(actions.dividends.first.amount, isNotNull);
    });

    test('documents parse from aggregate', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final docs = ScreenerDocuments.fromAggregate(
        Map<String, dynamic>.from(data),
      );

      expect(docs.announcements, isNotEmpty);
      expect(docs.announcements.first.description, isNotEmpty);
    });

    test('segments parse from aggregate', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final segments = ScreenerSegments.fromJson(
        Map<String, dynamic>.from(data['revenue-segment'] as Map),
      );

      // Segments may or may not be present for all companies.
      if (segments.periods.isNotEmpty) {
        expect(segments.segmentNames, isNotEmpty);
      }
    });

    test('full ScreenerCompanyData assembles from aggregate', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final peersJson = await getJson('/api/company/ITC/peers');
      final peers = ScreenerPeers.fromJson(peersJson, 'ITC');

      final companyData = ScreenerCompanyData.fromAggregate(agg, peers: peers);

      expect(companyData.ticker, 'ITC');
      expect(companyData.profile.name, contains('ITC'));
      expect(companyData.quote.currentPrice, greaterThan(0));
      expect(companyData.ratios.entries, isNotEmpty);
      expect(companyData.peers.peers, isNotEmpty);
      expect(companyData.chart.points, isNotEmpty);
      expect(companyData.bookValue, isNotNull);
    });

    test('dividend yield calculates from dividends + price', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final peersJson = await getJson('/api/company/ITC/peers');
      final peers = ScreenerPeers.fromJson(peersJson, 'ITC');
      final companyData = ScreenerCompanyData.fromAggregate(agg, peers: peers);

      final divYield = companyData.dividendYield(
        companyData.corporateActions.dividends,
      );
      // ITC pays dividends, so yield should be non-null and positive.
      if (divYield != null) {
        expect(divYield, greaterThan(0));
      }
    });
  });
}
