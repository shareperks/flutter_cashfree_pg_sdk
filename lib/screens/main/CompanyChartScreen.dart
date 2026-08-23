import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/company/company_price_chart.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/repository/services/company/company_data.service.dart';
import 'package:shareperks/utils/company_format.dart';
import 'package:soui/elements/SpScafold.dart';

/// One window of history the page can show.
///
/// [years] is what the service is asked for — its `from`/`to` are years, not
/// dates — and [days] trims the answer down afterwards. So 1M, 3M and 6M all
/// ride on the same one-year fetch and switch instantly.
class _Window {
  const _Window(this.label, {required this.years, this.days});

  final String label;
  final int years;
  final int? days;

  static const List<_Window> all = [
    _Window('1M', years: 1, days: 31),
    _Window('3M', years: 1, days: 92),
    _Window('6M', years: 1, days: 183),
    _Window('1Y', years: 1),
    _Window('3Y', years: 3),
    _Window('5Y', years: 5),
    _Window('Max', years: 0),
  ];
}

/// The chart on its own page: a full-height price series with pinch-zoom, a
/// volume pane, moving averages and a per-session readout.
///
/// The Overview tab's chart is a summary — four ranges, no zoom, sized to leave
/// room for the sections under it. This is the one for actually reading a
/// price: the plot takes the whole screen, resolution rises as you zoom in
/// (see [_resample]), and every session's open, high, low, close and volume is
/// a scrub away.
class CompanyChartScreen extends StatefulWidget {
  const CompanyChartScreen({
    super.key,
    required this.symbol,
    this.name,
    this.initial,
    this.initialYears,
  });

  final String symbol;
  final String? name;

  /// A series the caller has already fetched, and the number of years it
  /// covers. Handed over from the Overview tab so the page opens drawn rather
  /// than spinning; any other window is fetched on demand.
  final CompanyChart? initial;
  final int? initialYears;

  @override
  State<CompanyChartScreen> createState() => _CompanyChartScreenState();
}

class _CompanyChartScreenState extends State<CompanyChartScreen> {
  /// Points drawn at rest. Zooming in raises this in step with the scale.
  static const int _basePoints = 320;

  /// Above this the chart is showing raw sessions and there is nothing left to
  /// reveal.
  static const int _maxPoints = 4000;

  static const double _maxScale = 12;

  final TransformationController _transform = TransformationController();

  /// Responses keyed by the number of years asked for, so flipping between
  /// windows that share a fetch never hits the network twice.
  final Map<int, CompanyChart> _fetched = {};

  _Window _window = _Window.all[3];
  bool _loading = true;
  String? _error;

  /// Everything the current fetch returned, trimmed to [_window].
  List<PricePoint> _raw = const [];

  /// What is actually drawn — [_raw] resampled for the current zoom level.
  List<PricePoint> _points = const [];

  bool _showDma50 = true;
  bool _showDma200 = true;
  bool _showVolume = true;

  int? _touched;

  /// Rounded zoom level the current resample was built for; the series is only
  /// rebuilt when this changes, not on every pinch frame.
  int _resampleStep = 1;

