import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Shareholding pattern table — Section 12 of the screener guide.
///
/// Shows the last 6 columns (quarters). Values are percentages. Row order
/// follows [ScreenerShareholding.sortedCategories].
class ScreenerShareholdingTable extends StatelessWidget {
  const ScreenerShareholdingTable({super.key, required this.shareholding});

  final ScreenerShareholding shareholding;

  @override
  Widget build(BuildContext context) {
    if (shareholding.isEmpty) {
      return const Text(
        'No shareholding data available.',
        style: TextStyle(
          fontSize: 12,
          color: SharePerksColors.textSecondaryLight,
          fontFamily: SharePerksFonts.inter,
        ),
      );
    }

    final columns = shareholding.visibleColumns;
    final categories = shareholding.sortedCategories;

    if (categories.isEmpty) {
      return const Text(
        'No shareholding data available.',
        style: TextStyle(
          fontSize: 12,
          color: SharePerksColors.textSecondaryLight,
          fontFamily: SharePerksFonts.inter,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerRow(columns),
            for (var i = 0; i < categories.length; i++)
              _categoryRow(categories[i], columns, i),
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
          _cell('Category', isHeader: true, isLabel: true, width: 140),
          for (final col in columns) _cell(col, isHeader: true, width: 85),
        ],
      ),
    );
  }

  Widget _categoryRow(
    ScreenerShareholdingCategory category,
    List<String> columns,
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
          _cell(category.displayName, isLabel: true, width: 140),
          for (final col in columns)
            _cell(_fmtPct(category.values[col]), width: 85),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    bool isHeader = false,
    bool isLabel = false,
    double width = 80,
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

  static String _fmtPct(double? v) =>
      v == null ? '—' : '${v.toStringAsFixed(1)}%';
}
