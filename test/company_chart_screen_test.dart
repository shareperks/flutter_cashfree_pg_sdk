import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/screens/main/CompanyChartScreen.dart';

/// Sessions shaped like the service's: OHLC plus volume, with the moving
/// averages only starting once there is history behind them.
List<PricePoint> _series(int days) {
  final random = math.Random(11);
  var close = 250.0;
  var date = DateTime.utc(2024, 1, 1);
  final points = <PricePoint>[];

  for (var i = 0; i < days; i++) {
    close = (close + random.nextDouble() * 8 - 4).clamp(20.0, 5000.0);
    date = date.add(const Duration(days: 1));
    points.add(
      PricePoint(
        date: date.toIso8601String().split('T').first,
        open: close * 0.99,
        high: close * 1.02,
        low: close * 0.97,
        close: close,
        volume: 1000000 + random.nextInt(500000).toDouble(),
        dma50: i >= 50 ? close * 0.98 : null,
        dma200: i >= 200 ? close * 0.95 : null,
      ),
    );
  }
  return points;
}

Widget _host(List<PricePoint> points) {
  return MaterialApp(
    home: CompanyChartScreen(
      symbol: 'ITC',
      name: 'ITC Ltd',
      initial: CompanyChart(symbol: 'ITC', points: points),
      initialYears: 1,
    ),
  );
}

void main() {
  group('trimToWindow', () {
    final points = _series(400);

    test('keeps everything when no day count is given', () {
      expect(trimToWindow(points, null), hasLength(400));
    });

    test('cuts a year down to the last month', () {
      final trimmed = trimToWindow(points, 31);

      expect(trimmed.length, lessThan(40));
      expect(trimmed.last.date, points.last.date);

      final first = DateTime.parse(trimmed.first.date);
      final last = DateTime.parse(trimmed.last.date);
      expect(last.difference(first).inDays, lessThanOrEqualTo(31));
    });

    test('leaves a series shorter than the window alone', () {
      expect(trimToWindow(_series(10), 183), hasLength(10));
    });
  });

  group('CompanyChartScreen', () {
    testWidgets('opens drawn from the series it was handed', (tester) async {
      await tester.pumpWidget(_host(_series(400)));
      await tester.pumpAndSettle();

      // No spinner: the caller's fetch was reused, not repeated.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('ITC Ltd'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);

      // Price pane plus volume pane.
      expect(find.byType(LineChart), findsNWidgets(2));
    });

    testWidgets('price and volume panes zoom together', (tester) async {
      await tester.pumpWidget(_host(_series(400)));
      await tester.pumpAndSettle();

      final charts = tester
          .widgetList<LineChart>(find.byType(LineChart))
          .toList();
      final price = charts.first.transformationConfig;
      final volume = charts.last.transformationConfig;

      expect(price.scaleAxis, FlScaleAxis.horizontal);
      expect(volume.scaleAxis, FlScaleAxis.horizontal);
      // One controller drives both, which is what keeps the two panes on the
      // same sessions after a pinch.
      expect(
        identical(
          price.transformationController,
          volume.transformationController,
        ),
        isTrue,
      );
      expect(charts.first.data.maxX, charts.last.data.maxX);
    });

    testWidgets('series toggles add and remove lines', (tester) async {
      await tester.pumpWidget(_host(_series(400)));
      await tester.pumpAndSettle();

      LineChartData price() =>
          tester.widgetList<LineChart>(find.byType(LineChart)).first.data;

      expect(price().lineBarsData, hasLength(3));

      await tester.tap(find.text('50 DMA'));
      await tester.pumpAndSettle();
      expect(price().lineBarsData, hasLength(2));

      await tester.tap(find.text('200 DMA'));
      await tester.pumpAndSettle();
      expect(price().lineBarsData, hasLength(1));

      // Turning volume off drops the second chart entirely.
      await tester.tap(find.text('Volume'));
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('window switch trims without refetching', (tester) async {
      await tester.pumpWidget(_host(_series(400)));
      await tester.pumpAndSettle();

      final full = tester
          .widgetList<LineChart>(find.byType(LineChart))
          .first
          .data
          .maxX;

      await tester.tap(find.text('1M'));
      await tester.pumpAndSettle();

      // A month of the same fetch: fewer points, and no error from a network
      // call that never happened.
      final month = tester
          .widgetList<LineChart>(find.byType(LineChart))
          .first
          .data
          .maxX;
      expect(month, lessThan(full));
      expect(find.text('Try again'), findsNothing);
      expect(find.textContaining('1M High'), findsOneWidget);
    });

    testWidgets('pinching in raises the drawn resolution', (tester) async {
      // 1,200 sessions is well past the 320 the chart draws at rest, so there
      // is detail left to reveal.
      await tester.pumpWidget(_host(_series(1200)));
      await tester.pumpAndSettle();

      int spots() => tester
          .widgetList<LineChart>(find.byType(LineChart))
          .first
          .data
          .lineBarsData
          .last
          .spots
          .length;

      final atRest = spots();
      expect(atRest, 320);

      final center = tester.getCenter(find.byType(LineChart).first);
      final left = await tester.startGesture(center - const Offset(24, 0));
      final right = await tester.startGesture(center + const Offset(24, 0));
      await left.moveBy(const Offset(-110, 0));
      await right.moveBy(const Offset(110, 0));
      await tester.pumpAndSettle();
      await left.up();
      await right.up();
      await tester.pumpAndSettle();

      // Zoomed in, the same window is drawn from more of the raw sessions
      // rather than magnifying the resampling.
      expect(spots(), greaterThan(atRest));

      // And there is a way back out.
      expect(find.byTooltip('Reset zoom'), findsOneWidget);
      await tester.tap(find.byTooltip('Reset zoom'));
      await tester.pumpAndSettle();
      expect(spots(), atRest);
      expect(find.byTooltip('Reset zoom'), findsNothing);
    });

    testWidgets('scrubbing swaps window stats for the session OHLC', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_series(400)));
      await tester.pumpAndSettle();

      expect(find.text('1Y High'), findsOneWidget);
      expect(find.text('Open'), findsNothing);

      final box = tester.getRect(find.byType(LineChart).first);
      final gesture = await tester.startGesture(
        Offset(box.left + box.width * 0.5, box.center.dy),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Volume'), findsNWidgets(2)); // stat cell + toggle
      expect(find.text('1Y High'), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('1Y High'), findsOneWidget);
    });
  });
}
