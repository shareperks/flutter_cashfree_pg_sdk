import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/company/company_section.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/utils/company_format.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/gredent_list.dart';
import 'package:url_launcher/url_launcher.dart';

/// A titled, bordered block of filings or actions with its own count and
/// "Show all" toggle.
///
/// Each list is capped rather than fully rendered: a well-covered large cap
/// files dozens of announcements, and an unbounded list would push the other
/// three groups off the screen entirely.
class _DisclosureGroup extends StatefulWidget {
  const _DisclosureGroup({
    required this.title,
    required this.icon,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String title;
  final IconData icon;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<_DisclosureGroup> createState() => _DisclosureGroupState();
}

class _DisclosureGroupState extends State<_DisclosureGroup> {
  /// Enough to see what a company has been filing without burying the next
  /// group below the fold.
  static const int _collapsedCount = 5;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visible = _expanded
        ? widget.itemCount
        : (widget.itemCount < _collapsedCount
              ? widget.itemCount
              : _collapsedCount);
    final hidden = widget.itemCount - visible;

    return BorderCard(
      borderRadius: CompanyRadii.md,
      borderWidth: 1,
      color: SharePerksColors.primary.withAlpha(20),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CompanyRadii.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(
                  bottom: BorderSide(color: SharePerksColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 15, color: SharePerksColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SharePerksColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SharePerksColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.itemCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: SharePerksColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < visible; i++)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: i == visible - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: SharePerksColors.borderLight,
                            width: 0.5,
                          ),
                        ),
                ),
                child: widget.itemBuilder(context, i),
              ),
            if (hidden > 0 || _expanded)
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFBFD),
                    border: Border(
                      top: BorderSide(color: SharePerksColors.borderLight),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _expanded
                            ? 'Show less'
                            : 'Show all ${widget.itemCount}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: SharePerksColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? HugeIconsStroke.arrowUp01
                            : HugeIconsStroke.arrowDown01,
                        size: 13,
                        color: SharePerksColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty state shared by both disclosure sections — an empty list means
/// "nothing published", never "the request failed", so it must not look like
/// an error.
class _NothingPublished extends StatelessWidget {
  const _NothingPublished({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: SharePerksColors.surfaceLight,
        borderRadius: BorderRadius.circular(CompanyRadii.md),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: SharePerksColors.textSecondaryLight),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: SharePerksColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filings, transcripts, presentations and credit ratings. Each list degrades
/// to empty independently — empty means "nothing published", never "failed".
class CompanyDocumentsView extends StatelessWidget {
  const CompanyDocumentsView({super.key, required this.documents});

  final CompanyDocuments documents;

  Future<void> _open(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    // Document links point at third-party filing hosts and are not always live.
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _item(DocumentItem item) {
    final linked = item.url != null;
    return GredentListTile(
      enabled: linked,
      onTap: linked ? () => _open(item.url) : null,
      color: SharePerksColors.primary,
      style: GredentListTileStyle(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        border: const Border(),
        isThreeLine: item.date != null || item.category != null,
      ),
      leading: Icon(
        linked ? HugeIconsStroke.linkSquare02 : HugeIconsStroke.note01,
        size: 15,
        color: linked
            ? SharePerksColors.primary
            : SharePerksColors.textSecondaryLight,
      ),
      title: Text(
        // Upstream text — rendered as text, never as HTML.
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: linked
              ? SharePerksColors.textPrimaryLight
              : SharePerksColors.textSecondaryLight,
        ),
      ),
      subtitle: item.date != null || item.category != null
          ? Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  if (item.date != null) ...[
                    const Icon(
                      HugeIconsStroke.calendar03,
                      size: 11,
                      color: SharePerksColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      fmtIsoDate(item.date),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: SharePerksColors.textSecondaryLight,
                      ),
                    ),
                  ],
                  if (item.category != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SharePerksColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: SharePerksColors.borderLight,
                          ),
                        ),
                        child: Text(
                          item.category!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: SharePerksColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <({String title, IconData icon, List<DocumentItem> items})>[
      (
        title: 'Announcements',
        icon: HugeIconsSolid.notification01,
        items: documents.announcements,
      ),
      (
        title: 'Concall Transcripts',
        icon: HugeIconsSolid.chatUser,
        items: documents.callTranscripts,
      ),
      (
        title: 'Investor Presentations',
        icon: HugeIconsSolid.analyticsUp,
        items: documents.presentations,
      ),
      (
        title: 'Credit Ratings',
        icon: HugeIconsSolid.shield01,
        items: documents.creditRatings,
      ),
    ].where((group) => group.items.isNotEmpty).toList();

    if (groups.isEmpty) {
      return const _NothingPublished(
        icon: HugeIconsStroke.note01,
        message: 'No filings published for this company yet.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) const SizedBox(height: SharePerksSpacing.sm),
          _DisclosureGroup(
            title: groups[i].title,
            icon: groups[i].icon,
            itemCount: groups[i].items.length,
            itemBuilder: (context, index) => _item(groups[i].items[index]),
          ),
        ],
      ],
    );
  }
}

/// Dividends, splits, bonuses and rights.
class CompanyCorporateActionsView extends StatelessWidget {
  const CompanyCorporateActionsView({super.key, required this.actions});

  final CompanyCorporateActions actions;

  Widget _item(CorporateActionItem item) {
    return GredentListTile(
      color: SharePerksColors.primary,
      style: GredentListTileStyle(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        border: const Border(),
        isThreeLine: item.date != null,
      ),
      title: Text(
        item.detail ?? item.type,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: SharePerksColors.textPrimaryLight,
        ),
      ),
      subtitle: item.date != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(
                    HugeIconsStroke.calendar03,
                    size: 11,
                    color: SharePerksColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    fmtIsoDate(item.date),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: SharePerksColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          : null,
      trailing: item.amount != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SharePerksColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(CompanyRadii.sm),
              ),
              child: Text(
                fmtRupees(item.amount),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: SharePerksColors.success,
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups =
        <({String title, IconData icon, List<CorporateActionItem> items})>[
          (
            title: 'Dividends',
            icon: HugeIconsSolid.rupee,
            items: actions.dividends,
          ),
          (
            title: 'Splits',
            icon: HugeIconsSolid.unlink02,
            items: actions.splits,
          ),
          (
            title: 'Bonuses',
            icon: HugeIconsSolid.giftCard,
            items: actions.bonuses,
          ),
          (
            title: 'Rights',
            icon: HugeIconsSolid.starCircle,
            items: actions.rights,
          ),
        ].where((group) => group.items.isNotEmpty).toList();

    if (groups.isEmpty) {
      return const _NothingPublished(
        icon: HugeIconsStroke.calendar03,
        message: 'No corporate actions recorded yet.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) const SizedBox(height: SharePerksSpacing.sm),
          _DisclosureGroup(
            title: groups[i].title,
            icon: groups[i].icon,
            itemCount: groups[i].items.length,
            itemBuilder: (context, index) => _item(groups[i].items[index]),
          ),
        ],
      ],
    );
  }
}

/// Segment revenue and profit. Periods arrive newest-first.
class CompanySegmentsView extends StatelessWidget {
  const CompanySegmentsView({super.key, required this.periods});

  final List<SegmentPeriod> periods;

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return const SectionEmptyNote(message: 'No segment data published.');
    }
    final latest = periods.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          latest.period,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: SharePerksColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: SharePerksSpacing.sm),
        CompanyDataTable(
          columns: const ['Revenue', 'Profit'],
          rows: [
            for (final segment in latest.segments)
              CompanyTableRowData(
                label: segment.name,
                values: [
                  fmtNum(segment.revenueCr, decimals: 0),
                  fmtNum(segment.profitCr, decimals: 0),
                ],
              ),
          ],
          labelWidth: 150,
          minColumnWidth: 90,
        ),
      ],
    );
  }
}
