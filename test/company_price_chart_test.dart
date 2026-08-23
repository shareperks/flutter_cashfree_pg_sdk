import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shareperks/components/company/company_price_chart.dart';
import 'package:shareperks/repository/models/company_data_model.dart';

/// A synthetic session series shaped like the service's: a wobbling close, and
/// moving averages that only start once there is enough history behind them.
List<PricePoint> _series(int days) {
  final random = math.Random(7);
  var close = 250.0;
  final points = <PricePoint>[];
  var date = DateTime.utc(2013, 1, 1);

  for (var i = 0; i < days; i++) {
    close = (close + random.nextDouble() * 6 - 3).clamp(20.0, 5000.0);
    date = date.add(const Duration(days: 1));
    points.add(
      PricePoint(
        date: date.toIso8601String().split('T').first,
        close: close,
        dma50: i >= 50 ? close * 0.98 : null,
        dma200: i >= 200 ? close * 0.95 : null,
      ),
    );
  }
  return points;
}

Widget _host(CompanyChart? chart, {bool loading = false, String? error}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: CompanyPriceChart(
            chart: chart,
            loading: loading,
            error: error,
            activeRange: CompanyChartRange.all.first,
            onSelectRange: (_) {},
            onRetry: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('downsamplePriceSeries', () {
    test('keeps a short series untouched', () {
      final points = _series(40);
      expect(downsamplePriceSeries(points, 260), hasLength(40));
    });

    test('drops a long series to the threshold, endpoints intact', () {
      final points = _series(3400);
      final sampled = downsamplePriceSeries(points, 260);

      expect(sampled, hasLength(260));
      expect(sampled.first.date, points.first.date);
      expect(sampled.last.date, points.last.date);
    });

    test('keeps sessions in chronological order without repeats', () {
      final sampled = downsamplePriceSeries(_series(3400), 260);
      final dates = [for (final p in sampled) p.date];

      expect(dates, equals([...dates]..sort()));
      expect(dates.toSet(), hasLength(dates.length));
    });

    test('preserves the shape either side of a spike', () {
      // A single-session crash an even stride would step straight over.
      final points = [..._series(1200)];
      final crash = points[600];
      points[600] = PricePoint(date: crash.date, close: 5.0);

      final sampled = downsamplePriceSeries(points, 120);
      final lowest = sampled
          .map((p) => p.close!)
          .reduce((a, b) => a < b ? a : b);

      expect(lowest, 5.0);
    });

    test('skips sessions with no close', () {
      final points = [
        PricePoint(date: '2026-01-01', close: 10),
        const PricePoint(date: '2026-01-02'),
        PricePoint(date: '2026-01-03', close: 12),
      ];

      expect(downsamplePriceSeries(points, 260), hasLength(2));
    });
  });

  group('CompanyPriceChart', () {
    testWidgets('draws the three series for a full history', (tester) async {
      await tester.pumpWidget(
        _host(CompanyChart(symbol: 'ITC', points: _series(3400))),
      );
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData, hasLength(3));
      // Resampled, not the 3,400 sessions the service returned.
      expect(chart.data.lineBarsData.last.spots, hasLength(260));
      expect(find.text('50 DMA'), findsOneWidget);
    });

    testWidgets('leaves gaps where a moving average has no history yet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(CompanyChart(symbol: 'ITC', points: _series(260))),
      );
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final dma200 = chart.data.lineBarsData.first.spots;

      expect(dma200.first.isNull(), isTrue);
      expect(dma200.last.isNull(), isFalse);
    });

    testWidgets('scrubbing moves the readout to the touched session', (
      tester,
    ) async {
      final points = _series(400);
      await tester.pumpWidget(
        _host(CompanyChart(symbol: 'ITC', points: points)),
      );
      await tester.pumpAndSettle();

      // Before any touch the readout is the latest session.
      expect(find.text(_expectedDate(points.last.date)), findsOneWidget);

      final chart = find.byType(LineChart);
      final box = tester.getRect(chart);
      final gesture = await tester.startGesture(
        Offset(box.left + box.width * 0.25, box.center.dy),
      );
      await tester.pumpAndSettle();

      expect(find.text(_expectedDate(points.last.date)), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();

      // Releasing hands the readout back to the latest session.
      expect(find.text(_expectedDate(points.last.date)), findsOneWidget);
    });

    testWidgets('scrubbing draws a full-height line at the touched session', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(CompanyChart(symbol: 'ITC', points: _series(400))),
      );
      await tester.pumpAndSettle();

      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      final touch = data.lineTouchData;
      final closeBar = data.lineBarsData.last;
      final dmaBar = data.lineBarsData.first;

      // The chart lerps its data every frame, so the painter calls back with a
      // copy of the bar — never the instance the widget built. Anything that
      // matches on identity silently draws nothing.
      final lerped = closeBar.copyWith();
      expect(identical(lerped, closeBar), isFalse);

      final indicator = touch.getTouchedSpotIndicator(lerped, [0]).single;
      expect(indicator, isNotNull);
      expect(indicator!.indicatorBelowLine.color, isNot(Colors.transparent));
      expect(indicator.indicatorBelowLine.color!.a, greaterThan(0));
      expect(indicator.touchedSpotDotData.show, isTrue);

      // Top to bottom of the plot, not axis-to-spot.
      expect(touch.getTouchLineStart(lerped, 0), data.minY);
      expect(touch.getTouchLineEnd(lerped, 0), data.maxY);

      // The moving averages stay unmarked.
      expect(
        touch.getTouchedSpotIndicator(dmaBar.copyWith(), [0]).single,
        isNull,
      );

      // Nothing draws left to right across the plot.
      expect(data.extraLinesData.horizontalLines, isEmpty);
    });

    testWidgets('animates between ranges of different lengths', (tester) async {
      // Switching 1Y → Max hands fl_chart two spot lists of different lengths
      // to lerp between; this is the frame where that goes wrong if it does.
      await tester.pumpWidget(
        _host(CompanyChart(symbol: 'ITC', points: _series(240))),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _host(CompanyChart(symbol: 'ITC', points: _series(3400))),
      );
      await tester.pump(const Duration(milliseconds: 110));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.last.spots, hasLength(260));
    });

    testWidgets('renders states instead of a chart when there is no data', (
      tester,
    ) async {
      await tester.pumpWidget(_host(null, loading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(_host(null, error: 'Upstream is down'));
      await tester.pumpAndSettle();
      expect(find.text('Upstream is down'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);

      await tester.pumpWidget(
        _host(CompanyChart(symbol: 'ITC', points: _series(1))),
      );
      await tester.pumpAndSettle();
      expect(find.text('No price history for this range.'), findsOneWidget);
    });
  });
}

/// `2013-01-02` → `2 Jan 2013`, matching `fmtIsoDate`.
String _expectedDate(String iso) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final parts = iso.split('-');
  return '${int.parse(parts[2])} ${months[int.parse(parts[1]) - 1]} ${parts[0]}';
}
