import 'package:flutter/material.dart';
import 'package:shareperks/components/company/company_section.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/utils/company_format.dart';
import 'package:soui/elements/border_card.dart';

/// One comparable figure, and how it should be shown and ranked.
class _PeerMetric {
  const _PeerMetric({
    required this.label,
    required this.read,
    required this.format,
    required this.ascending,
  });

  final String label;
  final double? Function(PeerRow row) read;
  final String Function(double? value) format;

  /// Which end of the scale ranks first. Cheap earnings multiples sort up;
  /// returns and margins sort down.
  final bool ascending;
}

/// Peer comparison.
///
/// Rendered as cards rather than a table on purpose: seven metric columns on a
/// phone means five of them live off-screen behind a horizontal scroll, and a
/// comparison you have to scroll sideways to read is not a comparison. Each
/// peer instead gets a card with its figures laid out in a row that fits.
class CompanyPeersView extends StatefulWidget {
  const CompanyPeersView({super.key, required this.comparison});

  final PeerComparison comparison;

  @override
  State<CompanyPeersView> createState() => _CompanyPeersViewState();
}

class _CompanyPeersViewState extends State<CompanyPeersView> {
  static const List<_PeerMetric> _allMetrics = [
    _PeerMetric(
      label: 'Mkt Cap',
      read: _marketCap,
      format: _crShort,
      ascending: false,
    ),
    _PeerMetric(label: 'P/E', read: _pe, format: _plain, ascending: true),
    _PeerMetric(label: 'P/B', read: _pb, format: _plain, ascending: true),
    _PeerMetric(label: 'ROE', read: _roe, format: _percent, ascending: false),
    _PeerMetric(label: 'OPM', read: _opm, format: _percent, ascending: false),
  ];

  static double? _marketCap(PeerRow r) => r.marketCapCr;
  static double? _pe(PeerRow r) => r.pe;
  static double? _pb(PeerRow r) => r.priceToBook;
  static double? _roe(PeerRow r) => r.roePct;
  static double? _opm(PeerRow r) => r.opmPct;

  static String _plain(double? v) => fmtNum(v);
  static String _percent(double? v) => fmtPct(v);

  /// `338045.04` → `3.38L Cr`, so market cap fits a quarter of a phone.
  static String _crShort(double? value) => companyDash(value, (v) {
    if (v >= 100000) {
      return '${formatIndianNumber(v / 100000, decimals: 2)}L Cr';
    }
    if (v >= 1000) {
      return '${formatIndianNumber(v / 1000, decimals: 1)}K Cr';
    }
    return '${formatIndianNumber(v, decimals: 0)} Cr';
  });

  late final List<PeerRow> _everyone = [
    if (widget.comparison.self != null) widget.comparison.self!,
    ...widget.comparison.peers,
  ];

  /// A metric every company is missing is dead space — peer quotes are fetched
  /// as a batch upstream and can fail as a set, which routinely empties market
  /// cap for the whole table.
  late final List<_PeerMetric> _metrics = _allMetrics
      .where((m) => _everyone.any((row) => m.read(row) != null))
      .toList();

  late _PeerMetric? _sortBy = _metrics.isEmpty ? null : _metrics.first;

  List<PeerRow> get _sortedPeers {
    final peers = [...widget.comparison.peers];
    final metric = _sortBy;
    if (metric == null) return peers;
    peers.sort((a, b) {
      final left = metric.read(a);
      final right = metric.read(b);
      // Companies with no figure for the chosen metric sink to the bottom
      // rather than sorting as if they were zero.
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return metric.ascending ? left.compareTo(right) : right.compareTo(left);
    });
    return peers;
  }

  @override
  Widget build(BuildContext context) {
    if (_everyone.isEmpty) {
      return const SectionEmptyNote(
        message: 'No peers listed for this company.',
      );
    }

    final self = widget.comparison.self;
    final peers = _sortedPeers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_metrics.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Sort by',
                  style: TextStyle(
                    fontSize: 11,
                    color: SharePerksColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                for (final metric in _metrics) ...[
                  _sortChip(metric),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (self != null) ...[
          _peerCard(self, isSelf: true, rank: null),
          const SizedBox(height: 8),
        ],
        for (var i = 0; i < peers.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _peerCard(peers[i], isSelf: false, rank: i + 1),
        ],
      ],
    );
  }

  Widget _sortChip(_PeerMetric metric) {
    final selected = identical(_sortBy, metric);
    return GestureDetector(
      onTap: () => setState(() => _sortBy = metric),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          metric.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : SharePerksColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _peerCard(PeerRow row, {required bool isSelf, required int? rank}) {
    return BorderCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      borderRadius: CompanyRadii.md,
      borderWidth: 1,
      color: isSelf
          ? SharePerksColors.primary.withAlpha(60)
          : SharePerksColors.primary.withAlpha(20),
      backgroundColor: isSelf
          ? SharePerksColors.primary.withValues(alpha: 0.06)
          : SharePerksColors.backgroundLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rank != null) ...[
                SizedBox(
                  width: 20,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SharePerksColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name ?? row.symbol,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelf ? FontWeight.w700 : FontWeight.w600,
                        color: SharePerksColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      row.symbol,
                      style: const TextStyle(
                        fontSize: 10,
                        color: SharePerksColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              // The company's own row keeps its price as well as the badge —
              // a comparison whose reference point has no CMP is half a table.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isSelf)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: SharePerksColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'This company',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (row.currentPrice != null) ...[
                    if (isSelf) const SizedBox(height: 3),
                    Text(
                      fmtRupees(row.currentPrice),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: SharePerksColors.textPrimaryLight,
                      ),
                    ),
                    if (row.changePct != null)
                      Text(
                        fmtSignedPct(row.changePct),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: signColor(row.changePct),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
          if (_metrics.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (final metric in _metrics)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: SharePerksColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          metric.format(metric.read(row)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: metric.read(row) == null
                                ? SharePerksColors.textSecondaryLight
                                : SharePerksColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
