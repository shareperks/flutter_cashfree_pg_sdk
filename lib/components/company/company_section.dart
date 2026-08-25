import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/utils/company_format.dart';
import 'package:soui/elements/border_card.dart';

/// Card shell every company section sits in — title, optional caption, body.
class CompanySection extends StatelessWidget {
  const CompanySection({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
    required this.child,
    // Horizontally tight on purpose: every pixel spent on card padding is a
    // pixel the figures inside the table lose twice over (page padding, then
    // card padding). Vertical spacing is left alone — that costs nothing.
    this.padding = const EdgeInsets.fromLTRB(10, 12, 10, 12),
  });

  final String title;
  final String? caption;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      width: double.infinity,
      borderRadius: CompanyRadii.lg,
      borderWidth: 1,
      color: SharePerksColors.primary.withAlpha(20),
      backgroundColor: SharePerksColors.backgroundLight,
      // boxShadow: SharePerksShadows.sm,
      padding: padding,
      isGradientBackground: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: SharePerksFonts.albertSans,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SharePerksColors.textPrimaryLight,
                      ),
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        caption!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SharePerksColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// A section the service could not build — named in `unavailable`, or a null
/// section object. Always offer a retry so it does not read as "no data".
class SectionUnavailable extends StatelessWidget {
  const SectionUnavailable({
    super.key,
    required this.title,
    this.message = 'We could not load this section.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return CompanySection(
      title: title,
      child: Row(
        children: [
          const Icon(
            HugeIconsStroke.alert02,
            size: 18,
            color: SharePerksColors.warning,
          ),
          const SizedBox(width: SharePerksSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: SharePerksColors.textSecondaryLight,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

/// The service's `unavailable` keys, in the wording the section headings use.
const Map<String, String> kCompanySectionLabels = {
  'profitAndLoss': 'Profit & Loss',
  'quarterlyResults': 'Quarterly Results',
  'balanceSheet': 'Balance Sheet',
  'cashFlow': 'Cash Flow',
  'ratios': 'Ratios',
  'growth': 'Compounded Growth',
  'shareholding': 'Shareholding Pattern',
  'peers': 'Peer Comparison',
};

String companySectionLabel(String key) => kCompanySectionLabels[key] ?? key;

/// Sections the page bundle could not build, named up front.
///
/// The page degrades section by section, so without this a reader has to
/// scroll into a tab to discover something is missing — and a missing section
/// is indistinguishable from a company that never published one.
class CompanyUnavailableBanner extends StatelessWidget {
  const CompanyUnavailableBanner({
    super.key,
    required this.sections,
    this.onRetry,
  });

  final List<String> sections;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();
    final names = sections.map(companySectionLabel).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: SharePerksColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(CompanyRadii.md),
        border: Border.all(
          color: SharePerksColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              HugeIconsStroke.alert02,
              size: 16,
              color: SharePerksColors.warning,
            ),
          ),
          const SizedBox(width: SharePerksSpacing.sm),
          Expanded(
            child: Text(
              'Some sections could not be loaded: $names.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: SharePerksColors.textPrimaryLight,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Try again',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

/// Placeholder for a section that legitimately has nothing to show — an empty
/// document list is "no filings", not a failure.
class SectionEmptyNote extends StatelessWidget {
  const SectionEmptyNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        fontSize: 12,
        color: SharePerksColors.textSecondaryLight,
      ),
    );
  }
}

class CompanyTableRowData {
  const CompanyTableRowData({
    required this.label,
    required this.values,
    this.depth = 0,
    this.highlight = false,
    this.expanded,
    this.onToggle,
  });

  final String label;

  /// Pre-formatted cells, positionally aligned with the table's columns.
  /// Formatting happens once, off the build path, so scrolling never re-runs
  /// number formatting.
  final List<String> values;

  /// Indent level for nested rows (shareholding breakdowns).
  final int depth;

  /// Renders the row bold — used for the company's own row in peers.
  final bool highlight;

  /// Whether this row's children are showing. Null for rows that have none.
  final bool? expanded;

  /// Shows or hides this row's children. When set, the label cell becomes a
  /// tap target with a chevron.
  final VoidCallback? onToggle;

  bool get isParent => onToggle != null;
}

/// Screener-style table: a pinned label column plus horizontally scrolling
/// period columns, with zebra striping, tabular figures and an edge shadow
/// that shows the label column is pinned.
///
/// **Why it is built column-first.** A quarterly P&L here is 41 rows by 34
/// periods — around 1,400 cells — and roughly three quarters sit off-screen to
/// the right. So the scrolling half is a horizontal `ListView.builder` whose
/// *items are whole columns*: only the periods actually on screen are built,
/// and a fixed `itemExtent` keeps the list's layout O(1) instead of measuring
/// every column.
///
/// The vertical axis is capped by [initialRowLimit] rather than made
/// scrollable, because a nested vertical scroll inside the page's own list
/// fights the user's thumb. Long tables get a "Show all" affordance instead.
class CompanyDataTable extends StatefulWidget {
  const CompanyDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.labelWidth = 132,
    this.minColumnWidth = 78,
    this.initialRowLimit = 12,
    this.scrollToLatest = false,
  });

  final List<String> columns;
  final List<CompanyTableRowData> rows;

  /// Preferred width of the pinned label column. Capped at 45% of the table on
  /// narrow phones so the figures never lose more than they can spare.
  final double labelWidth;

  /// Narrowest a value column may get. The real width is derived from it: only
  /// whole columns are ever shown, so a figure is never sliced down the middle
  /// at the right edge.
  final double minColumnWidth;

  /// Rows rendered before the "Show all" toggle. `null` always renders every
  /// row.
  final int? initialRowLimit;

  /// Opens scrolled to the right-most column. Period tables run oldest → newest
  /// so the newest quarter would otherwise start off-screen; metric tables
  /// (peers, segments) want their first column instead.
  final bool scrollToLatest;

  @override
  State<CompanyDataTable> createState() => _CompanyDataTableState();
}

class _CompanyDataTableState extends State<CompanyDataTable> {
  bool _expanded = false;
  final ScrollController _horizontal = ScrollController();

  static const Color _stripe = Color(0xFFF8FAFC);
  static const Color _headerFill = Color(0xFFF1F5F9);

  // Cell styles are pre-built constants rather than `copyWith` calls: a
  // `copyWith` per cell allocates a TextStyle for every one of several hundred
  // cells on every build. Figures are tabular so digits line up in a column.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: SharePerksColors.textSecondaryLight,
    fontFeatures: _tabular,
  );
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12,
    color: SharePerksColors.textPrimaryLight,
  );
  static const TextStyle _labelNestedStyle = TextStyle(
    fontSize: 11.5,
    color: SharePerksColors.textSecondaryLight,
  );
  static const TextStyle _labelBoldStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: SharePerksColors.textPrimaryLight,
  );
  static const TextStyle _valueStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SharePerksColors.textPrimaryLight,
    fontFeatures: _tabular,
  );
  static const TextStyle _valueNegativeStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SharePerksColors.error,
    fontFeatures: _tabular,
  );
  static const TextStyle _valueEmptyStyle = TextStyle(
    fontSize: 12,
    color: SharePerksColors.textSecondaryLight,
    fontFeatures: _tabular,
  );
  static const TextStyle _valueBoldStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: SharePerksColors.textPrimaryLight,
    fontFeatures: _tabular,
  );
  static const TextStyle _valueBoldNegativeStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: SharePerksColors.error,
    fontFeatures: _tabular,
  );

  static const BoxDecoration _headerDecoration = BoxDecoration(
    color: _headerFill,
    border: Border(
      bottom: BorderSide(color: SharePerksColors.borderLight, width: 1),
    ),
  );
  static const BoxDecoration _rowPlain = BoxDecoration(
    border: Border(
      bottom: BorderSide(color: SharePerksColors.borderLight, width: 0.5),
    ),
  );
  static const BoxDecoration _rowStriped = BoxDecoration(
    color: _stripe,
    border: Border(
      bottom: BorderSide(color: SharePerksColors.borderLight, width: 0.5),
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.scrollToLatest) {
      // Periods run oldest → newest, so the useful end is the far right.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_horizontal.hasClients) return;
        _horizontal.jumpTo(_horizontal.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  TextStyle _styleFor(String value, bool highlight) {
    if (value == kEmDash) return _valueEmptyStyle;
    final negative = value.startsWith('-');
    if (highlight) return negative ? _valueBoldNegativeStyle : _valueBoldStyle;
    return negative ? _valueNegativeStyle : _valueStyle;
  }

  BoxDecoration _rowDecoration(int index) =>
      index.isOdd ? _rowStriped : _rowPlain;

  List<CompanyTableRowData> get _visibleRows {
    final limit = widget.initialRowLimit;
    if (_expanded || limit == null || widget.rows.length <= limit) {
      return widget.rows;
    }
    return widget.rows.sublist(0, limit);
  }

  Widget _labelColumn(List<CompanyTableRowData> rows, _TableMetrics m) {
    return SizedBox(
      width: m.labelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: m.headerHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: _headerDecoration,
          ),
          for (var i = 0; i < rows.length; i++) _labelCell(rows[i], i, m),
        ],
      ),
    );
  }

  Widget _labelCell(CompanyTableRowData row, int index, _TableMetrics m) {
    final label = Row(
      children: [
        if (row.isParent) ...[
          // Rotated rather than swapped so the chevron turns instead of
          // popping between two glyphs.
          AnimatedRotation(
            duration: const Duration(milliseconds: 150),
            turns: (row.expanded ?? false) ? 0.25 : 0,
            child: const Icon(
              HugeIconsStroke.arrowRight01,
              size: 13,
              color: SharePerksColors.primary,
            ),
          ),
          const SizedBox(width: 4),
        ] else if (row.depth > 0) ...[
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: SharePerksColors.textSecondaryLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            row.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: row.highlight || row.isParent
                ? _labelBoldStyle
                : (row.depth > 0 ? _labelNestedStyle : _labelStyle),
          ),
        ),
      ],
    );

    return Container(
      height: m.rowHeight,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        left: 8 + row.depth * 10.0,
        right: SharePerksSpacing.sm,
      ),
      decoration: _rowDecoration(index),
      child: row.isParent ? InkWell(onTap: row.onToggle, child: label) : label,
    );
  }

  /// One period: its header cell plus that period's value in every visible row.
  Widget _column(int index, List<CompanyTableRowData> rows, _TableMetrics m) {
    return Column(
      children: [
        Container(
          height: m.headerHeight,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 8),
          decoration: _headerDecoration,
          // Quarterly labels repeat ("2025", "2025"), so columns are addressed
          // by index and never looked up by label.
          child: Text(
            widget.columns[index],
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: _headerStyle,
          ),
        ),
        for (var i = 0; i < rows.length; i++)
          Container(
            height: m.rowHeight,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            decoration: _rowDecoration(i),
            child: Text(
              index < rows[i].values.length ? rows[i].values[index] : kEmDash,
              // Row heights are fixed so the two halves of the table stay in
              // step; an unusually wide figure must stay on one line rather
              // than wrap and overflow it.
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: index < rows[i].values.length
                  ? _styleFor(rows[i].values[index], rows[i].highlight)
                  : _valueEmptyStyle,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.columns.isEmpty || widget.rows.isEmpty) {
      return const SectionEmptyNote(message: 'No data published yet.');
    }

    final rows = _visibleRows;
    final hiddenRows = widget.rows.length - rows.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final m = _TableMetrics.resolve(
          context: context,
          available: constraints.maxWidth,
          preferredLabelWidth: widget.labelWidth,
          minColumnWidth: widget.minColumnWidth,
          columnCount: widget.columns.length,
        );
        final bodyHeight = m.headerHeight + rows.length * m.rowHeight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A table is hundreds of Text widgets; isolating it keeps scrolling
            // the page from repainting all of them.
            RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CompanyRadii.md),
                child: Container(
                  // The height goes on the inner box, not here: a Container's
                  // border insets its child, so a fixed height plus a 1px
                  // border overflows the content by exactly 2 pixels.
                  decoration: BoxDecoration(
                    border: Border.all(color: SharePerksColors.borderLight),
                    borderRadius: BorderRadius.circular(CompanyRadii.md),
                  ),
                  child: SizedBox(
                    height: bodyHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelColumn(rows, m),
                        Expanded(
                          child: ListView.builder(
                            controller: _horizontal,
                            scrollDirection: Axis.horizontal,
                            // Fixed extent: the list computes any column's
                            // offset arithmetically instead of laying out its
                            // predecessors.
                            itemExtent: m.columnWidth,
                            itemCount: widget.columns.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) =>
                                _column(index, rows, m),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (hiddenRows > 0 || _expanded)
              Align(
                alignment: Alignment.centerLeft,
                child: _toggle(
                  expanded: _expanded,
                  label: _expanded
                      ? 'Show less'
                      : 'Show all ${widget.rows.length} rows',
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _toggle({
    required bool expanded,
    required String label,
    required VoidCallback onPressed,
  }) {
    const color = SharePerksColors.primary;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        expanded ? HugeIconsStroke.arrowUp01 : HugeIconsStroke.arrowDown01,
        size: 14,
        color: color,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Table sizing worked out from the width actually available and the reader's
/// font-size setting, instead of hard-coded pixels.
///
/// Two things this gets right that fixed sizes could not: value columns divide
/// the leftover width evenly so only whole columns are visible — a figure is
/// never sliced in half at the right edge — and row heights grow with the
/// system text scale, so a two-line label like "Depreciation And Amortisation"
/// still fits on a phone with large text turned on.
class _TableMetrics {
  const _TableMetrics({
    required this.labelWidth,
    required this.columnWidth,
    required this.rowHeight,
    required this.headerHeight,
  });

  final double labelWidth;
  final double columnWidth;
  final double rowHeight;
  final double headerHeight;

  static _TableMetrics resolve({
    required BuildContext context,
    required double available,
    required double preferredLabelWidth,
    required double minColumnWidth,
    required int columnCount,
  }) {
    final scaler = MediaQuery.textScalerOf(context);

    // Labels take a share of the width rather than a fixed slice: on a 320dp
    // phone a 132px label column would leave room for a single value column.
    final upperLabelWidth = math.max(96.0, preferredLabelWidth);
    final labelWidth = (available * 0.38).clamp(96.0, upperLabelWidth);
    final forValues = available - labelWidth;

    // How many whole columns fit, then share the width out between them.
    var visibleColumns = (forValues / minColumnWidth).floor();
    if (visibleColumns < 1) visibleColumns = 1;
    if (visibleColumns > columnCount) visibleColumns = columnCount;
    final columnWidth = forValues / visibleColumns;

    // Two lines of label text plus padding, and one line in the header.
    final rowHeight = scaler.scale(12) * 2 * 1.3 + 12;
    final headerHeight = scaler.scale(11) * 1.3 + 16;

    return _TableMetrics(
      labelWidth: labelWidth,
      columnWidth: columnWidth,
      rowHeight: rowHeight,
      headerHeight: headerHeight,
    );
  }
}
