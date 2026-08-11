import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/EmailCouponNetworkImage.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/email_coupon_model.dart';
import 'package:shareperks/repository/services/gmail/gmail_coupon.service.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailCouponDetailScreen extends StatefulWidget {
  const EmailCouponDetailScreen({super.key, required this.coupon});

  final EmailCoupon coupon;

  @override
  State<EmailCouponDetailScreen> createState() =>
      _EmailCouponDetailScreenState();
}

class _EmailCouponDetailScreenState extends State<EmailCouponDetailScreen> {
  late EmailCoupon _coupon;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _coupon = widget.coupon;
  }

  Future<void> _copy(String value, {String label = 'Copied'}) async {
    await Clipboard.setData(ClipboardData(text: value));
    Fluttertoast.showToast(
      msg: label,
      backgroundColor: SharePerksColors.success,
      textColor: Colors.white,
    );
  }

  Future<void> _toggleUsed() async {
    if (_toggling) return;
    final nextUsed = !_coupon.used;
    setState(() => _toggling = true);
    try {
      final updated = await GmailCouponService.setCouponUsed(
        _coupon.id,
        used: nextUsed,
        current: _coupon,
      );
      if (!mounted) return;
      setState(() => _coupon = updated);
      Fluttertoast.showToast(
        msg: nextUsed ? 'Marked as used' : 'Marked as unused',
      );
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not update coupon');
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
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

  void _popWithResult() {
    Navigator.of(context).pop(_coupon);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _coupon.displayImage;
    final brand = _coupon.displayBrand;
    final offer = _coupon.offer?.trim();
    final discount = _coupon.maximumDiscount?.trim();
    final description = _coupon.description?.trim();
    final price = _coupon.price?.trim();
    final code = _coupon.couponCode?.trim();
    final pin = _coupon.pin?.trim();
    final redeemUrl = _coupon.redeemUrl?.trim();
    final hasRedeemUrl = redeemUrl != null && redeemUrl.isNotEmpty;
    final eligibility = _coupon.eligibility?.trim();
    final notes = _coupon.notes?.trim();
    final source = _coupon.source?.trim();
    final validFrom = _coupon.validFrom?.trim();
    final validTill = _coupon.validTill?.trim();
    final extractedAt = _coupon.extractedAt?.trim();
    final usedAt = _coupon.usedAt?.trim();
    final email = _coupon.email;
    final gmail = _coupon.gmailUser;
    final imageUrls = email?.imageUrls ?? const <String>[];
    final hasRedeemSection = (code != null && code.isNotEmpty) ||
        (pin != null && pin.isNotEmpty) ||
        hasRedeemUrl;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popWithResult();
      },
      child: SpScafold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _popWithResult,
            icon: const Icon(
              HugeIconsSolid.arrowLeft02,
              color: Colors.white,
            ),
          ),
          toolbarHeight: 40,
          title: const Text('Coupon details'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (imageUrl != null) ...[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: EmailCouponNetworkImage(url: imageUrl),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              _coupon.displayTitle,
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 22,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            if (brand.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                brand,
                style: TextStyle(
                  color: SharePerksColors.primary,
                  fontSize: 14,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if ((discount != null && discount.isNotEmpty) ||
                (offer != null && offer.isNotEmpty)) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (discount != null && discount.isNotEmpty)
                    _BrandPill(label: discount),
                  if (offer != null &&
                      offer.isNotEmpty &&
                      offer != discount)
                    _SoftPill(
                      label: offer,
                      color: SharePerksColors.accent,
                    ),
                  _SoftPill(
                    label: _coupon.used ? 'Used' : 'Unused',
                    color: _coupon.used
                        ? SharePerksColors.textSecondaryLight
                        : SharePerksColors.success,
                  ),
                ],
              ),
            ],
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 14,
                  fontFamily: SharePerksFonts.inter,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Offer details',
              children: [
                _DetailRow(label: 'Min. purchase', value: price),
                _DetailRow(label: 'Max. discount', value: discount),
                _DetailRow(label: 'Offer', value: offer),
                _DetailRow(label: 'Valid from', value: validFrom),
                _DetailRow(label: 'Valid till', value: validTill),
                _DetailRow(label: 'Eligibility', value: eligibility),
                _DetailRow(label: 'Source', value: source),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _NotesCard(notes: notes),
            ],
            if (hasRedeemSection) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Redeem',
                children: [
                  if (code != null && code.isNotEmpty)
                    _CopyValueRow(
                      label: 'Coupon code',
                      value: code,
                      onCopy: () => _copy(code, label: 'Coupon code copied'),
                    ),
                  if (pin != null && pin.isNotEmpty)
                    _CopyValueRow(
                      label: 'PIN',
                      value: pin,
                      onCopy: () => _copy(pin, label: 'PIN copied'),
                    ),
                  if (hasRedeemUrl)
                    _RedeemLinkButton(
                      onTap: () => _openRedeemUrl(redeemUrl),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Email source',
              children: [
                _DetailRow(label: 'Subject', value: email?.subject),
                _DetailRow(label: 'From', value: email?.from),
                _DetailRow(label: 'Received', value: email?.receivedAt),
                _DetailRow(label: 'Gmail', value: gmail?.email),
                _DetailRow(label: 'Extracted', value: extractedAt),
                _DetailRow(label: 'Used at', value: usedAt),
              ],
            ),
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Images from email',
                children: [
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 84,
                            height: 84,
                            child: EmailCouponNetworkImage(
                              url: imageUrls[index],
                              compact: true,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _UsedActionBar(
              used: _coupon.used,
              loading: _toggling,
              onTap: _toggleUsed,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: SharePerksColors.primary,
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: SharePerksFonts.albertSans,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  const _SoftPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: SharePerksFonts.inter,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  List<String> get _items {
    final raw = notes
        .split(RegExp(r'[\n\r]+|(?<=[.!?])\s+(?=[A-Z•\-\*])|•|\u2022'))
        .map((e) => e.trim().replaceFirst(RegExp(r'^[-*]\s*'), ''))
        .where((e) => e.isNotEmpty)
        .toList();
    if (raw.length <= 1) {
      final single = notes.trim();
      return single.isEmpty ? const <String>[] : <String>[single];
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Material(
      color: SharePerksColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        side: BorderSide(color: SharePerksColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  HugeIconsSolid.note,
                  size: 16,
                  color: SharePerksColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(
                    color: SharePerksColors.textPrimaryLight,
                    fontSize: 14,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: SharePerksColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 13,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SharePerksColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 14,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  bool get hasValue {
    final v = value?.trim();
    return v != null && v.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasValue) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!.trim(),
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 13,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedeemLinkButton extends StatelessWidget {
  const _RedeemLinkButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(HugeIconsSolid.link02, size: 16),
          label: const Text('Open redeem link'),
          style: ElevatedButton.styleFrom(
            backgroundColor: SharePerksColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyValueRow extends StatelessWidget {
  const _CopyValueRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: SharePerksColors.textSecondaryLight,
                          fontSize: 10,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: SharePerksColors.primary,
                          fontSize: 16,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
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
      ),
    );
  }
}

class _UsedActionBar extends StatelessWidget {
  const _UsedActionBar({
    required this.used,
    required this.loading,
    required this.onTap,
  });

  final bool used;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: used
          ? SharePerksColors.surfaceLight
          : SharePerksColors.success.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(SharePerksRadii.lg),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: used
                      ? Colors.white
                      : SharePerksColors.success.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        used
                            ? HugeIconsSolid.tick02
                            : HugeIconsSolid.circle,
                        size: 16,
                        color: used
                            ? SharePerksColors.textSecondaryLight
                            : SharePerksColors.success,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      used ? 'Marked as used' : 'Still unused',
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 14,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      used
                          ? 'Tap Undo if you still want to use this coupon'
                          : 'Tap when you’ve redeemed this coupon',
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 11,
                        fontFamily: SharePerksFonts.inter,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                used ? 'Undo' : 'Mark used',
                style: TextStyle(
                  color: SharePerksColors.primary,
                  fontSize: 13,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


