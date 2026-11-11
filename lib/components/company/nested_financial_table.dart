import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Renders a structured statement (P&L, quarterly, balance sheet) as a
/// horizontally-scrollable table with expandable/collapsible nested rows.
///
/// Row definitions come from the API's `ui.rows` array — each row has a
/// `valueKey` dot-path (e.g. `display.revenue`) that is resolved against
/// each period object to extract the cell value. Rows with `expandable:
/// true` can be tapped to reveal their `children`.
///
/// The first column ("Particulars") is frozen; all other columns scroll
/// horizontally.
class NestedFinancialTable extends StatefulWidget {
  const NestedFinancialTable({
    super.key,
    required this.statement,
    this.maxColumns = 10,
  });

  final ScreenerStatement statement;

  /// Maximum number of period columns to show (newest first).
  final int maxColumns;

  @override
  State<NestedFinancialTable> createState() => _NestedFinancialTableState();
}

class _NestedFinancialTableState extends State<NestedFinancialTable> {
  final Set<String> _expanded = {};

  /// Periods to display (newest first, capped at [maxColumns]).
  List<ScreenerPeriod> get _periods {
    final all = widget.statement.periods;
    if (all.length <= widget.maxColumns) {
      return all.reversed.toList();
    }
    return all.reversed.take(widget.maxColumns).toList();
  }

  @override
  void initState() {
    super.initState();
    // Start with default-expanded rows open.
    _initExpanded(widget.statement.rows);
  }

  void _initExpanded(List<ScreenerRowDef> rows) {
    for (final row in rows) {
      if (row.defaultExpanded) _expanded.add(row.id);
      if (row.children.isNotEmpty) _initExpanded(row.children);
    }
  }

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
    if (widget.statement.isEmpty) {
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
    final labelWidth = 150.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: labelWidth + (periods.length * columnWidth),
        child: Column(
          children: [
            // Header row
            _headerRow(periods, labelWidth, columnWidth),
            const Divider(height: 1, color: SharePerksColors.borderLight),
            // Data rows
            ..._buildRows(
              widget.statement.rows,
              0,
              periods,
              labelWidth,
              columnWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(
    List<ScreenerPeriod> periods,
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
                p.label,
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

  List<Widget> _buildRows(
    List<ScreenerRowDef> rows,
    int level,
    List<ScreenerPeriod> periods,
    double labelWidth,
    double columnWidth,
  ) {
    final widgets = <Widget>[];
    for (final row in rows) {
      final isExpanded = _expanded.contains(row.id);
      widgets.add(
        _buildRow(row, level, periods, labelWidth, columnWidth, isExpanded),
      );
      if (row.children.isNotEmpty && isExpanded) {
        widgets.addAll(
          _buildRows(row.children, level + 1, periods, labelWidth, columnWidth),
        );
      }
    }
    return widgets;
  }

  Widget _buildRow(
    ScreenerRowDef row,
    int level,
    List<ScreenerPeriod> periods,
    double labelWidth,
    double columnWidth,
    bool isExpanded,
  ) {
    final indent = level * 12.0;
    final isBold = row.type.isBold;
    final isHighlight = row.highlight;

    return InkWell(
      onTap: row.expandable ? () => _toggle(row.id) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isHighlight
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
            // Label column
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
                    if (!row.expandable && level > 0) const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isBold
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: row.type.isPercentage
                              ? SharePerksColors.textSecondaryLight
                              : SharePerksColors.textPrimaryLight,
                          fontFamily: SharePerksFonts.inter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Value columns
            ...periods.map((p) {
              final value = p.value(row.valueKey);
              return SizedBox(
                width: columnWidth,
                child: Text(
                  _formatValue(value, row.type),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
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

  /// Formats a value based on row type.
  String _formatValue(double? value, ScreenerRowType type) {
    if (value == null) return '—';
    if (type.isPercentage) {
      return '${value.toStringAsFixed(2)}%';
    }
    if (type.isPerShare) {
      return value.toStringAsFixed(2);
    }
    // Crore values — format with up to 2 decimal places, trimming trailing zeros.
    if (value.abs() >= 1000) {
      return value.toStringAsFixed(0);
    } else if (value.abs() >= 100) {
      return value.toStringAsFixed(1);
    } else if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
