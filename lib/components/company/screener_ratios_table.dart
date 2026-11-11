import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Financial ratios table — Section 10 of the screener guide.
///
/// A flat table with years as columns (newest first, max 8) and ratio names as
/// rows. All values are percentages (the API returns fractions, multiplied by
/// 100). Rows where every value is null are hidden.
class ScreenerRatiosTable extends StatelessWidget {
  const ScreenerRatiosTable({super.key, required this.ratios});

  final ScreenerRatios ratios;

  /// Preferred row order per the guide.
  static const _rowOrder = <_RatioRow>[
    _RatioRow('Gross Margin', 'grossMargin'),
    _RatioRow('Operating Margin', 'operatingMargin'),
    _RatioRow('EBITDA Margin', 'ebitdaMargin'),
    _RatioRow('EBIT Margin', 'ebitMargin'),
    _RatioRow('Pre-tax Margin', 'preTaxMargin'),
    _RatioRow('Net Margin', 'netMargin'),
    _RatioRow('Effective Tax Rate', 'effectiveTaxRate'),
    _RatioRow('Return on Equity', 'returnOnEquity'),
    _RatioRow('Return on Capital', 'returnOnCapital'),
    _RatioRow('Return on Asset', 'returnOnAsset'),
    _RatioRow('Return on Tangible Assets', 'returnOnTangibleAssets'),
  ];

  @override
  Widget build(BuildContext context) {
    final annual = ratios.annual.take(8).toList();
    if (annual.isEmpty) {
      return const Text(
        'No ratio data available.',
        style: TextStyle(
          fontSize: 12,
          color: SharePerksColors.textSecondaryLight,
          fontFamily: SharePerksFonts.inter,
        ),
      );
    }

    final columns = annual.map((e) => e.header).toList();

    // Build rows, hiding rows where all values are null.
    final visibleRows = <_RowData>[];
    for (final def in _rowOrder) {
      final values = annual.map((e) => e.allRatios[def.key]).toList();
      if (values.every((v) => v == null)) continue;
      visibleRows.add(
        _RowData(
          def.label,
          values
              .map((v) => v == null ? '—' : '${(v * 100).toStringAsFixed(1)}%')
              .toList(),
        ),
      );
    }

    if (visibleRows.isEmpty) {
      return const Text(
        'No ratio data available.',
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
            for (var i = 0; i < visibleRows.length; i++)
              _dataRow(visibleRows[i], i),
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
          _cell('Ratio', isHeader: true, isLabel: true, width: 150),
          for (final col in columns) _cell(col, isHeader: true, width: 80),
        ],
      ),
    );
  }

  Widget _dataRow(_RowData row, int index) {
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
          _cell(row.label, isLabel: true, width: 150),
          for (var i = 0; i < row.values.length; i++)
            _cell(row.values[i], width: 80),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    bool isHeader = false,
    bool isLabel = false,
    double width = 72,
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
}

class _RatioRow {
  const _RatioRow(this.label, this.key);
  final String label;
  final String key;
}

class _RowData {
  const _RowData(this.label, this.values);
  final String label;
  final List<String> values;
}
