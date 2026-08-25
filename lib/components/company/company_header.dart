import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/utils/company_format.dart';
import 'package:soui/elements/border_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// One classification chip: the label a company is filed under, and the group
/// the service knows it by.
typedef CompanyClassification = ({ClassificationGroup group, String value});

/// Identity block: name, exchange codes, live price, the 52-week band and the
/// classification chips.
///
/// The band is the one piece of the header that is not a number: where the
/// price sits between its yearly extremes is the question a stat strip answers
/// worst and a bar answers instantly.
class CompanyIdentityCard extends StatelessWidget {
  const CompanyIdentityCard({
    super.key,
    required this.identity,
    required this.metrics,
    this.onTapClassification,
  });

  final CompanyIdentity identity;
  final CompanyKeyMetrics metrics;

  /// Opens the companies filed under a sector / industry. Chips render inert
  /// when null.
  final ValueChanged<CompanyClassification>? onTapClassification;

  List<CompanyClassification> get _tags => [
    if (identity.sector != null)
      (group: ClassificationGroup.sector, value: identity.sector!),
    if (identity.industry != null && identity.industry != identity.sector)
      (group: ClassificationGroup.industry, value: identity.industry!),
    if (identity.macroSector != null && identity.macroSector != identity.sector)
      (group: ClassificationGroup.macroSector, value: identity.macroSector!),
  ];

