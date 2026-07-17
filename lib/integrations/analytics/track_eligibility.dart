import 'analytics_event.dart';
import 'journey_context.dart';
import 'tracked_action.dart';

/// Records eligibility outcome for any perk type. Always track both eligible
/// and ineligible — ineligible taps are high-signal drop-off data.
Future<void> trackEligibility({
  required String perkType,
  required String rewardId,
  required bool isEligible,
  String? reason,
  required String source,
  String? brandId,
}) async {
  final AnalyticsEvent event;
  switch (perkType) {
    case 'giftcard':
      event = AnalyticsEvent.giftcardEligibilityChecked;
      break;
    case 'promocode':
      event = AnalyticsEvent.promocodeEligibilityChecked;
      break;
    case 'cashback':
      event = AnalyticsEvent.cashbackEligibilityChecked;
      break;
    default:
      event = AnalyticsEvent.perkEligibilityChecked;
  }

  if (!isEligible) {
    JourneyContext.lastAction = 'ineligible_${reason ?? 'unknown'}';
  }

  await trackAction(event, {
    'reward_id': rewardId,
    'perk_type': perkType,
    'is_eligible': isEligible,
    'eligibility_reason': ?reason,
    'source': source,
    'brand_id': ?brandId,
  });
}
