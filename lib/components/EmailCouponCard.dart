import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/EmailCouponNetworkImage.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/email_coupon_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailCouponCard extends StatelessWidget {
  const EmailCouponCard({
    super.key,
    required this.coupon,
    this.onUsedChanged,
  });

  final EmailCoupon coupon;
  final ValueChanged<EmailCoupon>? onUsedChanged;

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    Fluttertoast.showToast(
      msg: 'Coupon code copied',
      backgroundColor: SharePerksColors.success,
      textColor: Colors.white,
    );
  }

  Future<void> _openRedeemUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      Fluttertoast.showToast(msg: 'Invalid redeem link');
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        Fluttertoast.showToast(msg: 'Could not open redeem link');
      }
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not open redeem link');
    }
  }

  Future<void> _openDetail(BuildContext context) async {
    final result = await context.pushNamed<EmailCoupon>(
      RouteNames.EMAIL_COUPON_DETAIL_SCREEN,
      extra: coupon,
    );
    if (result != null) {
      onUsedChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = coupon.couponCode?.trim();
    final hasCode = code != null && code.isNotEmpty;
    final brand = coupon.displayBrand;
    final subtitle = coupon.displaySubtitle;
    final description = coupon.description?.trim();
    final price = coupon.price?.trim();
    final maxDiscount = coupon.maximumDiscount?.trim();
    final offerLine = (subtitle.isNotEmpty && subtitle != maxDiscount)
        ? subtitle
        : '';
    final discountLine = (maxDiscount != null && maxDiscount.isNotEmpty)
        ? maxDiscount
        : offerLine;
    final validity = coupon.validityLabel;
    final pin = coupon.pin?.trim();
    final redeemUrl = coupon.redeemUrl?.trim();
    final hasRedeemUrl = redeemUrl != null && redeemUrl.isNotEmpty;
    final imageUrl = coupon.displayImage;
    final isUsed = coupon.used;

    final borderColor = isUsed
        ? SharePerksColors.borderLight
        : SharePerksColors.primary.withValues(alpha: 0.22);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isUsed ? 0.78 : 1,
      child: Material(
        color: SharePerksColors.backgroundLight,
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        child: InkWell(
          onTap: () => _openDetail(context),
          borderRadius: BorderRadius.circular(SharePerksRadii.lg),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SharePerksRadii.lg),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Thumb(imageUrl: imageUrl, used: isUsed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coupon.displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SharePerksColors.textPrimaryLight,
                                fontSize: 15,
                                fontFamily: SharePerksFonts.albertSans,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            if (brand.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: SharePerksColors.primary,
                                  fontSize: 12,
                                  fontFamily: SharePerksFonts.inter,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (discountLine.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                discountLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: SharePerksColors.accent,
                                  fontSize: 14,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if ((price != null && price.isNotEmpty) ||
                      validity.isNotEmpty ||
                      isUsed) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (price != null && price.isNotEmpty)
                          _InfoChip(
                            icon: HugeIconsSolid.shoppingBag01,
                            label: 'Min $price',
                            foreground: SharePerksColors.textSecondaryLight,
                            background: SharePerksColors.surfaceLight,
                          ),
                        if (validity.isNotEmpty)
                          _InfoChip(
                            icon: HugeIconsSolid.calendar03,
                            label: validity,
                            foreground: SharePerksColors.textSecondaryLight,
                            background: SharePerksColors.surfaceLight,
                          ),
                        if (isUsed)
                          _InfoChip(
                            icon: HugeIconsSolid.tick02,
                            label: 'Used',
                            foreground: SharePerksColors.textSecondaryLight,
                            background: SharePerksColors.surfaceLight,
                          ),
                      ],
                    ),
                  ],
                  if (hasCode) ...[
                    const SizedBox(height: 12),
                    _CodeTicket(
                      code: code,
                      onCopy: () => _copyCode(code),
                    ),
                  ],
                  if (pin != null && pin.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'PIN  $pin',
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                  if (hasRedeemUrl) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => _openRedeemUrl(redeemUrl),
                        icon: Icon(HugeIconsSolid.link02, size: 15),
                        label: const Text('Open redeem link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SharePerksColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              SharePerksRadii.md,
                            ),
                          ),
                          textStyle: TextStyle(
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeTicket extends StatelessWidget {
  const _CodeTicket({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SharePerksColors.surfaceLight,
      borderRadius: BorderRadius.circular(SharePerksRadii.md),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                HugeIconsSolid.couponPercent,
                size: 16,
                color: SharePerksColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coupon code',
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 10,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        color: SharePerksColors.primary,
                        fontSize: 15,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: SharePerksColors.primary,
                  borderRadius: BorderRadius.circular(SharePerksRadii.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      HugeIconsStroke.copy01,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Copy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl, required this.used});

  final String? imageUrl;
  final bool used;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SharePerksColors.borderLight),
        color: SharePerksColors.surfaceLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          EmailCouponNetworkImage(
            url: imageUrl,
            compact: true,
            fit: BoxFit.cover,
          ),
          if (used) ColoredBox(color: Colors.white.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}
