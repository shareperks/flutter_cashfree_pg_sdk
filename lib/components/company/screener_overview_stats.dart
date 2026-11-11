import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// A grid of stat tiles showing key ratios — Section 2 of the screener guide.
///
/// Each tile is a small card with a label (secondary colour) and a value
/// (primary colour). Ratios arrive as fractions from the API and are multiplied
/// by 100 before display.
class ScreenerOverviewStats extends StatelessWidget {
  const ScreenerOverviewStats({super.key, required this.data});

  final ScreenerCompanyData data;

  @override
  Widget build(BuildContext context) {
    final ttm = data.ratios.ttm;
    final basicTtm = data.basic.ttm;
    final pe = data.priceRatios.annual.isNotEmpty
        ? data.priceRatios.annual.first.pe
        : data.priceRatios.entries.firstOrNull?.pe;
    final dy = data.dividendYield(data.corporateActions.dividends);

    final stats = <_StatTile>[
      _StatTile(
        'Market Cap',
        _fmtMarketCap(data.quote.marketCap ?? data.profile.marketCap),
      ),
      _StatTile('Current Price', _fmtPrice(data.quote.currentPrice)),
      _StatTile('High / Low', _fmtHighLow(data.quote.high52, data.quote.low52)),
      _StatTile('Stock P/E', _fmtNum(pe, decimals: 1)),
      _StatTile('Book Value', _fmtPrice(data.bookValue)),
      _StatTile('Dividend Yield', _fmtPct(dy)),
      _StatTile(
        'ROCE',
        _fmtPct(
          ttm?.returnOnCapital != null ? ttm!.returnOnCapital! * 100 : null,
        ),
      ),
      _StatTile(
        'ROE',
        _fmtPct(
          ttm?.returnOnEquity != null ? ttm!.returnOnEquity! * 100 : null,
        ),
      ),
      _StatTile('Face Value', _fmtPrice(basicTtm?.adjustedFaceValue)),
      _StatTile('Sales / Share', _fmtNum(basicTtm?.salesPerShare, decimals: 2)),
      _StatTile(
        'Net Margin',
        _fmtPct(ttm?.netMargin != null ? ttm!.netMargin! * 100 : null),
      ),
      _StatTile(
        'OPM',
        _fmtPct(
          ttm?.operatingMargin != null ? ttm!.operatingMargin! * 100 : null,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.4,
            crossAxisSpacing: SharePerksSpacing.sm,
            mainAxisSpacing: SharePerksSpacing.sm,
          ),
          itemCount: stats.length,
          itemBuilder: (context, i) => _tile(stats[i]),
        );
      },
    );
  }

  Widget _tile(_StatTile tile) {
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

  // ── formatters ─────────────────────────────────────────────────────────────

  static const _dash = '—';

  static String _fmtPrice(double? v) => v == null
      ? _dash
      : (v == v.roundToDouble()
            ? '₹${v.toStringAsFixed(0)}'
            : '₹${v.toStringAsFixed(2)}');

  static String _fmtNum(double? v, {int decimals = 2}) =>
      v == null ? _dash : v.toStringAsFixed(decimals);

  static String _fmtPct(double? v) =>
      v == null ? _dash : '${v.toStringAsFixed(1)}%';

  static String _fmtHighLow(double? high, double? low) {
    if (high == null && low == null) return _dash;
    final h = high == null
        ? _dash
        : (high == high.roundToDouble()
              ? high.toStringAsFixed(0)
              : high.toStringAsFixed(2));
    final l = low == null
        ? _dash
        : (low == low.roundToDouble()
              ? low.toStringAsFixed(0)
              : low.toStringAsFixed(2));
    return '$h / $l';
  }

  static String _fmtMarketCap(double? v) {
    if (v == null) return _dash;
    final abs = v.abs();
    if (abs >= 1e7) return '₹${(v / 1e7).toStringAsFixed(2)} Cr';
    if (abs >= 1e5) return '₹${(v / 1e5).toStringAsFixed(2)} L';
    return '₹${v.toStringAsFixed(0)}';
  }
}

class _StatTile {
  const _StatTile(this.label, this.value);
  final String label;
  final String value;
}
