import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/components/EmailCouponNetworkImage.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/email_coupon_model.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/gmail/gmail_coupon.service.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/theme.dart';

/// Home section for Email Coupons — matches SharePerks BorderCard sections.
class EmailCouponsHomeSection extends StatefulWidget {
  const EmailCouponsHomeSection({super.key});

  @override
  State<EmailCouponsHomeSection> createState() =>
      _EmailCouponsHomeSectionState();
}

class _EmailCouponsHomeSectionState extends State<EmailCouponsHomeSection> {
  bool _loading = true;
  List<LinkedGmailAccount> _accounts = const <LinkedGmailAccount>[];
  int _couponCount = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final accountId = GmailCouponService.resolveAccountId(
      fromUserProvider: context.read<UserProvider>().user?.id,
    );
    if (accountId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        GmailCouponService.listAccounts(accountId),
        GmailCouponService.listCoupons(
          accountId,
          page: 1,
          limit: 1,
          usedFilter: EmailCouponUsedFilter.unused,
        ),
      ]);
      if (!mounted) return;
      final accounts = results[0] as GmailAccountsByAccountIdResponse;
      final coupons = results[1] as PaginatedEmailCouponsResponse;
      setState(() {
        _accounts = accounts.accounts;
        _couponCount = coupons.total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openCoupons() async {
    await context.pushNamed(RouteNames.MY_EMAIL_COUPONS_SCREEN);
    if (!mounted) return;
    unawaited(_load());
  }

  Future<void> _openManage() async {
    await context.pushNamed(RouteNames.MANAGE_GOOGLE_ACCOUNTS_SCREEN);
    if (!mounted) return;
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final connected = _accounts.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: BorderCard(
        width: double.infinity,
        borderWidth: 1,
        borderRadius: SharePerksRadii.lg,
        color: SharePerksColors.primary.withValues(alpha: 0.2),
        isGradientBackground: true,
        backgroundColor: SharePerksColors.primary.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SharePerksColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      HugeIconsSolid.mailOpen01,
                      size: 22,
                      color: SharePerksColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Email ',
                                style: TextStyle(
                                  color: AppColors.brand,
                                  fontSize: 18,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: 'Coupons',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 18,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connected
                              ? 'Inbox offers, ready to redeem'
                              : 'Connect Gmail & unlock offer codes',
                          style: TextStyle(
                            color: SharePerksColors.textSecondaryLight,
                            fontSize: 12,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_loading && _couponCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: SharePerksColors.accent,
                        borderRadius: BorderRadius.circular(SharePerksRadii.md),
                      ),
                      child: Text(
                        '$_couponCount unused',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading)
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(SharePerksRadii.md),
                  ),
                )
              else if (connected)
                _ConnectedAccountsRow(accounts: _accounts)
              else
                _EmptyConnectHint(onConnect: _openManage),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: connected ? _openCoupons : _openManage,
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
                        child: Text(
                          connected ? 'View coupons' : 'Connect Gmail',
                        ),
                      ),
                    ),
                  ),
                  if (connected) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: _openManage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SharePerksColors.primary,
                          side: BorderSide(color: SharePerksColors.primary),
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
                        child: const Text('Accounts'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedAccountsRow extends StatelessWidget {
  const _ConnectedAccountsRow({required this.accounts});

  final List<LinkedGmailAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final shown = accounts.take(3).toList();
    final extra = accounts.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          accounts.length == 1
              ? 'Connected inbox'
              : '${accounts.length} connected inboxes',
          style: TextStyle(
            color: SharePerksColors.textSecondaryLight,
            fontSize: 11,
            fontFamily: SharePerksFonts.inter,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _AccountChip(account: shown[i])),
            ],
            if (extra > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SharePerksRadii.md),
                  border: Border.all(color: SharePerksColors.borderLight),
                ),
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    color: SharePerksColors.primary,
                    fontSize: 12,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.account});

  final LinkedGmailAccount account;

  @override
  Widget build(BuildContext context) {
    final picture = account.picture?.trim();
    final name = (account.name?.trim().isNotEmpty == true)
        ? account.name!.trim()
        : account.email;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 28,
              height: 28,
              child: picture != null && picture.isNotEmpty
                  ? EmailCouponNetworkImage(
                      url: picture,
                      compact: true,
                      fit: BoxFit.cover,
                      loadTimeout: const Duration(seconds: 4),
                    )
                  : _InitialAvatar(initial: initial),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SharePerksColors.textPrimaryLight,
                    fontSize: 11,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SharePerksColors.textSecondaryLight,
                    fontSize: 9,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SharePerksColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: SharePerksColors.primary,
            fontSize: 12,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyConnectHint extends StatelessWidget {
  const _EmptyConnectHint({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onConnect,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SharePerksRadii.md),
          border: Border.all(color: SharePerksColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(
              HugeIconsSolid.mailAdd01,
              size: 18,
              color: SharePerksColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Link your Gmail once — we’ll pull redeemable codes from offer emails.',
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 12,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
