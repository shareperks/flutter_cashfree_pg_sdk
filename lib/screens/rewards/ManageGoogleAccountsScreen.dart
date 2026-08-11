import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/email_coupon_model.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/gmail/gmail_coupon.service.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:url_launcher/url_launcher.dart';

/// Connect / view Gmail accounts linked to the SharePerks user for coupon scrape.
class ManageGoogleAccountsScreen extends StatefulWidget {
  const ManageGoogleAccountsScreen({super.key});

  @override
  State<ManageGoogleAccountsScreen> createState() =>
      _ManageGoogleAccountsScreenState();
}

class _ManageGoogleAccountsScreenState extends State<ManageGoogleAccountsScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _isError = false;
  bool _connecting = false;
  String? _disconnectingId;
  List<LinkedGmailAccount> _accounts = const <LinkedGmailAccount>[];
  String? _accountId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accountId = GmailCouponService.resolveAccountId(
      fromUserProvider: context.read<UserProvider>().user?.id,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User may return from the OAuth browser sheet — refresh linked accounts.
    if (state == AppLifecycleState.resumed) {
      unawaited(_load(silent: true));
    }
  }

  Future<void> _load({bool silent = false}) async {
    final accountId = _accountId;
    if (accountId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isError = true;
        _accounts = const <LinkedGmailAccount>[];
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _isError = false;
      });
    }

    try {
      final data = await GmailCouponService.listAccounts(accountId);
      if (!mounted) return;
      setState(() {
        _accounts = data.accounts;
        _loading = false;
        _isError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!silent || _accounts.isEmpty) _isError = true;
        _loading = false;
      });
    }
  }

  Future<void> _connectGoogle() async {
    final accountId = _accountId;
    if (accountId == null) {
      Fluttertoast.showToast(msg: 'Could not resolve your account id');
      return;
    }

    final uri = Uri.parse(GmailCouponService.connectGoogleUrl(accountId));
    setState(() => _connecting = true);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        Fluttertoast.showToast(msg: 'Could not open Google sign-in');
      }
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not open Google sign-in');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  String _disconnectErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      return e.message ?? 'Could not disconnect Google account';
    }
    return 'Could not disconnect Google account';
  }

  Future<void> _disconnectGoogle(LinkedGmailAccount account) async {
    if (_disconnectingId != null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Google'),
        content: Text(
          'Disconnect ${account.email}? SharePerks will stop scraping coupons from this inbox and remove stored email coupons for it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: SharePerksColors.error,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _disconnectingId = account.id);
    try {
      final res = await GmailCouponService.disconnectAccount(account.id);
      if (!mounted) return;
      if (res.ok) {
        setState(() {
          _accounts = _accounts.where((a) => a.id != account.id).toList();
          _disconnectingId = null;
        });
        Fluttertoast.showToast(msg: 'Disconnected ${account.email}');
      } else {
        setState(() => _disconnectingId = null);
        Fluttertoast.showToast(msg: 'Could not disconnect Google account');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _disconnectingId = null);
      Fluttertoast.showToast(msg: _disconnectErrorMessage(e));
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        toolbarHeight: 40,
        title: const Text('Google Accounts'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'Connect Gmail so SharePerks can find redeemable coupon codes in your offer emails.',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 13,
                fontFamily: SharePerksFonts.inter,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _connecting ? null : _connectGoogle,
                icon: _connecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(HugeIconsSolid.mailAdd01, size: 18),
                label: Text(
                  _accounts.isEmpty
                      ? 'Connect Google'
                      : 'Connect another Google account',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SharePerksColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connected',
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 14,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              ...List.generate(
                2,
                (_) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 72,
                  decoration: BoxDecoration(
                    color: SharePerksColors.surfaceLight,
                    borderRadius: BorderRadius.circular(SharePerksRadii.md),
                  ),
                ),
              )
            else if (_isError && _accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      'Could not load connected accounts.',
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 13,
                        fontFamily: SharePerksFonts.inter,
                      ),
                    ),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_accounts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: SharePerksColors.surfaceLight,
                  borderRadius: BorderRadius.circular(SharePerksRadii.md),
                  border: Border.all(color: SharePerksColors.borderLight),
                ),
                child: Text(
                  'No Google account connected yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SharePerksColors.textSecondaryLight,
                    fontSize: 13,
                    fontFamily: SharePerksFonts.inter,
                  ),
                ),
              )
            else
              ..._accounts.map(_accountTile),
            const SizedBox(height: 20),
            Text(
              'After connecting, coupons appear on My Email Coupons. The first scrape may take a few minutes.',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight.withValues(
                  alpha: 0.9,
                ),
                fontSize: 11,
                fontFamily: SharePerksFonts.inter,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountTile(LinkedGmailAccount account) {
    final connectedOn = _formatDate(account.createdAt);
    final disconnecting = _disconnectingId == account.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(
                picture: account.picture,
                name: account.name ?? account.email,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name?.trim().isNotEmpty == true
                          ? account.name!.trim()
                          : account.email,
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 13,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (account.name?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.email,
                        style: TextStyle(
                          color: SharePerksColors.textSecondaryLight,
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                        ),
                      ),
                    ],
                    if (connectedOn.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Connected $connectedOn',
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
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SharePerksColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Connected',
                  style: TextStyle(
                    color: SharePerksColors.success,
                    fontSize: 10,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: disconnecting || _disconnectingId != null
                    ? null
                    : () => _disconnectGoogle(account),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (disconnecting)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          HugeIconsSolid.unlink02,
                          size: 14,
                          color: SharePerksColors.error,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        disconnecting ? 'Disconnecting…' : 'Disconnect',
                        style: TextStyle(
                          color: SharePerksColors.error,
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.picture, required this.name});

  final String? picture;
  final String name;

  @override
  Widget build(BuildContext context) {
    final url = picture?.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    Widget fallback() => Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SharePerksColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: SharePerksColors.primary,
          fontWeight: FontWeight.w700,
          fontFamily: SharePerksFonts.albertSans,
        ),
      ),
    );

    if (url == null || url.isEmpty) return fallback();

    return ClipOval(
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      ),
    );
  }
}
