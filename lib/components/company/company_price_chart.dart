import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/company/company_section.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/utils/company_format.dart';

/// A selectable window of price history. `years == 0` means "everything the
/// service has".
class CompanyChartRange {
  const CompanyChartRange(this.label, this.years);

  final String label;
  final int years;

  /// A full history is the heaviest request on the page, so the first entry —
  /// used as the default — is deliberately the narrowest. The set matches the
  /// web page's ranges.
  static const List<CompanyChartRange> all = [
    CompanyChartRange('1Y', 1),
    CompanyChartRange('3Y', 3),
    CompanyChartRange('5Y', 5),
    CompanyChartRange('Max', 0),
  ];
}

/// Price history with a range switcher, drawn with `fl_chart`.
///
/// Data still belongs to the screen — the chart is the biggest payload on the
/// page and owning its own fetch would reload the history every time the user
/// came back to the Overview tab. What this widget does own is the scrub
/// position, which is pure interaction state.
///
/// **Why the series is resampled.** `Max` on a well-covered symbol is ~3,400
/// sessions. Handing every one of them to a 300-pixel-wide chart draws several
/// points per pixel and makes each touch hit-test walk the whole list; the
/// resample keeps ~260 points chosen to preserve the shape of the line (see
/// [downsamplePriceSeries]) and is recomputed only when the response changes.
class CompanyPriceChart extends StatefulWidget {
  const CompanyPriceChart({
    super.key,
    required this.chart,
    required this.loading,
    required this.error,
    required this.activeRange,
    required this.onSelectRange,
    required this.onRetry,
    this.onExpand,
  });

  final CompanyChart? chart;
  final bool loading;
  final String? error;
  final CompanyChartRange activeRange;
  final ValueChanged<CompanyChartRange> onSelectRange;
  final VoidCallback onRetry;

  /// Opens the full-page chart. The header affordance is hidden when null.
  final VoidCallback? onExpand;

  @override
  State<CompanyPriceChart> createState() => _CompanyPriceChartState();
}

class _CompanyPriceChartState extends State<CompanyPriceChart> {
  /// Roughly one point per pixel of chart width on a large phone.
  static const int _maxPoints = 260;

  /// A day count past which month labels stop being useful and the axis reads
  /// better as years.
  static const int _yearAxisThreshold = 900;

  /// The vertical line that follows the reader's finger.
  static final Color _crosshairColor = SharePerksColors.primary.withValues(
    alpha: 0.55,
  );
  static const double _crosshairWidth = 1.2;
  static const List<int> _crosshairDash = [3, 3];

  List<PricePoint> _points = const [];
  List<LineChartBarData> _bars = const [];
  double _minY = 0;
  double _maxY = 1;

  /// The point under the reader's finger, or null when they are not scrubbing.
  int? _touched;

  @override
  void initState() {
    super.initState();
    _rebuildSeries();
  }

  @override
  void didUpdateWidget(covariant CompanyPriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Identity, not equality: the model has no `==`, and a new response object
    // is exactly what "the range changed" looks like from here.
    if (!identical(oldWidget.chart, widget.chart)) _rebuildSeries();
  }

  void _rebuildSeries() {
    _points = downsamplePriceSeries(
      widget.chart?.points ?? const [],
      _maxPoints,
    );
    _touched = null;

    if (_points.length < 2) {
      _bars = const [];
      return;
    }

    double? minY;
    double? maxY;
    for (final point in _points) {
      for (final value in [point.close, point.dma50, point.dma200]) {
        if (value == null) continue;
        minY = (minY == null || value < minY) ? value : minY;
        maxY = (maxY == null || value > maxY) ? value : maxY;
      }
    }
    minY ??= 0;
    maxY ??= 1;
    // Breathing room so the extremes are not painted onto the frame.
    final padding = (maxY - minY) * 0.06;
    _minY = minY - (padding == 0 ? 1 : padding);
    _maxY = maxY + (padding == 0 ? 1 : padding);

    // Drawn back to front: the moving averages are context, the close is the
    // subject.
    _bars = [
      _series((p) => p.dma200, SharePerksColors.warning, 1),
      _series((p) => p.dma50, SharePerksColors.info, 1),
      _series((p) => p.close, SharePerksColors.primary, 1.8, area: true),
    ];
  }

