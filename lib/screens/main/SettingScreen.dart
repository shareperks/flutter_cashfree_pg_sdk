import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/loader/SettingsScreenShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/integrations/analytics/consent_manager.dart';
import 'package:shareperks/integrations/onesignal_push.dart';
import 'package:shareperks/repository/models/user_settings_model.dart';
import 'package:shareperks/repository/services/actions/Settings.service.dart';
import 'package:shareperks/repository/services/auth/mfa_service.dart';
import 'package:soui/elements/SpScafold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _loadError = false;
  bool _saving = false;

  bool _notifications = false;
  bool _perksUpdates = false;
  bool _walletUpdates = false;
  bool _mfaEnabled = false;
  bool _shareUsageData = true;

  Future<void> _fetchSettings() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      final s = await SettingsService.getSettings();
      if (!mounted) return;
      setState(() {
        _applySettings(s);
        _loading = false;
      });
      final consent = await ConsentManager.isGranted();
      if (!mounted) return;
      setState(() => _shareUsageData = consent);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = true;
        _loading = false;
      });
    }
  }

  Future<void> _refreshAfterSaveFailure() async {
    try {
      final s = await SettingsService.getSettings();
      if (!mounted) return;
      setState(() => _applySettings(s));
    } catch (_) {
      // Keep local toggles; user already saw save error SnackBar.
    }
  }

  void _applySettings(UserSettings s) {
    _notifications = s.notifications ?? false;
    _perksUpdates = s.perksUpdates ?? false;
    _walletUpdates = s.walletUpdates ?? false;
    _mfaEnabled = s.mfaEnabled ?? false;
    // Reconcile push SDK with server preference.
    if (!_notifications && OneSignalPush.isOptedIn) {
      OneSignalPush.setOptedIn(false);
    }
  }

  Future<void> _openMfaSetup() async {
    await context.pushNamed(RouteNames.MFA_SETUP_SCREEN);
    if (!mounted) return;
    await _fetchSettings();
  }

  Future<void> _showDisableMfaDialog() async {
    final disabled = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DisableMfaDialog(),
    );

    if (disabled == true && mounted) {
      Fluttertoast.showToast(
        msg: '2FA disabled',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await _fetchSettings();
    }
  }

  Future<void> _pushSettings({
    required bool notifications,
    required bool perksUpdates,
    required bool walletUpdates,
  }) async {
    setState(() => _saving = true);
    try {
      final updated = await SettingsService.updateSettings(
        UserSettingsUpdate.all(
          notifications: notifications,
          perksUpdates: perksUpdates,
          walletUpdates: walletUpdates,
        ),
      );
      if (!mounted) return;
      setState(() {
        _applySettings(updated);
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save settings. Try again.')),
      );
      await _refreshAfterSaveFailure();
    }
  }

  Future<void> _onPerksChanged(bool value) async {
    setState(() => _perksUpdates = value);
    await _pushSettings(
      notifications: _notifications,
      perksUpdates: value,
      walletUpdates: _walletUpdates,
    );
  }

  Future<void> _onWalletChanged(bool value) async {
    setState(() => _walletUpdates = value);
    await _pushSettings(
      notifications: _notifications,
      perksUpdates: _perksUpdates,
      walletUpdates: value,
    );
  }

  Future<void> _onNotificationsChanged(bool value) async {
    if (value) {
      final granted =
          await OneSignalPush.requestPermissionIfNeeded(force: true);
      if (!granted) {
        if (!mounted) return;
        setState(() => _notifications = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission is required. Enable it in system settings.',
            ),
          ),
        );
        return;
      }
      await OneSignalPush.setOptedIn(true);
    } else {
      await OneSignalPush.setOptedIn(false);
    }

    if (!mounted) return;
    setState(() => _notifications = value);
    await _pushSettings(
      notifications: value,
      perksUpdates: _perksUpdates,
      walletUpdates: _walletUpdates,
    );
  }

  Future<void> _onShareUsageDataChanged(bool value) async {
    setState(() => _shareUsageData = value);
    if (value) {
      await ConsentManager.grant();
    } else {
      await ConsentManager.deny();
    }
    await AnalyticsService.instance.onConsentChanged(value);
  }

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        toolbarHeight: 40,
        title: Text("Settings & Security"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: _loading
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: const SettingsScreenShimmer(),
            )
          : _loadError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 16,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _fetchSettings,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Settings',
                    style: TextStyle(
                      color: const Color(0xFF6400E0),
                      fontSize: 18,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 1,
                          color: SharePerksColors.borderLight,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Text(
                        'Perk Updates',
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 14,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: Switch(
                        value: _perksUpdates,
                        onChanged: _saving ? (e) {} : (v) => _onPerksChanged(v),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 1,
                          color: SharePerksColors.borderLight,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Text(
                        'Wallet Updates',
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 14,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: Switch(
                        value: _walletUpdates,
                        onChanged: _saving
                            ? (e) {}
                            : (v) => _onWalletChanged(v),
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  Text(
                    'Security',
                    style: TextStyle(
                      color: const Color(0xFF6400E0),
                      fontSize: 18,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 1,
                          color: SharePerksColors.borderLight,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Text(
                        'Two-factor authentication',
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 14,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _mfaEnabled
                            ? 'On — Google Authenticator'
                            : 'Off — protect your account with an authenticator app',
                        style: TextStyle(
                          color: SharePerksColors.textSecondaryLight,
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: _mfaEnabled
                            ? _showDisableMfaDialog
                            : _openMfaSetup,
                        child: Text(_mfaEnabled ? 'Disable' : 'Enable'),
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  Text(
                    'App Permissions',
                    style: TextStyle(
                      color: const Color(0xFF6400E0),
                      fontSize: 18,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 1,
                          color: SharePerksColors.borderLight,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Text(
                        'Notifications',
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 14,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: Switch(
                        value: _notifications,
                        onChanged: _saving
                            ? (e) {}
                            : (v) => _onNotificationsChanged(v),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 1,
                          color: SharePerksColors.borderLight,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Text(
                        'Share usage data',
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 14,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Helps us improve SharePerks via Google Analytics',
                        style: TextStyle(
                          color: SharePerksColors.textSecondaryLight,
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      trailing: Switch(
                        value: _shareUsageData,
                        onChanged: (v) => _onShareUsageDataChanged(v),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Delete Account',
                        style: TextStyle(
                          color: const Color(0xFFEB3939),
                          fontSize: 15,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      context.pushNamed(RouteNames.HELP_AND_SUPPORT_SCREEN);
                    },
                    child: Image.asset(
                      Assets.ASSETS_CARDS_SUPPORTCARD_PNG,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                  Copyright(),
                ],
              ),
              ),
            ),
    );
  }
}

class _DisableMfaDialog extends StatefulWidget {
  const _DisableMfaDialog();

  @override
  State<_DisableMfaDialog> createState() => _DisableMfaDialogState();
}

class _DisableMfaDialogState extends State<_DisableMfaDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      Fluttertoast.showToast(
        msg: 'Enter a valid code.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await MfaService.disable(code);
      if (!mounted) return;
      if (!res.success) {
        Fluttertoast.showToast(
          msg: res.message.isNotEmpty ? res.message : 'Invalid code',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        _codeController.clear();
        setState(() => _submitting = false);
        return;
      }
      Navigator.pop(context, true);
    } catch (_) {
      Fluttertoast.showToast(
        msg: 'Could not disable 2FA. Try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Disable 2FA',
        style: TextStyle(
          fontFamily: SharePerksFonts.albertSans,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your authenticator code or a backup code to disable 2FA.',
            style: TextStyle(
              fontSize: 13,
              fontFamily: SharePerksFonts.inter,
              color: SharePerksColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            autofocus: true,
            maxLength: 16,
            onSubmitted: (_) => _submitting ? null : _submit(),
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'Code',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Disable'),
        ),
      ],
    );
  }
}

