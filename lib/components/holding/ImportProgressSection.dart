import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class ImportProgressSection extends StatelessWidget {
  const ImportProgressSection({
    super.key,
    this.title = 'Holding statement import in progress',
    this.description =
        'We’re importing your statement and unlocking eligible perks. This usually takes a moment.',
    this.progress,
    this.backgroundColor = Colors.white,
  });

  /// Heading text shown above the progress bar.
  final String title;

  /// Supporting text shown below the title.
  final String description;

  /// If null, shows an indeterminate progress bar.
  /// If provided, should be in 0..1.
  final double? progress;

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final value = progress == null
        ? null
        : progress!.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: SharePerksColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 18,
                  color: SharePerksColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 13,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 11.5,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: SharePerksColors.borderLight.withAlpha(70),
              valueColor: AlwaysStoppedAnimation<Color>(
                SharePerksColors.primary,
              ),
            ),
          ),
          if (value != null) ...[
            const SizedBox(height: 8),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 11,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
