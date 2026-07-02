import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/biometric/biometric_auth_result.dart';
import 'package:shareperks/integrations/biometric/biometric_auth_service.dart';

enum _BiometricGatePhase { checking, locked, unlocked }

/// Wraps sensitive content behind local device authentication.
///
/// Re-lock on app resume by default so holdings stay protected when the user
/// switches away and returns.
class BiometricGate extends StatefulWidget {
  const BiometricGate({
    super.key,
    required this.child,
    required this.reason,
    this.onUnlocked,
    this.onLocked,
    this.lockOnResume = true,
    this.authService,
  });

  final Widget child;
  final String reason;
  final VoidCallback? onUnlocked;
  final VoidCallback? onLocked;
  final bool lockOnResume;
  final BiometricAuthService? authService;

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  late final BiometricAuthService _authService;
  _BiometricGatePhase _phase = _BiometricGatePhase.checking;
  BiometricAuthResult? _lastResult;
  bool _authenticating = false;
  bool _wasBackgroundedWhileUnlocked = false;
  DateTime? _unlockedAt;

  /// Ignore [resumed] briefly after unlock — the system biometric sheet
  /// dismisses with a lifecycle bounce that must not trigger re-auth.
  static const _resumeGracePeriod = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? BiometricAuthService();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.lockOnResume) return;

    // Biometric / PIN sheets use [inactive], not a real background.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_phase == _BiometricGatePhase.unlocked) {
        _wasBackgroundedWhileUnlocked = true;
      }
      return;
    }

    if (state != AppLifecycleState.resumed) return;
    if (_authenticating) return;
    if (_phase != _BiometricGatePhase.unlocked) return;
    if (!_wasBackgroundedWhileUnlocked) return;

    final unlockedAt = _unlockedAt;
    if (unlockedAt != null &&
        DateTime.now().difference(unlockedAt) < _resumeGracePeriod) {
      return;
    }

    _wasBackgroundedWhileUnlocked = false;
    _lock(andReauthenticate: true);
  }

  void _lock({bool andReauthenticate = false}) {
    if (!mounted) return;
    _unlockedAt = null;
    setState(() => _phase = _BiometricGatePhase.locked);
    widget.onLocked?.call();
    if (andReauthenticate) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating || !mounted) return;
    setState(() {
      _authenticating = true;
      _phase = _BiometricGatePhase.checking;
    });

    final result = await _authService.authenticate(reason: widget.reason);
    if (!mounted) return;

    setState(() => _authenticating = false);

    if (result.isSuccess) {
      setState(() {
        _phase = _BiometricGatePhase.unlocked;
        _lastResult = null;
        _unlockedAt = DateTime.now();
        _wasBackgroundedWhileUnlocked = false;
      });
      widget.onUnlocked?.call();
      return;
    }

    setState(() {
      _phase = _BiometricGatePhase.locked;
      _lastResult = result;
    });
    widget.onLocked?.call();
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _BiometricGatePhase.checking:
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      case _BiometricGatePhase.unlocked:
        return widget.child;
      case _BiometricGatePhase.locked:
        return _LockedView(
          message: _lastResult?.message ?? _defaultLockedMessage(),
          isRetryable: _isRetryable(_lastResult?.status),
          onUnlock: _authenticating ? null : _authenticate,
        );
    }
  }

  String _defaultLockedMessage() {
    return 'Verify your identity with fingerprint, Face ID, or your device '
        'PIN to view holdings.';
  }

  bool _isRetryable(BiometricAuthStatus? status) {
    if (status == null) return true;
    return status != BiometricAuthStatus.notSupported &&
        status != BiometricAuthStatus.passcodeNotSet;
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView({
    required this.message,
    required this.isRetryable,
    required this.onUnlock,
  });

  final String message;
  final bool isRetryable;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            HugeIconsStroke.lockKey,
            size: 48,
            color: SharePerksColors.primary.withAlpha(180),
          ),
          const SizedBox(height: 20),
          Text(
            'Authentication required',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 18,
              fontFamily: SharePerksFonts.albertSans,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF898989),
              fontSize: 13,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          if (isRetryable) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SharePerksColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SharePerksRadii.md),
                ),
              ),
              onPressed: onUnlock,
              child: const Text('Unlock holdings'),
            ),
          ],
        ],
      ),
    );
  }
}
