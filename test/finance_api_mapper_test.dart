import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/repository/services/company/finance_api_mapper.dart';

/// Fetches live data from the finance API and verifies the mapper produces
/// well-formed model objects. Run with:
///   flutter test test/finance_api_mapper_test.dart
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

  group('finance API mapper — ITC', () {
    test('overview maps from aggregate profile + quote + basic', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final overview = mapOverview(
        Map<String, dynamic>.from(data['profile'] as Map),
        Map<String, dynamic>.from(data['quote'] as Map),
        Map<String, dynamic>.from(data['basic'] as Map),
        'ITC',
      );
      expect(overview.identity.symbol, 'ITC');
      expect(overview.identity.name, contains('ITC'));
      expect(overview.identity.sector, isNotNull);
      expect(overview.metrics.currentPrice, greaterThan(0));
      expect(overview.metrics.marketCapCr, greaterThan(0));
    });

    test('profit-loss maps to FinancialTable', () async {
      final pl = await getJson(
        '/api/company/ITC/profit-loss',
        query: {'statement_type': 'c'},
      );
      final table = mapStructuredStatement(
        pl,
        statement: StatementKind.pl,
        period: ReportPeriod.annual,
      );
      expect(table.statement, StatementKind.pl);
      expect(table.columns, isNotEmpty);
      expect(table.rows, isNotEmpty);
      expect(table.rows.first.values.length, table.columns.length);
      // First row should have at least one non-null value.
      expect(table.rows.first.values.any((v) => v != null), isTrue);
    });

    test('balance-sheet maps to FinancialTable', () async {
      final bs = await getJson(
        '/api/company/ITC/balance-sheet',
        query: {'statement_type': 'c'},
      );
      final table = mapStructuredStatement(
        bs,
        statement: StatementKind.bs,
        period: ReportPeriod.annual,
      );
      expect(table.statement, StatementKind.bs);
      expect(table.columns, isNotEmpty);
      expect(table.rows, isNotEmpty);
    });

    test('cash-flow maps to FinancialTable', () async {
      final cf = await getJson(
        '/api/company/ITC/cash-flow',
        query: {'statement_type': 'c'},
      );
      final table = mapCashFlow(cf);
      expect(table.statement, StatementKind.cf);
      expect(table.columns, isNotEmpty);
      expect(table.rows, isNotEmpty);
      expect(table.rows.first.values.length, table.columns.length);
    });

    test('quarterly maps to FinancialTable', () async {
      final q = await getJson(
        '/api/company/ITC/quarterly',
        query: {'statement_type': 'c'},
      );
      final table = mapStructuredStatement(
        q,
        statement: StatementKind.pl,
        period: ReportPeriod.quarterly,
      );
      expect(table.period, ReportPeriod.quarterly);
      expect(table.columns, isNotEmpty);
      expect(table.rows, isNotEmpty);
    });

    test('peers maps to PeerComparison', () async {
      final peers = await getJson('/api/company/ITC/peers');
      final comparison = mapPeers(peers, 'ITC');
      expect(comparison.peers, isNotEmpty);
      expect(comparison.self, isNotNull);
      expect(comparison.self!.symbol, 'ITC');
    });

    test('shareholding maps from aggregate', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final sh = mapShareholding(
        Map<String, dynamic>.from(data['shareholding'] as Map),
      );
      expect(sh.columns, isNotEmpty);
      expect(sh.categories, isNotEmpty);
    });

    test('chart maps from aggregate historical-price', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final chart = mapChart(
        Map<String, dynamic>.from(data['historical-price'] as Map),
        'ITC',
      );
      expect(chart.points, isNotEmpty);
      expect(
        chart.points.first.date.compareTo(chart.points.last.date),
        lessThan(0),
      );
    });

    test('documents map from aggregate', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final docs = mapDocuments(Map<String, dynamic>.from(data));
      expect(docs.announcements, isNotEmpty);
    });

    test('corporate actions map from aggregate', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final data = agg['data'] as Map;
      final actions = mapCorporateActions(Map<String, dynamic>.from(data));
      expect(actions.dividends, isNotEmpty);
    });

    test('full CompanyPage assembles correctly', () async {
      final agg = await getJson(
        '/api/company/ITC',
        query: {'statement_type': 'c'},
      );
      final pl = await getJson(
        '/api/company/ITC/profit-loss',
        query: {'statement_type': 'c'},
      );
      final bs = await getJson(
        '/api/company/ITC/balance-sheet',
        query: {'statement_type': 'c'},
      );
      final cf = await getJson(
        '/api/company/ITC/cash-flow',
        query: {'statement_type': 'c'},
      );
      final q = await getJson(
        '/api/company/ITC/quarterly',
        query: {'statement_type': 'c'},
      );
      final peers = await getJson('/api/company/ITC/peers');

      final page = mapCompanyPage(
        aggregate: agg,
        profitAndLoss: mapStructuredStatement(
          pl,
          statement: StatementKind.pl,
          period: ReportPeriod.annual,
        ),
        quarterlyResults: mapStructuredStatement(
          q,
          statement: StatementKind.pl,
          period: ReportPeriod.quarterly,
        ),
        balanceSheet: mapStructuredStatement(
          bs,
          statement: StatementKind.bs,
          period: ReportPeriod.annual,
        ),
        cashFlow: mapCashFlow(cf),
        peers: mapPeers(peers, 'ITC'),
      );

      expect(page.overview.identity.symbol, 'ITC');
      expect(page.profitAndLoss, isNotNull);
      expect(page.profitAndLoss!.rows, isNotEmpty);
      expect(page.quarterlyResults, isNotNull);
      expect(page.balanceSheet, isNotNull);
      expect(page.cashFlow, isNotNull);
      expect(page.peers, isNotNull);
      expect(page.peers!.peers, isNotEmpty);
    });
  });
}
