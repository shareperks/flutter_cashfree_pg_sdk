import 'package:flutter/material.dart';
import 'package:shareperks/components/company/company_section.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/utils/company_format.dart';
import 'package:soui/elements/border_card.dart';

/// Shareholding pattern, with each category's holders folded away until asked
/// for, plus the latest promoter pledge.
///
/// Unlike the financial tables, shareholding cells are keyed by column label
/// rather than positional, so each row is built by walking `columns` and
/// looking the label up in the category's map.
class CompanyShareholdingView extends StatefulWidget {
  const CompanyShareholdingView({super.key, required this.data});

  final CompanyShareholding data;

  @override
  State<CompanyShareholdingView> createState() =>
      _CompanyShareholdingViewState();
}

class _CompanyShareholdingViewState extends State<CompanyShareholdingView> {
  /// Only the most recent periods fit on a phone; `columns` is chronological.
  static const int _maxColumns = 8;

  // Formatting every cell happens once, in [initState], instead of on each
  // rebuild; only the assembly of visible rows is redone when a group opens.
  late final List<String> _columns;
  late final List<_CategoryGroup> _groups;

  /// Which top-level categories are showing their holders. Collapsed by
  /// default: ITC's five categories carry 32 named funds between them, and a
  /// reader opening the section wants the five.
  final Set<int> _open = {};

  /// Newest period that actually carries a pledge figure.
  late final PledgeSummary? _latestPledge;

  @override
  void initState() {
    super.initState();
    final data = widget.data;

    _columns = data.columns.length > _maxColumns
        ? data.columns.sublist(data.columns.length - _maxColumns)
        : data.columns;

    _groups = [
      for (final category in data.categories)
        (
          name: category.name,
          values: [
            for (final column in _columns)
              fmtNum(category.values[column], decimals: 2),
          ],
          // Grandchildren are rare but real; they ride along under their
          // top-level category rather than nesting a second control.
          holders: _flattenHolders(category, 1),
        ),
    ];

    // `pledge` arrives in upstream order, which is not chronological, and its
    // last element is often an all-null row — so sort, then take the newest
    // period that reports a figure.
    _latestPledge =
        ([...data.pledge]..sort(
              (a, b) => periodOrder(a.period).compareTo(periodOrder(b.period)),
            ))
            .reversed
            .where((row) => row.pledgedPct != null)
            .firstOrNull;
  }

  List<CompanyTableRowData> _flattenHolders(
    ShareholdingCategory category,
    int depth,
  ) {
    final rows = <CompanyTableRowData>[];
    for (final holder in category.holders) {
      rows.add(
        CompanyTableRowData(
          label: holder.name,
          depth: depth,
          values: [
            for (final column in _columns)
              fmtNum(holder.values[column], decimals: 2),
          ],
        ),
      );
      rows.addAll(_flattenHolders(holder, depth + 1));
    }
    return rows;
  }

  /// Category rows, each followed by its holders when the group is open.
  List<CompanyTableRowData> get _visibleRows {
    final rows = <CompanyTableRowData>[];
    for (var i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      final hasHolders = group.holders.isNotEmpty;
      final open = _open.contains(i);

      rows.add(
        CompanyTableRowData(
          label: hasHolders
              ? '${group.name}  (${group.holders.length})'
              : group.name,
          values: group.values,
          expanded: hasHolders ? open : null,
          onToggle: hasHolders
              ? () => setState(() => open ? _open.remove(i) : _open.add(i))
              : null,
        ),
      );
      if (open) rows.addAll(group.holders);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompanyDataTable(
          columns: _columns,
          rows: _visibleRows,
          labelWidth: 150,
          scrollToLatest: true,
          // The groups are the row control here; a second "Show all N rows"
          // toggle underneath would be answering the same question twice.
          initialRowLimit: null,
        ),
        if (_groups.any((g) => g.holders.isNotEmpty)) ...[
          const SizedBox(height: 6),
          Text(
            _open.isEmpty
                ? 'Tap a category to see who holds it'
                : 'Tap a category to collapse it',
            style: const TextStyle(
              fontSize: 11,
              color: SharePerksColors.textSecondaryLight,
            ),
          ),
        ],
        if (_latestPledge != null) ...[
          const SizedBox(height: SharePerksSpacing.md),
          BorderCard(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            borderRadius: CompanyRadii.md,
            borderWidth: 1,
            color: SharePerksColors.primary.withAlpha(20),
            backgroundColor: SharePerksColors.surfaceLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promoters have pledged '
                  '${fmtPct(_latestPledge.pledgedPct, decimals: 2)} of their '
                  'holding as of ${_latestPledge.period}.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pledgeToneColor(_latestPledge.pledgedPct),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (_latestPledge.lockedInPct != null)
                      'Locked in ${fmtPct(_latestPledge.lockedInPct, decimals: 2)}',
                    if (_latestPledge.totalShareholders != null)
                      '${fmtNum(_latestPledge.totalShareholders, decimals: 0)} shareholders',
                  ].join('  ·  '),
                  style: const TextStyle(
                    fontSize: 11,
                    color: SharePerksColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One shareholding category: its own percentages, and the holders filed under
/// it, pre-formatted.
typedef _CategoryGroup = ({
  String name,
  List<String> values,
  List<CompanyTableRowData> holders,
});
