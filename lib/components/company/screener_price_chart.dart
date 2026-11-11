import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

class _Range {
  const _Range(this.label, this.days);
  final String label;
  final int days;
}

/// Available time-frame buttons and their approximate day counts.
const _kRanges = <_Range>[
  _Range('1M', 30),
  _Range('6M', 182),
  _Range('1Yr', 365),
  _Range('3Yr', 1095),
  _Range('5Yr', 1825),
  _Range('10Yr', 3650),
  _Range('Max', 0),
];

/// Price chart with a time-frame switcher — Section 3 of the screener guide.
///
/// Uses a lightweight [CustomPainter] instead of an external chart library.
/// The change % over the selected period is shown in the header (green if
/// positive, red if negative).
class ScreenerPriceChart extends StatelessWidget {
  const ScreenerPriceChart({
    super.key,
    required this.chart,
    required this.activeRange,
    required this.onSelectRange,
  });

  final ScreenerChart chart;
  final String activeRange;
  final ValueChanged<String> onSelectRange;

  @override
  Widget build(BuildContext context) {
    final range = _kRanges.firstWhere(
      (r) => r.label == activeRange,
      orElse: () => _kRanges.first,
    );
    final filtered = chart.filtered(range.days);
    final change = filtered.changePct;
    final isPositive = change != null && change >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: change % over the selected period
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (filtered.points.isNotEmpty) ...[
                Text(
                  '₹${_fmtPrice(filtered.points.last.close)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: SharePerksFonts.albertSans,
                    color: SharePerksColors.textPrimaryLight,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              const Spacer(),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isPositive
                                ? SharePerksColors.success
                                : SharePerksColors.error)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(CompanyRadii.sm),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: SharePerksFonts.inter,
                      color: isPositive
                          ? SharePerksColors.success
                          : SharePerksColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: SharePerksSpacing.sm + 2),
        // Chart
        SizedBox(
          height: 200,
          child: filtered.points.length < 2
              ? const Center(
                  child: Text(
                    'No price history for this range.',
                    style: TextStyle(
                      fontSize: 12,
                      color: SharePerksColors.textSecondaryLight,
                      fontFamily: SharePerksFonts.inter,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _LineChartPainter(
                      points: filtered.points.map((p) => p.close ?? 0).toList(),
                      dates: filtered.points.map((p) => p.date).toList(),
                      color: isPositive
                          ? SharePerksColors.success
                          : SharePerksColors.error,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: SharePerksSpacing.sm + 2),
        // Time-frame buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < _kRanges.length; i++) ...[
                GestureDetector(
                  onTap: () => onSelectRange(_kRanges[i].label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: activeRange == _kRanges[i].label
                          ? SharePerksColors.primary
                          : SharePerksColors.surfaceLight,
                      borderRadius: BorderRadius.circular(CompanyRadii.sm),
                      border: Border.all(
                        color: activeRange == _kRanges[i].label
                            ? SharePerksColors.primary
                            : SharePerksColors.borderLight,
                      ),
                    ),
                    child: Text(
                      _kRanges[i].label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: SharePerksFonts.inter,
                        color: activeRange == _kRanges[i].label
                            ? Colors.white
                            : SharePerksColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
                if (i < _kRanges.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _fmtPrice(double? v) {
    if (v == null) return '—';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }
}

/// A minimal line-chart painter that draws closing prices with a gradient fill
/// below the line and light axis labels.
class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.dates,
    required this.color,
  });

  final List<double> points;
  final List<String> dates;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double minVal = points.first;
    double maxVal = points.first;
    for (final p in points) {
      if (p < minVal) minVal = p;
      if (p > maxVal) maxVal = p;
    }
    final range = maxVal - minVal;
    final yRange = range == 0 ? 1.0 : range;
    final padY = size.height * 0.1;
    final usableH = size.height - padY * 2;

    double xAt(int i) => (i / (points.length - 1)) * size.width;
    double yAt(double v) => padY + (1 - (v - minVal) / yRange) * usableH;

    // Gradient fill below the line.
    final fillPath = Path()..moveTo(xAt(0), yAt(points[0]));
    for (var i = 1; i < points.length; i++) {
      fillPath.lineTo(xAt(i), yAt(points[i]));
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    // The line itself.
    final linePath = Path()..moveTo(xAt(0), yAt(points[0]));
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(xAt(i), yAt(points[i]));
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    // Start and end date labels.
    _drawDateLabel(canvas, size, dates.first, 0, true);
    _drawDateLabel(canvas, size, dates.last, size.width, false);
  }

  void _drawDateLabel(
    Canvas canvas,
    Size size,
    String date,
    double x,
    bool leftAlign,
  ) {
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
    String label;
    final parts = date.split('-');
    if (parts.length == 3) {
      final monthIdx = int.tryParse(parts[1]);
      final yearShort = parts[0].length >= 4 ? parts[0].substring(2) : parts[0];
      label = monthIdx != null && monthIdx >= 1 && monthIdx <= 12
          ? '${months[monthIdx - 1]} $yearShort'
          : date;
    } else {
      label = date;
    }

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 9,
          color: SharePerksColors.textSecondaryLight,
          fontFamily: SharePerksFonts.inter,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = leftAlign ? 0.0 : (x - tp.width);
    final maxX = (size.width - tp.width).clamp(0.0, double.infinity);
    tp.paint(canvas, Offset(dx.clamp(0.0, maxX), size.height - tp.height));
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.points != points || old.color != color;
}
