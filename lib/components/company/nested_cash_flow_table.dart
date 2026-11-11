import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Renders a cash flow statement. Unlike [NestedFinancialTable], cash flow
/// rows have values keyed by period label (not dot-paths) and values are in
/// **rupees** (not crores) — so they're divided by 10,000,000 for display.
///
/// Rows are grouped by section (operating, investing, financing, summary)
/// with section headers. All-zero rows are hidden except the always-shown
/// totals.
class NestedCashFlowTable extends StatefulWidget {
  const NestedCashFlowTable({
    super.key,
    required this.cashFlow,
    this.quarterly = false,
    this.maxColumns = 8,
  });

  final ScreenerCashFlow cashFlow;
  final bool quarterly;
  final int maxColumns;

  @override
  State<NestedCashFlowTable> createState() => _NestedCashFlowTableState();
}

class _NestedCashFlowTableState extends State<NestedCashFlowTable> {
  final Set<String> _expanded = {};

  List<String> get _periods {
    final all = widget.quarterly
        ? widget.cashFlow.quarterlyPeriods
        : widget.cashFlow.annualPeriods;
    if (all.length <= widget.maxColumns) {
      return all.reversed.toList();
    }
    return all.reversed.take(widget.maxColumns).toList();
  }

  List<ScreenerCashFlowRow> get _rows =>
      widget.cashFlow.visibleRows(widget.quarterly);

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final periods = _periods;
    if (widget.cashFlow.isEmpty || periods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize: 12,
            color: SharePerksColors.textSecondaryLight,
          ),
        ),
      );
    }

    final columnWidth = 95.0;
    final labelWidth = 160.0;

    // Group rows by section.
    final sections = <String, List<ScreenerCashFlowRow>>{};
    for (final row in _rows) {
      sections.putIfAbsent(row.section, () => []).add(row);
    }
    const sectionOrder = ['operating', 'investing', 'financing', 'summary'];
    const sectionLabels = {
      'operating': 'OPERATING',
      'investing': 'INVESTING',
      'financing': 'FINANCING',
      'summary': 'SUMMARY',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: labelWidth + (periods.length * columnWidth),
        child: Column(
          children: [
            // Header
            _headerRow(periods, labelWidth, columnWidth),
            const Divider(height: 1, color: SharePerksColors.borderLight),
            // Sections
            for (final sectionKey in sectionOrder)
              if (sections.containsKey(sectionKey)) ...[
                _sectionHeader(
                  sectionLabels[sectionKey]!,
                  labelWidth,
                  periods.length,
                  columnWidth,
                ),
                for (final row in sections[sectionKey]!)
                  _buildRow(row, periods, labelWidth, columnWidth),
              ],
          ],
        ),
      ),
    );
  }

  Widget _headerRow(
    List<String> periods,
    double labelWidth,
    double columnWidth,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: const BoxDecoration(
        color: SharePerksColors.surfaceLight,
        border: Border(bottom: BorderSide(color: SharePerksColors.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: const Text(
              'Particulars',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SharePerksColors.textSecondaryLight,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
          ),
          ...periods.map(
            (p) => SizedBox(
              width: columnWidth,
              child: Text(
                p,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SharePerksColors.textSecondaryLight,
                  fontFamily: SharePerksFonts.inter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String label,
    double labelWidth,
    int periodCount,
    double columnWidth,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      color: SharePerksColors.surfaceLight,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: SharePerksColors.textSecondaryLight,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
          ),
          SizedBox(width: periodCount * columnWidth),
        ],
      ),
    );
  }

  Widget _buildRow(
    ScreenerCashFlowRow row,
    List<String> periods,
    double labelWidth,
    double columnWidth,
  ) {
    final isExpanded = _expanded.contains(row.id);
    final indent = row.level * 12.0;

    return InkWell(
      onTap: row.expandable ? () => _toggle(row.id) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: row.highlight
              ? SharePerksColors.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: SharePerksColors.borderLight.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: EdgeInsets.only(left: indent),
                child: Row(
                  children: [
                    if (row.expandable)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 14,
                          color: SharePerksColors.textSecondaryLight,
                        ),
                      ),
                    if (!row.expandable && row.level > 0)
                      const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: row.highlight
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: SharePerksColors.textPrimaryLight,
                          fontFamily: SharePerksFonts.inter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...periods.map((p) {
              final value = row.values[p];
              return SizedBox(
                width: columnWidth,
                child: Text(
                  _formatCrore(value),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: row.highlight
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: value != null
                        ? SharePerksColors.textPrimaryLight
                        : SharePerksColors.textSecondaryLight.withValues(
                            alpha: 0.4,
                          ),
                    fontFamily: SharePerksFonts.inter,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Cash flow values are in rupees — convert to crore for display.
  String _formatCrore(double? value) {
    if (value == null || value == 0) return '—';
    final crore = value / 10000000;
    if (crore.abs() >= 1000) {
      return crore.toStringAsFixed(0);
    } else if (crore.abs() >= 100) {
      return crore.toStringAsFixed(1);
    } else if (crore == crore.roundToDouble()) {
      return crore.toStringAsFixed(0);
    }
    return crore.toStringAsFixed(2);
  }
}