  LineChartBarData _series(
    double? Function(PricePoint p) select,
    Color color,
    double width, {
    bool area = false,
  }) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < _points.length; i++)
          if (select(_points[i]) case final value?)
            FlSpot(i.toDouble(), value)
          else
            // A gap, not a zero: the 50/200 DMA have no value until they have
            // that much history behind them.
            FlSpot.nullSpot,
      ],
      color: color,
      barWidth: width,
      isCurved: false,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: area,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  /// The close the readout shows: the scrubbed point, or the latest one.
  PricePoint? get _readoutPoint {
    if (_points.isEmpty) return null;
    final index = _touched;
    if (index == null || index < 0 || index >= _points.length) {
      return _points.last;
    }
    return _points[index];
  }

  /// Change across the visible window, which is what a range switcher is really
  /// asking about — not the day's change the header already shows.
  double? get _windowChangePct {
    if (_points.length < 2) return null;
    final first = _points.first.close;
    final last = _points.last.close;
    if (first == null || last == null || first == 0) return null;
    return ((last - first) / first) * 100;
  }

  bool get _yearAxis {
    if (_points.length < 2) return false;
    final first = DateTime.tryParse(_points.first.date);
    final last = DateTime.tryParse(_points.last.date);
    if (first == null || last == null) return false;
    return last.difference(first).inDays > _yearAxisThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return CompanySection(
      title: 'Price Chart',
      caption: widget.chart == null
          ? null
          : '${fmtIsoDate(widget.chart!.from)} → ${fmtIsoDate(widget.chart!.to)}',
      trailing: widget.onExpand == null
          ? null
          : IconButton(
              tooltip: 'Open full chart',
              onPressed: widget.onExpand,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(
                HugeIconsStroke.arrowExpand01,
                size: 17,
                color: SharePerksColors.primary,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _readout(),
          const SizedBox(height: SharePerksSpacing.sm),
          SizedBox(height: 190, child: _body()),
          const SizedBox(height: SharePerksSpacing.sm),
          _ranges(),
          if (_bars.isNotEmpty) ...[
            const SizedBox(height: SharePerksSpacing.sm),
            Row(
              children: [
                _legend('Close', SharePerksColors.primary),
                const SizedBox(width: 14),
                _legend('50 DMA', SharePerksColors.info),
                const SizedBox(width: 14),
                _legend('200 DMA', SharePerksColors.warning),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Price and date for the scrubbed point — a tooltip that never covers the
  /// line it describes, and that has something to say before the first touch.
  Widget _readout() {
    final point = _readoutPoint;
    final change = _windowChangePct;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fmtRupees(point?.close),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: SharePerksColors.textPrimaryLight,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              point == null ? '' : fmtIsoDate(point.date),
              style: const TextStyle(
                fontSize: 10,
                color: SharePerksColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (change != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtSignedPct(change),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: signColor(change),
                ),
              ),
              Text(
                'over ${widget.activeRange.label}',
                style: const TextStyle(
                  fontSize: 10,
                  color: SharePerksColors.textSecondaryLight,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _body() {
    if (widget.loading) {
      return const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: SharePerksColors.textSecondaryLight,
              ),
            ),
            TextButton(
              onPressed: widget.onRetry,
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }
    if (_bars.isEmpty) {
      return const Center(
        child: SectionEmptyNote(message: 'No price history for this range.'),
      );
    }

    // The chart repaints on every scrub frame; isolating it keeps the rest of
    // the page's layer out of that.
    return RepaintBoundary(
      child: LineChart(
        _chartData(),
        // Range switches animate; a scrub must not — an implicitly animated
        // crosshair slides along behind the finger.
        duration: _touched == null
            ? const Duration(milliseconds: 220)
            : Duration.zero,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  LineChartData _chartData() {
    final interval = (_maxY - _minY) / 4;
    final yearAxis = _yearAxis;

    return LineChartData(
      lineBarsData: _bars,
      minX: 0,
      maxX: (_points.length - 1).toDouble(),
      minY: _minY,
      maxY: _maxY,
      clipData: const FlClipData.all(),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: interval <= 0 ? null : interval,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: SharePerksColors.borderLight,
          strokeWidth: 0.6,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: interval <= 0 ? null : interval,
            getTitlesWidget: _priceTitle,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            // Three gaps, four labels — more than that and they collide on a
            // phone.
            interval: ((_points.length - 1) / 3).clamp(1, double.infinity),
            getTitlesWidget: (value, meta) => _dateTitle(value, meta, yearAxis),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchSpotThreshold: 24,
        // fl_chart's default indicator stops at the touched point, which on a
        // low session reads as a stub near the axis. Spanning the plot gives a
        // crosshair that is findable wherever the price happens to be.
        getTouchLineStart: (_, _) => _minY,
        getTouchLineEnd: (_, _) => _maxY,
        // The readout above the chart replaces the popup, so the built-in
        // tooltip is left empty rather than disabled — the indicator line and
        // dot come from the same machinery.
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 0,
          getTooltipItems: (spots) => List.filled(spots.length, null),
        ),
        getTouchedSpotIndicator: (bar, indicators) => [
          for (final _ in indicators)
            // Only the close line gets an indicator; three dots stacked on the
            // same x is noise.
            //
            // Matched by colour, not identity: the chart lerps its data on
            // every frame, so the bar handed back here is a copy of the one
            // built in [_series] and never the same object.
            if (bar.color == SharePerksColors.primary)
              TouchedSpotIndicatorData(
                // Runs the full height of the plot — see getTouchLineStart /
                // getTouchLineEnd above.
                FlLine(
                  color: _crosshairColor,
                  strokeWidth: _crosshairWidth,
                  dashArray: _crosshairDash,
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 3.5,
                        color: SharePerksColors.primary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                ),
              )
            else
              // The painter skips a null indicator outright, which beats
              // drawing a transparent one.
              null,
        ],
        touchCallback: (event, response) {
          final spots = response?.lineBarSpots;
          final index =
              (!event.isInterestedForInteractions ||
                  spots == null ||
                  spots.isEmpty)
              ? null
              : spots.first.spotIndex;
          if (index == _touched) return;
          setState(() => _touched = index);
        },
      ),
    );
  }

  Widget _priceTitle(double value, TitleMeta meta) {
    // The axis's own min and max sit on the frame; drawing them doubles up with
    // the 52-week band above and crowds the corners.
    if (value <= meta.min || value >= meta.max) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(
        fmtCompactPrice(value),
        style: const TextStyle(
          fontSize: 9.5,
          color: SharePerksColors.textSecondaryLight,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _dateTitle(double value, TitleMeta meta, bool yearAxis) {
    final index = value.round();
    if (index < 0 || index >= _points.length) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(
        fmtAxisDate(_points[index].date, yearOnly: yearAxis),
        style: const TextStyle(
          fontSize: 9.5,
          color: SharePerksColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _ranges() {
    return Row(
      children: [
        for (final range in CompanyChartRange.all)
          Padding(
            padding: const EdgeInsets.only(right: SharePerksSpacing.sm),
            child: GestureDetector(
              onTap: widget.loading ? null : () => widget.onSelectRange(range),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: widget.activeRange.label == range.label
                      ? SharePerksColors.primary
                      : SharePerksColors.surfaceLight,
                  borderRadius: BorderRadius.circular(CompanyRadii.sm),
                  border: Border.all(color: SharePerksColors.borderLight),
                ),
                child: Text(
                  range.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.activeRange.label == range.label
                        ? Colors.white
                        : SharePerksColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 2,
          width: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: SharePerksColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

/// Largest-Triangle-Three-Buckets: the standard time-series downsampler.
///
/// Even sampling drops spikes — a stride of 13 sessions can step straight over
/// a crash. LTTB instead keeps, from each bucket, the point that forms the
/// largest triangle with its neighbours, which is the one that carries the most
/// of the line's shape. The first and last points are always kept, so the
/// window's endpoints (and the change computed from them) stay exact.
///
/// Public so the sampling can be tested without pumping a widget.
List<PricePoint> downsamplePriceSeries(List<PricePoint> source, int threshold) {
  // A null close is a hole in the price line; the moving averages ride along on
  // whichever points survive.
  final data = [
    for (final point in source)
      if (point.close != null) point,
  ];

  final n = data.length;
  if (threshold < 3 || n <= threshold) return data;

  final bucketSize = (n - 2) / (threshold - 2);
  final sampled = <PricePoint>[data.first];
  var anchor = 0;

  for (var i = 0; i < threshold - 2; i++) {
    // Mean of the *next* bucket, standing in for where the line is heading.
    var avgStart = ((i + 1) * bucketSize).floor() + 1;
    var avgEnd = ((i + 2) * bucketSize).floor() + 1;
    if (avgEnd > n) avgEnd = n;
    if (avgStart >= avgEnd) avgStart = avgEnd - 1;

    var avgX = 0.0;
    var avgY = 0.0;
    for (var j = avgStart; j < avgEnd; j++) {
      avgX += j;
      avgY += data[j].close!;
    }
    final count = avgEnd - avgStart;
    avgX /= count;
    avgY /= count;

    final from = (i * bucketSize).floor() + 1;
    var to = ((i + 1) * bucketSize).floor() + 1;
    if (to > n) to = n;

    final anchorX = anchor.toDouble();
    final anchorY = data[anchor].close!;

    var largest = -1.0;
    var chosen = from < n ? from : n - 1;
    for (var j = from; j < to; j++) {
      final area =
          ((anchorX - avgX) * (data[j].close! - anchorY) -
                  (anchorX - j) * (avgY - anchorY))
              .abs() *
          0.5;
      if (area > largest) {
        largest = area;
        chosen = j;
      }
    }

    sampled.add(data[chosen]);
    anchor = chosen;
  }

  sampled.add(data.last);
  return sampled;
}
