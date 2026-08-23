import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/utils/company_format.dart';

/// Compounded growth blocks. The window order is fixed here rather than taken
/// from the response, because map key order is an implementation detail and
/// "10 Years" should always be the first row.
class CompanyGrowthBlocks extends StatelessWidget {
  const CompanyGrowthBlocks({super.key, required this.growth});

  final CompanyGrowth growth;

  static const List<String> _windows = [
    '10 Years',
    '5 Years',
    '3 Years',
    '1 Year',
  ];

  @override
  Widget build(BuildContext context) {
    final blocks = <({String title, GrowthBlock block})>[
      (title: 'Compounded Sales Growth', block: growth.sales),
      (title: 'Compounded Profit Growth', block: growth.profit),
      (title: 'Stock Price CAGR', block: growth.stockPrice),
      // Average ROE over each window, not a CAGR.
      (title: 'Return on Equity', block: growth.returnOnEquity),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = SharePerksSpacing.sm;
        final width = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in blocks)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SharePerksColors.surfaceLight,
                    borderRadius: BorderRadius.circular(CompanyRadii.md),
                    border: Border.all(color: SharePerksColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SharePerksColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final window in _windows)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                window,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: SharePerksColors.textSecondaryLight,
                                ),
                              ),
                              Text(
                                fmtPct(item.block[window]),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: item.block[window] == null
                                      ? SharePerksColors.textSecondaryLight
                                      : signColor(item.block[window]),
                                ),
                              ),
                            ],
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
