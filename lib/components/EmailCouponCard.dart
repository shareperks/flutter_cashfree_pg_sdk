import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/email_coupon_model.dart';

class EmailCouponCard extends StatelessWidget {
  const EmailCouponCard({super.key, required this.coupon});

  final EmailCoupon coupon;

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    Fluttertoast.showToast(
      msg: 'Coupon code copied',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = coupon.couponCode?.trim();
    final hasCode = code != null && code.isNotEmpty;
    final subtitle = coupon.displaySubtitle;
    final validTill = coupon.validTill?.trim();
    final eligibility = coupon.eligibility?.trim();
    final notes = coupon.notes?.trim();
    final pin = coupon.pin?.trim();
    final source = coupon.source?.trim();
    final gmail = coupon.gmailUser?.email?.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SharePerksColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  HugeIconsSolid.couponPercent,
                  size: 20,
                  color: SharePerksColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.displayTitle,
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 14,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: SharePerksColors.textSecondaryLight,
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (validTill != null && validTill.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SharePerksColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Till $validTill',
                    style: TextStyle(
                      color: SharePerksColors.textSecondaryLight,
                      fontSize: 10,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (hasCode) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _copyCode(code),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: SharePerksColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SharePerksColors.primary.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: TextStyle(
                          color: SharePerksColors.primary,
                          fontSize: 15,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Icon(
                      HugeIconsStroke.copy01,
                      size: 18,
                      color: SharePerksColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (pin != null && pin.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'PIN: $pin',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((eligibility != null && eligibility.isNotEmpty) ||
              (notes != null && notes.isNotEmpty)) ...[
            const SizedBox(height: 8),
            if (eligibility != null && eligibility.isNotEmpty)
              Text(
                eligibility,
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 11,
                  fontFamily: SharePerksFonts.inter,
                ),
              ),
            if (notes != null && notes.isNotEmpty) ...[
              if (eligibility != null && eligibility.isNotEmpty)
                const SizedBox(height: 4),
              Text(
                notes,
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 11,
                  fontFamily: SharePerksFonts.inter,
                ),
              ),
            ],
          ],
          if ((source != null &&
                  source.isNotEmpty &&
                  source != coupon.displayTitle) ||
              (gmail != null && gmail.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (source != null &&
                    source.isNotEmpty &&
                    source != coupon.displayTitle)
                  'via $source',
                if (gmail != null && gmail.isNotEmpty) gmail,
              ].join(' · '),
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight.withValues(
                  alpha: 0.85,
                ),
                fontSize: 10,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
