import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';

class CoundownTimer extends StatefulWidget {
  const CoundownTimer({super.key, required this.seconds, this.onEnd});

  /// Total countdown length in seconds.
  final int seconds;

  /// Called once when the countdown reaches zero.
  final VoidCallback? onEnd;

  @override
  State<CoundownTimer> createState() => _CoundownTimerState();
}

class _CoundownTimerState extends State<CoundownTimer> {
  static const TextStyle _style = TextStyle(
    color: Color(0xFF6400E0),
    fontSize: 28,
    fontFamily: SharePerksFonts.albertSans,
    fontWeight: FontWeight.w600,
  );

  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _schedule();
  }

  @override
  void didUpdateWidget(CoundownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      _timer?.cancel();
      _remaining = widget.seconds;
      _schedule();
    }
  }

  void _schedule() {
    if (_remaining <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onEnd?.call();
      });
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        _timer = null;
        widget.onEnd?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining ~/ 3600;
    final m = (_remaining % 3600) ~/ 60;
    final s = _remaining % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$hh', style: _style),
        const Text(':', style: _style),
        Text(mm, style: _style),
        const Text(':', style: _style),
        Text(ss, style: _style),
      ],
    );
  }
}
