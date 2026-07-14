import 'dart:async';

import 'analytics_event.dart';
import 'analytics_service.dart';
import 'journey_context.dart';

/// A single tap/action recorded inside a screen session, e.g.
/// `Verify Eligibility (eligible)` or `Selected Amount (1000)`.
class ScreenClick {
  ScreenClick(this.label, this.detail) : at = DateTime.now();

  final String label;
  final String? detail;
  final DateTime at;

  /// CRM-ready single line, e.g. `verify eligibility (eligible)`.
  String get display =>
      (detail == null || detail!.isEmpty) ? label : '$label ($detail)';

  Map<String, Object?> toJson() => {
        'label': label,
        if (detail != null && detail!.isNotEmpty) 'detail': detail,
        'at': at.toIso8601String(),
        'at_label': ScreenSession.formatTime(at),
      };
}

class _Session {
  _Session(this.screenName) : startedAt = DateTime.now();

  final String screenName;
  final DateTime startedAt;
  final List<ScreenClick> clicks = [];
}

/// Accumulates one CRM "card" per screen (or bottom sheet) visit:
///
///   screen_name : GiftCardAmountScreen
///   name        : Amazon Gift Card        (entity: gift card / brand / offer)
///   time        : 10:00 AM - 11:00 AM
///   clicks      : verify eligibility (eligible)
///                 Selected Amount (1000)
///                 proceed to payment
///
/// A `screen_session` event with this exact shape is emitted when the visit
/// ends (screen popped / replaced / bottom sheet closed). Uses a stack so a
/// bottom sheet opened over a screen gets its own card without losing the
/// underlying screen's accumulated clicks.
class ScreenSession {
  ScreenSession._();

  static final List<_Session> _stack = [];

  /// Opens a new visit for [screenName]. Pair with [end].
  static void begin(String screenName) {
    _stack.add(_Session(screenName));
  }

  /// Appends a tap/action to the current visit. If no visit is open (e.g. the
  /// route observer missed a lifecycle callback), lazily opens one for the
  /// current screen so an action is never silently dropped.
  static void recordClick(String label, {String? detail}) {
    if (_stack.isEmpty) {
      begin(JourneyContext.currentScreen ?? 'unknown');
    }
    _stack.last.clicks.add(ScreenClick(label, detail));
  }

  /// Closes the current visit and emits its `screen_session` card.
  static void end() {
    if (_stack.isEmpty) return;
    _emit(_stack.removeLast());
  }

  static void _emit(_Session s) {
    final endedAt = DateTime.now();
    final entityName =
        JourneyContext.currentRewardName ?? JourneyContext.currentBrandName;

    unawaited(
      AnalyticsService.instance.track(AnalyticsEvent.screenSession, {
        'screen_name': s.screenName,
        if (entityName != null) 'name': entityName,
        'started_at': s.startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'time_label':
            '${formatTime(s.startedAt)} - ${formatTime(endedAt)}',
        'duration_ms': endedAt.difference(s.startedAt).inMilliseconds,
        'clicks': s.clicks.map((c) => c.toJson()).toList(),
        'clicks_summary': s.clicks.map((c) => c.display).toList(),
        ...JourneyContext.baseProps(),
      }),
    );
  }

  /// 24h -> `10:00 AM` style label used in the CRM card time range.
  static String formatTime(DateTime dt) {
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    var hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
