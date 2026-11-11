import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Revenue by segment table — Section 11 of the screener guide.
///
/// Shows a table with periods as columns and segment names as rows. Values are
/// in rupees and formatted with the Indian number system (Cr for ≥ 1e7, L for
/// ≥ 1e5, K for ≥ 1e3).
class ScreenerSegmentsTable extends StatelessWidget {
  const ScreenerSegmentsTable({super.key, required this.segments});

  final ScreenerSegments segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const Text(
        'No segment data available.',
        style: TextStyle(
          fontSize: 12,
          color: SharePerksColors.textSecondaryLight,
          fontFamily: SharePerksFonts.inter,
        ),
      );
    }

    final periods = segments.periods;
    final segmentNames = segments.segmentNames;

    if (periods.isEmpty || segmentNames.isEmpty) {
      return const Text(
        'No segment data available.',
        style: TextStyle(
          fontSize: 12,
          color: SharePerksColors.textSecondaryLight,
          fontFamily: SharePerksFonts.inter,
        ),
      );
    }

    final columns = periods.map((p) => p.period).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerRow(columns),
            for (var i = 0; i < segmentNames.length; i++)
              _segmentRow(segmentNames[i], periods, i),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(List<String> columns) {
    return Container(
      decoration: const BoxDecoration(
        color: SharePerksColors.surfaceLight,
        border: Border(bottom: BorderSide(color: SharePerksColors.borderLight)),
      ),
      child: Row(
        children: [
          _cell('Segment', isHeader: true, isLabel: true, width: 140),
          for (final col in columns) _cell(col, isHeader: true, width: 95),
        ],
      ),
    );
  }

  Widget _segmentRow(
    String name,
    List<ScreenerSegmentPeriod> periods,
    int index,
  ) {
    final striped = index.isOdd;
    return Container(
      decoration: BoxDecoration(
        color: striped
            ? SharePerksColors.surfaceLight.withValues(alpha: 0.5)
            : null,
        border: const Border(
          bottom: BorderSide(color: SharePerksColors.borderLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _cell(name, isLabel: true, width: 140),
          for (final period in periods)
            _cell(
              _fmtSegmentValue(segments.segmentRevenue(period, name)),
              width: 95,
            ),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    bool isHeader = false,
    bool isLabel = false,
    double width = 90,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      alignment: isLabel ? Alignment.centerLeft : Alignment.centerRight,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
          color: isHeader
              ? SharePerksColors.textSecondaryLight
              : (text == '—'
                    ? SharePerksColors.textSecondaryLight
                    : SharePerksColors.textPrimaryLight),
          fontFamily: SharePerksFonts.inter,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// Formats a rupee value using the Indian number system with compact suffixes.
  static String _fmtSegmentValue(double? v) {
    if (v == null) return '—';
    final abs = v.abs();
    if (abs >= 1e7) return '₹${(v / 1e7).toStringAsFixed(2)} Cr';
    if (abs >= 1e5) return '₹${(v / 1e5).toStringAsFixed(2)} L';
    if (abs >= 1e3) return '₹${(v / 1e3).toStringAsFixed(2)} K';
    return '₹${v.toStringAsFixed(0)}';
  }
}