  @override
  Widget build(BuildContext context) {
    final codes = <String>[
      if (identity.nseCode != null) 'NSE: ${identity.nseCode}',
      if (identity.bseCode != null) 'BSE: ${identity.bseCode}',
    ];
    final tags = _tags;

    return BorderCard(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      borderRadius: 25,
      borderWidth: 1,
      color: SharePerksColors.primary,
      backgroundColor: SharePerksColors.surfaceLight,
      // boxShadow: SharePerksShadows.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            identity.name,
            style: const TextStyle(
              fontFamily: SharePerksFonts.albertSans,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: SharePerksColors.textPrimaryLight,
            ),
          ),
          if (codes.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              codes.join('  ·  '),
              style: const TextStyle(
                fontSize: 11,
                color: SharePerksColors.textSecondaryLight,
              ),
            ),
          ],
          const SizedBox(height: SharePerksSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtRupees(metrics.currentPrice),
                style: const TextStyle(
                  fontFamily: SharePerksFonts.albertSans,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: SharePerksColors.textPrimaryLight,
                ),
              ),
              const SizedBox(width: SharePerksSpacing.sm),
              if (metrics.changePct != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(
                        metrics.changePct! < 0
                            ? HugeIconsSolid.arrowDown02
                            : HugeIconsSolid.arrowUp02,
                        size: 13,
                        color: signColor(metrics.changePct),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        fmtSignedPct(metrics.changePct),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: signColor(metrics.changePct),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (metrics.lastTradedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'As on ${fmtIsoDateTime(metrics.lastTradedAt)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: SharePerksColors.textSecondaryLight,
                ),
              ),
            ),
          const SizedBox(height: SharePerksSpacing.md),
          CompanyPriceBand(
            price: metrics.currentPrice,
            low: metrics.low52,
            high: metrics.high52,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: SharePerksSpacing.md),
            Wrap(
              spacing: SharePerksSpacing.sm,
              runSpacing: SharePerksSpacing.xs,
              children: [for (final tag in tags) _chip(tag)],
            ),
          ],
          if (identity.website != null) ...[
            const SizedBox(height: SharePerksSpacing.sm),
            InkWell(
              onTap: () => _openWebsite(identity.website!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    HugeIconsSolid.link02,
                    size: 13,
                    color: SharePerksColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    identity.website!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SharePerksColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(CompanyClassification tag) {
    final tappable = onTapClassification != null;
    return InkWell(
      borderRadius: BorderRadius.circular(CompanyRadii.sm),
      onTap: tappable ? () => onTapClassification!(tag) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: SharePerksColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(CompanyRadii.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: SharePerksColors.primary,
              ),
            ),
            if (tappable) ...[
              const SizedBox(width: 3),
              const Icon(
                HugeIconsStroke.arrowRight01,
                size: 11,
                color: SharePerksColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> _openWebsite(String website) async {
    final url = website.startsWith('http') ? website : 'https://$website';
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Where the last traded price sits between the 52-week low and high.
///
/// Renders nothing when upstream has no usable band — an empty track with two
/// em dashes says less than the space it takes.
class CompanyPriceBand extends StatelessWidget {
  const CompanyPriceBand({
    super.key,
    required this.price,
    required this.low,
    required this.high,
  });

  final double? price;
  final double? low;
  final double? high;

  @override
  Widget build(BuildContext context) {
    final position = bandPosition(price, low, high);
    if (position == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const markerSize = 9.0;
            final travel = constraints.maxWidth - markerSize;
            return SizedBox(
              height: markerSize,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: SharePerksColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: position,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: SharePerksColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: travel * position,
                    child: Container(
                      height: markerSize,
                      width: markerSize,
                      decoration: BoxDecoration(
                        color: SharePerksColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(fmtNum(low, decimals: 0), style: _bandLabel),
            const Text('52 week', style: _bandLabel),
            Text(fmtNum(high, decimals: 0), style: _bandLabel),
          ],
        ),
      ],
    );
  }

  static const TextStyle _bandLabel = TextStyle(
    fontSize: 10,
    color: SharePerksColors.textSecondaryLight,
  );
}

/// The Screener stat strip — the same twelve figures the web page shows, in the
/// same order.
///
/// Price and the 52-week extremes are deliberately absent: they are the
/// header's job, and repeating them here costs two tiles that carry nothing
/// new.
class CompanyStatGrid extends StatelessWidget {
  const CompanyStatGrid({super.key, required this.metrics});

  final CompanyKeyMetrics metrics;

  static final List<
    ({
      String label,
      String Function(CompanyKeyMetrics m) value,
      Color? Function(CompanyKeyMetrics m)? tone,
    })
  >
  _stats = [
    (label: 'Market Cap', value: (m) => fmtCr(m.marketCapCr), tone: null),
    (label: 'Stock P/E', value: (m) => fmtNum(m.stockPe), tone: null),
    (label: 'Book Value', value: (m) => fmtRupees(m.bookValue), tone: null),
    (label: 'Price / Book', value: (m) => fmtNum(m.priceToBook), tone: null),
    (
      label: 'Dividend Yield',
      value: (m) => fmtPct(m.dividendYieldPct),
      tone: null,
    ),
    (label: 'ROCE', value: (m) => fmtPct(m.rocePct), tone: null),
    (label: 'ROE', value: (m) => fmtPct(m.roePct), tone: null),
    (label: 'OPM', value: (m) => fmtPct(m.opmPct), tone: null),
    // (label: 'Face Value', value: (m) => fmtRupees(m.faceValue), tone: null),
    (
      label: 'Promoter Holding',
      value: (m) => fmtPct(m.promoterHoldingPct),
      tone: null,
    ),
    // (
    //   label: 'Pledged',
    //   value: (m) => fmtPct(m.pledgedPct),
    //   // Any pledge is worth colouring, however small.
    //   tone: (m) => pledgeToneColor(m.pledgedPct),
    // ),
    (
      label: 'Shares Outstanding',
      value: (m) => fmtCompactCount(m.sharesOutstanding),
      tone: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = SharePerksSpacing.sm;
        final width = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in _stats)
              SizedBox(
                width: width,
                child: BorderCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  borderRadius: CompanyRadii.md,
                  borderWidth: 1,
                  color: SharePerksColors.primary.withAlpha(50),
                  isGradientBackground: false,
                  boxShadow: [],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: SharePerksColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.value(metrics),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              stat.tone?.call(metrics) ??
                              SharePerksColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The long-form business description, clamped with a "Show more" toggle.
///
/// The toggle only appears when the text really is longer than the clamp: a
/// [TextPainter] lays the paragraph out at the width it will actually get and
/// reports whether it exceeded the line limit, so short descriptions do not get
/// a toggle that expands nothing.
class CompanyAboutText extends StatefulWidget {
  const CompanyAboutText({super.key, required this.about});

  final String about;

  @override
  State<CompanyAboutText> createState() => _CompanyAboutTextState();
}

class _CompanyAboutTextState extends State<CompanyAboutText> {
  static const int _collapsedLines = 4;

  static const TextStyle _style = TextStyle(
    fontSize: 12,
    height: 1.5,
    color: SharePerksColors.textSecondaryLight,
  );

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.about, style: _style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Text(
                widget.about,
                style: _style,
                maxLines: _expanded ? null : _collapsedLines,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (overflows)
              TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? HugeIconsStroke.arrowUp01
                      : HugeIconsStroke.arrowDown01,
                  size: 13,
                  color: SharePerksColors.primary,
                ),
                label: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SharePerksColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Rule-based pros and cons. Either list can legitimately be empty.
class CompanyProsAndCons extends StatelessWidget {
  const CompanyProsAndCons({super.key, required this.pros, required this.cons});

  final List<String> pros;
  final List<String> cons;

  Widget _list({
    required String title,
    required List<String> items,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: SharePerksSpacing.sm),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 13, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: SharePerksColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pros.isEmpty && cons.isEmpty) {
      return const SectionEmptyNotePlaceholder();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pros.isNotEmpty)
          _list(
            title: 'PROS',
            items: pros,
            color: SharePerksColors.success,
            icon: HugeIconsSolid.tick02,
          ),
        if (pros.isNotEmpty && cons.isNotEmpty)
          const SizedBox(height: SharePerksSpacing.md),
        if (cons.isNotEmpty)
          _list(
            title: 'CONS',
            items: cons,
            color: SharePerksColors.error,
            icon: HugeIconsSolid.alertCircle,
          ),
      ],
    );
  }
}

class SectionEmptyNotePlaceholder extends StatelessWidget {
  const SectionEmptyNotePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'No analysis published for this company yet.',
      style: TextStyle(
        fontSize: 12,
        color: SharePerksColors.textSecondaryLight,
      ),
    );
  }
}