  /// Whether the reader has zoomed at all, which is what the reset control
  /// keys off.
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);

    final initial = widget.initial;
    final years = widget.initialYears;
    if (initial != null && years != null) {
      _fetched[years] = initial;
      _window = _Window.all.firstWhere(
        (w) => w.years == years && w.days == null,
        orElse: () => _window,
      );
    }
    _load(_window);
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_onTransform)
      ..dispose();
    super.dispose();
  }

  double get _scale => _transform.value.getMaxScaleOnAxis();

  void _onTransform() {
    final step = _scale.round().clamp(1, _maxScale.round());
    final zoomed = _scale > 1.01;
    // Two separate thresholds: resampling is expensive and only worth doing per
    // whole step of magnification, but the reset control has to appear as soon
    // as the reader has zoomed at all — 1.4x rounds to step 1 and would
    // otherwise leave them with no way back.
    if (step == _resampleStep && zoomed == _zoomed) return;
    setState(() {
      _zoomed = zoomed;
      if (step != _resampleStep) {
        _resampleStep = step;
        _resample();
      }
    });
  }

  /// Detail follows the zoom: at rest the line is [_basePoints] samples, and
  /// every step of magnification asks for proportionally more, up to the raw
  /// series. Without this, zooming in magnifies the resampling artefacts
  /// instead of revealing sessions.
  void _resample() {
    final target = (_basePoints * _resampleStep).clamp(_basePoints, _maxPoints);
    _points = downsamplePriceSeries(_raw, target);
  }

  Future<void> _load(_Window window) async {
    setState(() {
      _window = window;
      _loading = true;
      _error = null;
      _touched = null;
    });

    try {
      final chart = _fetched[window.years] ?? await _fetch(window.years);
      if (!mounted) return;
      _fetched[window.years] = chart;
      setState(() {
        _raw = trimToWindow(chart.points, window.days);
        _resample();
        _loading = false;
      });
    } on CompanyApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.displayMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Price history is unavailable right now.';
        _loading = false;
      });
    }
  }

  Future<CompanyChart> _fetch(int years) {
    final now = DateTime.now().year;
    return CompanyDataService.getChart(
      widget.symbol,
      // The endpoint takes years; `Max` is both bounds omitted.
      from: years == 0 ? null : now - years,
      to: years == 0 ? null : now,
    );
  }

  void _resetZoom() {
    _transform.value = Matrix4.identity();
    setState(() {
      _zoomed = false;
      _resampleStep = 1;
      _resample();
    });
  }

  PricePoint? get _session {
    final index = _touched;
    if (index == null || index < 0 || index >= _points.length) return null;
    return _points[index];
  }

  PricePoint? get _latest => _points.isEmpty ? null : _points.last;

  double? get _windowChangePct {
    if (_points.length < 2) return null;
    final first = _points.first.close;
    final last = _points.last.close;
    if (first == null || last == null || first == 0) return null;
    return ((last - first) / first) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        backgroundColor: SharePerksColors.primary,
        leading: const AppBackButton(),
        toolbarHeight: 40,
        titleSpacing: 0,
        title: Text(widget.symbol.toUpperCase()),
        actions: [
          if (_zoomed)
            IconButton(
              tooltip: 'Reset zoom',
              onPressed: _resetZoom,
              icon: const Icon(HugeIconsStroke.zoomOutArea, size: 18),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            _windows(),
            Expanded(child: _plot()),
            if (_showVolume && _points.isNotEmpty) _volume(),
            _series(),
            _stats(),
          ],
        ),
      ),
    );
  }

  /// Name, last (or scrubbed) price, and the change across the window.
  Widget _header() {
    final session = _session;
    final point = session ?? _latest;
    final change = _windowChangePct;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.name != null)
                  Text(
                    widget.name!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: SharePerksColors.textSecondaryLight,
                    ),
                  ),
                Text(
                  fmtRupees(point?.close),
                  style: const TextStyle(
                    fontFamily: SharePerksFonts.albertSans,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: SharePerksColors.textPrimaryLight,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  point == null
                      ? ''
                      : session == null
                      ? 'Latest close · ${fmtIsoDate(point.date)}'
                      : fmtIsoDate(point.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: SharePerksColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (change != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmtSignedPct(change),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: signColor(change),
                  ),
                ),
                Text(
                  'over ${_window.label}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: SharePerksColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _windows() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: _Window.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final window = _Window.all[index];
          final selected = window.label == _window.label;
          return GestureDetector(
            onTap: _loading ? null : () => _load(window),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? SharePerksColors.primary
                    : SharePerksColors.surfaceLight,
                borderRadius: BorderRadius.circular(CompanyRadii.sm),
                border: Border.all(
                  color: selected
                      ? SharePerksColors.primary
                      : SharePerksColors.borderLight,
                ),
              ),
              child: Text(
                window.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : SharePerksColors.textSecondaryLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _plot() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          height: 26,
          width: 26,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(SharePerksSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                HugeIconsStroke.alert02,
                size: 40,
                color: SharePerksColors.textSecondaryLight,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: SharePerksColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _load(_window),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_points.length < 2) {
      return const Center(
        child: Text(
          'No price history for this window.',
          style: TextStyle(
            fontSize: 12,
            color: SharePerksColors.textSecondaryLight,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 14, 2),
      child: RepaintBoundary(
        child: LineChart(
          _priceData(),
          // A scrub must land under the finger immediately; only window
          // changes are worth animating.
          duration: _touched == null
              ? const Duration(milliseconds: 220)
              : Duration.zero,
          curve: Curves.easeOutCubic,
          transformationConfig: FlTransformationConfig(
            scaleAxis: FlScaleAxis.horizontal,
            maxScale: _maxScale,
            transformationController: _transform,
          ),
        ),
      ),
    );
  }

  ({double min, double max}) get _priceBounds {
    double? min;
    double? max;
    for (final point in _points) {
      for (final value in [
        point.low ?? point.close,
        point.high ?? point.close,
        if (_showDma50) point.dma50,
        if (_showDma200) point.dma200,
      ]) {
        if (value == null) continue;
        min = (min == null || value < min) ? value : min;
        max = (max == null || value > max) ? value : max;
      }
    }
    min ??= 0;
    max ??= 1;
    final padding = (max - min) * 0.06;
    return (
      min: min - (padding == 0 ? 1 : padding),
      max: max + (padding == 0 ? 1 : padding),
    );
  }

  LineChartData _priceData() {
    final bounds = _priceBounds;
    final interval = (bounds.max - bounds.min) / 4;
    final yearAxis = _spansYears;

    return LineChartData(
      lineBarsData: [
        if (_showDma200) _line((p) => p.dma200, SharePerksColors.warning, 1),
        if (_showDma50) _line((p) => p.dma50, SharePerksColors.info, 1),
        _line((p) => p.close, SharePerksColors.primary, 1.8, area: true),
      ],
      minX: 0,
      maxX: (_points.length - 1).toDouble(),
      minY: bounds.min,
      maxY: bounds.max,
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
            reservedSize: 46,
            interval: interval <= 0 ? null : interval,
            getTitlesWidget: (value, meta) {
              if (value <= meta.min || value >= meta.max) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(fmtCompactPrice(value), style: _axisStyle),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: ((_points.length - 1) / 4).clamp(1, double.infinity),
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= _points.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  fmtAxisDate(_points[index].date, yearOnly: yearAxis),
                  style: _axisStyle,
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchSpotThreshold: 26,
        getTouchLineStart: (_, _) => bounds.min,
        getTouchLineEnd: (_, _) => bounds.max,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 0,
          getTooltipItems: (spots) => List.filled(spots.length, null),
        ),
        getTouchedSpotIndicator: (bar, indicators) => [
          for (final _ in indicators)
            // Matched by colour: the chart lerps its bars into new objects
            // every frame, so identity never holds here.
            if (bar.color == SharePerksColors.primary)
              TouchedSpotIndicatorData(
                FlLine(
                  color: SharePerksColors.primary.withValues(alpha: 0.55),
                  strokeWidth: 1.2,
                  dashArray: const [3, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 4,
                        color: SharePerksColors.primary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                ),
              )
            else
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

  LineChartBarData _line(
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

  /// Traded volume, sharing the price chart's x domain *and* its transformation
  /// controller — so a pinch on either pane keeps the two in step.
  Widget _volume() {
    var peak = 0.0;
    for (final point in _points) {
      final volume = point.volume;
      if (volume != null && volume > peak) peak = volume;
    }
    if (peak <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(
                'Vol\n${fmtCompactCount(peak)}',
                textAlign: TextAlign.right,
                style: _axisStyle,
              ),
            ),
            Expanded(
              child: RepaintBoundary(
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < _points.length; i++)
                            FlSpot(i.toDouble(), _points[i].volume ?? 0),
                        ],
                        color: SharePerksColors.primary.withValues(alpha: 0.35),
                        barWidth: 0.6,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: SharePerksColors.primary.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: (_points.length - 1).toDouble(),
                    minY: 0,
                    maxY: peak * 1.08,
                    clipData: const FlClipData.all(),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                  duration: Duration.zero,
                  transformationConfig: FlTransformationConfig(
                    scaleAxis: FlScaleAxis.horizontal,
                    maxScale: _maxScale,
                    transformationController: _transform,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Which series are drawn. Everything here is a toggle rather than a legend:
  /// on a small screen, hiding the moving averages is often what makes the
  /// price readable.
  Widget _series() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _toggle(
            '50 DMA',
            SharePerksColors.info,
            _showDma50,
            () => setState(() => _showDma50 = !_showDma50),
          ),
          _toggle(
            '200 DMA',
            SharePerksColors.warning,
            _showDma200,
            () => setState(() => _showDma200 = !_showDma200),
          ),
          _toggle(
            'Volume',
            SharePerksColors.primary,
            _showVolume,
            () => setState(() => _showVolume = !_showVolume),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, Color color, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? color.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(CompanyRadii.sm),
          border: Border.all(
            color: on
                ? color.withValues(alpha: 0.45)
                : SharePerksColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 2.5,
              width: 12,
              decoration: BoxDecoration(
                color: on ? color : SharePerksColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: on ? color : SharePerksColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The scrubbed session's OHLC, or the window's own extremes when nothing is
  /// under the finger — the numbers a chart is usually being read for.
  Widget _stats() {
    final session = _session;
    final cells = session != null
        ? <({String label, String value})>[
            (label: 'Open', value: fmtRupees(session.open)),
            (label: 'High', value: fmtRupees(session.high)),
            (label: 'Low', value: fmtRupees(session.low)),
            (label: 'Close', value: fmtRupees(session.close)),
            (label: 'Volume', value: fmtCompactCount(session.volume)),
          ]
        : _windowCells();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: SharePerksColors.surfaceLight,
        borderRadius: BorderRadius.circular(CompanyRadii.md),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              child: Column(
                children: [
                  Text(
                    cell.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: SharePerksColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cell.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: SharePerksColors.textPrimaryLight,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<({String label, String value})> _windowCells() {
    double? high;
    double? low;
    var volumeSum = 0.0;
    var volumeCount = 0;

    for (final point in _points) {
      final top = point.high ?? point.close;
      final bottom = point.low ?? point.close;
      if (top != null) high = (high == null || top > high) ? top : high;
      if (bottom != null) {
        low = (low == null || bottom < low) ? bottom : low;
      }
      if (point.volume != null) {
        volumeSum += point.volume!;
        volumeCount++;
      }
    }

    return [
      (label: '${_window.label} High', value: fmtRupees(high)),
      (label: '${_window.label} Low', value: fmtRupees(low)),
      (label: 'Change', value: fmtSignedPct(_windowChangePct)),
      (
        label: 'Avg Vol',
        value: fmtCompactCount(
          volumeCount == 0 ? null : volumeSum / volumeCount,
        ),
      ),
      (label: 'Sessions', value: '${_raw.length}'),
    ];
  }

  bool get _spansYears {
    if (_points.length < 2) return false;
    final first = DateTime.tryParse(_points.first.date);
    final last = DateTime.tryParse(_points.last.date);
    if (first == null || last == null) return false;
    return last.difference(first).inDays > 900;
  }

  static const TextStyle _axisStyle = TextStyle(
    fontSize: 9.5,
    color: SharePerksColors.textSecondaryLight,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Keeps the last [days] sessions of [points], which arrive oldest first.
///
/// The service's chart endpoint is addressed in whole years, so a one-month
/// window is a one-year fetch cut down here — which also means 1M, 3M and 6M
/// switch without another request.
List<PricePoint> trimToWindow(List<PricePoint> points, int? days) {
  if (days == null || points.isEmpty) return points;
  final last = DateTime.tryParse(points.last.date);
  if (last == null) return points;

  final cutoff = last.subtract(Duration(days: days));
  final from = points.indexWhere((point) {
    final date = DateTime.tryParse(point.date);
    return date != null && !date.isBefore(cutoff);
  });
  return from <= 0 ? points : points.sublist(from);
}
