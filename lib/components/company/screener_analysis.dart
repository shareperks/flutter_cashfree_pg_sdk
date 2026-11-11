import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Analysis section — Section 4 of the screener guide.
///
/// Shows (a) an annual price-ratios table (P/E, P/B, P/S, P/FCF, Avg Price —
/// one column per year, newest first, max 8 years) and (b) cash-flow metric
/// stat tiles (Operating CF, Free CF, Investing CF, Financing CF — 3-year
/// totals in ₹ crore, divided by 10,000,000).
class ScreenerAnalysis extends StatelessWidget {
  const ScreenerAnalysis({
    super.key,
    required this.priceRatios,
    required this.financialMetrics,
  });

  final ScreenerPriceRatios priceRatios;
  final ScreenerFinancialMetrics financialMetrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Text(
            'Annual Price Ratios',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SharePerksColors.textSecondaryLight,
              fontFamily: SharePerksFonts.inter,
            ),
          ),
        ),
        _PriceRatiosTable(priceRatios: priceRatios),
        const SizedBox(height: SharePerksSpacing.md),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            'Cash Flow Metrics (3-Year Totals)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SharePerksColors.textSecondaryLight,
              fontFamily: SharePerksFonts.inter,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _CashFlowTiles(metrics: financialMetrics),
        ),
      ],
    );
  }
}

// ── price ratios table ───────────────────────────────────────────────────────

class _PriceRatiosTable extends StatelessWidget {
  const _PriceRatiosTable({required this.priceRatios});

  final ScreenerPriceRatios priceRatios;

  @override
  Widget build(BuildContext context) {
    final annual = priceRatios.annual.take(8).toList();
    if (annual.isEmpty) {
      return const _EmptyNote('No price ratio data available.');
    }

    final columns = annual.map((e) => e.header).toList();
    final rows = <_Row>[
      _Row('P/E', annual.map((e) => _fmtNum(e.pe, decimals: 1)).toList()),
      _Row('P/B', annual.map((e) => _fmtNum(e.pb, decimals: 1)).toList()),
      _Row('P/S', annual.map((e) => _fmtNum(e.ps, decimals: 1)).toList()),
      _Row('P/FCF', annual.map((e) => _fmtNum(e.pfcf, decimals: 1)).toList()),
      _Row('Avg Price', annual.map((e) => _fmtPrice(e.averagePrice)).toList()),
    ];

    return _HorizontalTable(columns: columns, rows: rows);
  }
}

// ── cash flow tiles ──────────────────────────────────────────────────────────

class _CashFlowTiles extends StatelessWidget {
  const _CashFlowTiles({required this.metrics});

  final ScreenerFinancialMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final tiles = <_StatTile>[
      _StatTile('Operating CF 3Y', _fmtCr(metrics.operatingCashFlow3yr)),
      _StatTile('Free CF 3Y', _fmtCr(metrics.freeCashFlow3yr)),
      _StatTile('Investing CF 3Y', _fmtCr(metrics.investingCashFlow3yr)),
      _StatTile('Financing CF 3Y', _fmtCr(metrics.financingCashFlow3yr)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.4,
            crossAxisSpacing: SharePerksSpacing.sm,
            mainAxisSpacing: SharePerksSpacing.sm,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, i) => _statTile(tiles[i]),
        );
      },
    );
  }

  Widget _statTile(_StatTile tile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SharePerksColors.surfaceLight,
        borderRadius: BorderRadius.circular(CompanyRadii.md),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tile.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: SharePerksColors.textSecondaryLight,
              fontFamily: SharePerksFonts.inter,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tile.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SharePerksColors.primary,
              fontFamily: SharePerksFonts.albertSans,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── shared helpers ───────────────────────────────────────────────────────────

class _Row {
  const _Row(this.label, this.values);
  final String label;
  final List<String> values;
}

class _StatTile {
  const _StatTile(this.label, this.value);
  final String label;
  final String value;
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        fontSize: 12,
        color: SharePerksColors.textSecondaryLight,
        fontFamily: SharePerksFonts.inter,
      ),
    );
  }
}

/// A horizontally scrollable table with a pinned label column.
class _HorizontalTable extends StatelessWidget {
  const _HorizontalTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _headerRow(),
            // Body
            for (var i = 0; i < rows.length; i++) _dataRow(rows[i], i),
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Container(
      decoration: const BoxDecoration(
        color: SharePerksColors.surfaceLight,
        border: Border(bottom: BorderSide(color: SharePerksColors.borderLight)),
      ),
      child: Row(
        children: [
          _cell('Year', isHeader: true, isLabel: true, width: 100),
          for (final col in columns) _cell(col, isHeader: true, width: 80),
        ],
      ),
    );
  }

  Widget _dataRow(_Row row, int index) {
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
          _cell(row.label, isLabel: true, width: 100),
          for (var i = 0; i < columns.length; i++)
            _cell(i < row.values.length ? row.values[i] : '—', width: 80),
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
}

// ── formatters ───────────────────────────────────────────────────────────────

const _dash = '—';

String _fmtNum(double? v, {int decimals = 2}) =>
    v == null ? _dash : v.toStringAsFixed(decimals);

String _fmtPrice(double? v) => v == null
    ? _dash
    : (v == v.roundToDouble()
          ? '₹${v.toStringAsFixed(0)}'
          : '₹${v.toStringAsFixed(2)}');

String _fmtCr(double? v) {
  if (v == null) return _dash;
  final cr = v / 1e7;
  final negative = cr < 0;
  final abs = cr.abs();
  final formatted = abs.toStringAsFixed(2);
  return negative ? '-₹ $formatted Cr' : '₹ $formatted Cr';
}
