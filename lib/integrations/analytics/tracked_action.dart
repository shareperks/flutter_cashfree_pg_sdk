import 'dart:async';

import 'analytics_event.dart';
import 'analytics_service.dart';
import 'journey_context.dart';
import 'screen_session.dart';

/// Records a meaningful user action with journey + screen context.
///
/// Every action (anything that isn't a screen-lifecycle / view event) is also
/// appended to the current screen's CRM card, so `screen_session.clicks`
/// reflects what the user actually did — eligibility checks, amount selections,
/// payments, votes, referrals, etc. — without each call site having to record
/// separately.
Future<void> trackAction(
  AnalyticsEvent event, [
  Map<String, Object?> props = const {},
]) async {
  JourneyContext.lastAction = event.name;

  if (_isCardAction(event)) {
    final label = (props['label'] as String?) ?? _humanize(event.name);
    final detail = (props['detail'] as String?) ?? _clickDetail(props);
    ScreenSession.recordClick(label, detail: detail);
  }

  await AnalyticsService.instance.track(event, {
    if (JourneyContext.currentScreen != null)
      'screen_name': JourneyContext.currentScreen!,
    ...JourneyContext.baseProps(),
    ...props,
  });
}

/// Records a button / CTA tap with the visible [label] (button text) and the
/// current screen name. Use for any tappable control we want in the audit
/// trail: `trackButtonClick('Proceed to Claim Credit')`. The tap is added to
/// the current screen's CRM card by [trackAction].
Future<void> trackButtonClick(
  String label, [
  Map<String, Object?> props = const {},
]) async {
  final detail = _clickDetail(props);
  await trackAction(AnalyticsEvent.buttonClicked, {
    'label': label,
    'detail': ?detail,
    ...props,
  });
}

/// Screen-view / lifecycle / error / discovery-view events are NOT user
/// actions and must not clutter the card's click list.
bool _isCardAction(AnalyticsEvent event) {
  const nonActionCategories = {
    EventCategory.screen,
    EventCategory.lifecycle,
    EventCategory.error,
  };
  if (nonActionCategories.contains(event.category)) return false;
  final name = event.name;
  if (name.endsWith('viewed') || name.endsWith('loaded')) return false;
  return true;
}

/// Turns an event name like `giftcard_amount_selected` into `Giftcard Amount
/// Selected` for the CRM card when no explicit label is provided.
String _humanize(String eventName) => eventName
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Derives the parenthesised detail shown after a click label on the CRM card.
String? _clickDetail(Map<String, Object?> props) {
  final detail = props['detail'];
  if (detail is String && detail.isNotEmpty) return detail;
  final eligible = props['is_eligible'];
  if (eligible is bool) return eligible ? 'eligible' : 'not eligible';
  final amount = props['selected_amount'] ?? props['amount'];
  if (amount != null) return '$amount';
  return null;
}

/// Tracks a bottom sheet as its own screen surface.
///
/// Sets [sheetName] as the active `screen_name` (so taps inside the sheet are
/// attributed to the sheet, not the screen behind it) and emits a
/// `screen_view`. Returns a callback that restores the previous screen —
/// pass it to `showModalBottomSheet(...).whenComplete(restore)`.
void Function() trackBottomSheet(
  String sheetName, [
  Map<String, Object?> props = const {},
]) {
  final previousScreen = JourneyContext.currentScreen;
  final previousEnteredAt = JourneyContext.screenEnteredAt;
  JourneyContext.currentScreen = sheetName;
  JourneyContext.screenEnteredAt = DateTime.now();
  // Nested card for the sheet; clicks inside it attach here, not the screen
  // behind it. Closed on the restore callback below.
  ScreenSession.begin(sheetName);
  unawaited(
    trackAction(AnalyticsEvent.screenView, {
      'screen_name': sheetName,
      'surface': 'bottom_sheet',
      'previous_screen': ?previousScreen,
      ...props,
    }),
  );
  return () {
    ScreenSession.end();
    JourneyContext.currentScreen = previousScreen;
    JourneyContext.screenEnteredAt = previousEnteredAt;
  };
}
