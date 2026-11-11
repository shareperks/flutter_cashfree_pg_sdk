import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Peer comparison table — Section 5 of the screener guide.
///
/// Columns: Company, CMP, Change, Mar Cap, P/E, P/B, ROE, OPM. The current
/// company (self) is highlighted. Shows the first 5 peers by default with a
/// "View All" expand button. ROE and OPM are fractions (× 100).
class ScreenerPeersTable extends StatefulWidget {
  const ScreenerPeersTable({super.key, required this.peers});

  final ScreenerPeers peers;

  @override
  State<ScreenerPeersTable> createState() => _ScreenerPeersTableState();
}

class _ScreenerPeersTableState extends State<ScreenerPeersTable> {
  bool _expanded = false;
  static const _defaultCount = 5;

  @override
  Widget build(BuildContext context) {
    final self = widget.peers.self;
    final others = widget.peers.others;

    // Build the row list: self first (if present), then others.
    final allPeers = <ScreenerPeer>[?self, ...others];

    if (allPeers.isEmpty) {
      return const Text(
        'No peer data available.',
        style: TextStyle(
          fontSize: 12,
          color: SharePerksColors.textSecondaryLight,
          fontFamily: SharePerksFonts.inter,
        ),
      );
    }

    final visible = _expanded || allPeers.length <= _defaultCount
        ? allPeers
        : allPeers.sublist(0, _defaultCount);
    final hiddenCount = allPeers.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerRow(),
                for (var i = 0; i < visible.length; i++)
                  _peerRow(visible[i], widget.peers.ticker, i),
              ],
            ),
          ),
        ),
        if (hiddenCount > 0 || _expanded) ...[
          const SizedBox(height: SharePerksSpacing.sm),
          _expandButton(hiddenCount),
        ],
      ],
    );
  }

  Widget _headerRow() {
    const headers = [
      'Company',
      'CMP',
      'Change',
      'Mar Cap',
      'P/E',
      'P/B',
      'ROE',
      'OPM',
    ];
    const widths = [140.0, 80.0, 80.0, 90.0, 64.0, 64.0, 64.0, 64.0];
    return Container(
      decoration: const BoxDecoration(
        color: SharePerksColors.surfaceLight,
        border: Border(bottom: BorderSide(color: SharePerksColors.borderLight)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < headers.length; i++)
            _cell(
              headers[i],
              width: widths[i],
              isHeader: true,
              isLabel: i == 0,
            ),
        ],
      ),
    );
  }

  Widget _peerRow(ScreenerPeer peer, String ticker, int index) {
    final isSelf = peer.symbol.toUpperCase() == ticker.toUpperCase();
    final striped = index.isOdd;
    return Container(
      decoration: BoxDecoration(
        color: isSelf
            ? CompanyTints.selfHighlight
            : striped
            ? SharePerksColors.surfaceLight.withValues(alpha: 0.5)
            : null,
        border: const Border(
          bottom: BorderSide(color: SharePerksColors.borderLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _cell(
            peer.name ?? peer.symbol,
            width: 140,
            isLabel: true,
            highlight: isSelf,
          ),
          _cell(_fmtPrice(peer.cmp), width: 80, highlight: isSelf),
          _cell(
            peer.change ?? '—',
            width: 80,
            highlight: isSelf,
            colorOverride: _changeColor(peer.change),
          ),
          _cell(_fmtMarketCap(peer.marketCap), width: 90, highlight: isSelf),
          _cell(_fmtNum(peer.pe, decimals: 1), width: 64, highlight: isSelf),
          _cell(_fmtNum(peer.pb, decimals: 1), width: 64, highlight: isSelf),
          _cell(_fmtPct(peer.roe), width: 64, highlight: isSelf),
          _cell(_fmtPct(peer.opm), width: 64, highlight: isSelf),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    bool isHeader = false,
    bool isLabel = false,
    double width = 72,
    bool highlight = false,
    Color? colorOverride,
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
          fontWeight: highlight
              ? FontWeight.w700
              : (isHeader ? FontWeight.w600 : FontWeight.w500),
          color:
              colorOverride ??
              (isHeader
                  ? SharePerksColors.textSecondaryLight
                  : (text == '—'
                        ? SharePerksColors.textSecondaryLight
                        : SharePerksColors.textPrimaryLight)),
          fontFamily: SharePerksFonts.inter,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _expandButton(int hiddenCount) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SharePerksColors.surfaceLight,
          borderRadius: BorderRadius.circular(CompanyRadii.sm),
          border: Border.all(color: SharePerksColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _expanded ? 'Show Less' : 'View All ($hiddenCount more)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SharePerksColors.primary,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 14,
              color: SharePerksColors.primary,
            ),
          ],
        ),
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
      v == null ? _dash : '${(v * 100).toStringAsFixed(1)}%';

  static String _fmtMarketCap(double? v) {
    if (v == null) return _dash;
    final abs = v.abs();
    if (abs >= 1e7) return '₹${(v / 1e7).toStringAsFixed(2)} Cr';
    if (abs >= 1e5) return '₹${(v / 1e5).toStringAsFixed(2)} L';
    return '₹${v.toStringAsFixed(0)}';
  }

  static Color? _changeColor(String? change) {
    if (change == null || change == _dash) return null;
    if (change.startsWith('-')) return SharePerksColors.error;
    return SharePerksColors.success;
  }
}
