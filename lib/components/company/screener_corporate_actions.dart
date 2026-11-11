import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Corporate actions section — Section 13 of the screener guide.
///
/// Shows four sub-sections: Dividends (table with Date, Type, Amount, Adj
/// Amount), Splits, Bonuses, and Rights (each a list with description and
/// date). Each section shows the first 5 records by default with a "View All"
/// expand button.
class ScreenerCorporateActionsSection extends StatelessWidget {
  const ScreenerCorporateActionsSection({super.key, required this.actions});

  final ScreenerCorporateActions actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Text(
        'No corporate actions data available.',
        style: TextStyle(
          fontSize: 12,
          color: SharePerksColors.textSecondaryLight,
          fontFamily: SharePerksFonts.inter,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (actions.dividends.isNotEmpty) ...[
          _sectionTitle('Dividends'),
          const SizedBox(height: SharePerksSpacing.sm),
          _DividendsTable(dividends: actions.dividends),
          const SizedBox(height: SharePerksSpacing.lg),
        ],
        if (actions.splits.isNotEmpty) ...[
          _sectionTitle('Splits'),
          const SizedBox(height: SharePerksSpacing.sm),
          _ActionList(actions: actions.splits),
          const SizedBox(height: SharePerksSpacing.lg),
        ],
        if (actions.bonuses.isNotEmpty) ...[
          _sectionTitle('Bonuses'),
          const SizedBox(height: SharePerksSpacing.sm),
          _ActionList(actions: actions.bonuses),
          const SizedBox(height: SharePerksSpacing.lg),
        ],
        if (actions.rights.isNotEmpty) ...[
          _sectionTitle('Rights'),
          const SizedBox(height: SharePerksSpacing.sm),
          _ActionList(actions: actions.rights),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: SharePerksColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: SharePerksFonts.albertSans,
            color: SharePerksColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

// ── dividends table ──────────────────────────────────────────────────────────

class _DividendsTable extends StatefulWidget {
  const _DividendsTable({required this.dividends});

  final List<ScreenerDividend> dividends;

  @override
  State<_DividendsTable> createState() => _DividendsTableState();
}

class _DividendsTableState extends State<_DividendsTable> {
  bool _expanded = false;
  static const _defaultCount = 5;

  @override
  Widget build(BuildContext context) {
    final visible = _expanded || widget.dividends.length <= _defaultCount
        ? widget.dividends
        : widget.dividends.sublist(0, _defaultCount);
    final hiddenCount = widget.dividends.length - visible.length;

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
                  _dataRow(visible[i], i),
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
    return Container(
      decoration: const BoxDecoration(
        color: SharePerksColors.surfaceLight,
        border: Border(bottom: BorderSide(color: SharePerksColors.borderLight)),
      ),
      child: Row(
        children: [
          _cell('Date', isHeader: true, isLabel: true, width: 110),
          _cell('Type', isHeader: true, isLabel: true, width: 120),
          _cell('Amount', isHeader: true, width: 85),
          _cell('Adj Amount', isHeader: true, width: 100),
        ],
      ),
    );
  }

  Widget _dataRow(ScreenerDividend div, int index) {
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
          _cell(div.date ?? '—', isLabel: true, width: 110),
          _cell(div.type ?? '—', isLabel: true, width: 120),
          _cell(_fmtAmount(div.amount), width: 85),
          _cell(_fmtAmount(div.adjAmount), width: 100),
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

  static String _fmtAmount(double? v) =>
      v == null ? '—' : '₹${v.toStringAsFixed(2)}';
}

// ── action list (splits, bonuses, rights) ────────────────────────────────────

class _ActionList extends StatefulWidget {
  const _ActionList({required this.actions});

  final List<ScreenerCorporateAction> actions;

  @override
  State<_ActionList> createState() => _ActionListState();
}

class _ActionListState extends State<_ActionList> {
  bool _expanded = false;
  static const _defaultCount = 5;

  @override
  Widget build(BuildContext context) {
    final visible = _expanded || widget.actions.length <= _defaultCount
        ? widget.actions
        : widget.actions.sublist(0, _defaultCount);
    final hiddenCount = widget.actions.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++) _actionItem(visible[i], i),
        if (hiddenCount > 0 || _expanded) ...[
          const SizedBox(height: SharePerksSpacing.sm),
          _expandButton(hiddenCount),
        ],
      ],
    );
  }

  Widget _actionItem(ScreenerCorporateAction action, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: SharePerksColors.surfaceLight,
        borderRadius: BorderRadius.circular(CompanyRadii.sm),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              action.description.isEmpty ? '—' : action.description,
              style: const TextStyle(
                fontSize: 11,
                color: SharePerksColors.textPrimaryLight,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            action.date ?? '—',
            style: const TextStyle(
              fontSize: 10,
              color: SharePerksColors.textSecondaryLight,
              fontFamily: SharePerksFonts.inter,
            ),
          ),
        ],
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
}
