import 'dart:math';

/// In-memory correlation state for a single redemption attempt.
///
/// Start a journey on `perk_card_clicked` (or reward screen entry via deep
/// link). Attach [baseProps] to every subsequent funnel event. Clear on
/// success or explicit abandon.
class JourneyContext {
  JourneyContext._();

  static String? currentJourneyId;
  static String? currentRewardId;
  static String? currentPerkType;
  static String? currentRewardName;
  static String? currentBrandName;
  static String? currentScreen;
  static String? lastAction;
  static DateTime? screenEnteredAt;

  /// Starts a new redemption journey. Returns the generated [journey_id].
  static String startJourney({
    required String rewardId,
    required String perkType,
    String? rewardName,
    String? brandName,
  }) {
    currentJourneyId = _uuidV4();
    currentRewardId = rewardId;
    currentPerkType = perkType;
    currentRewardName = rewardName;
    currentBrandName = brandName;
    return currentJourneyId!;
  }

  /// Attaches the human-readable reward / brand name once it is known (e.g.
  /// after the reward detail API resolves). These flow into every subsequent
  /// funnel event via [baseProps].
  static void setNames({String? rewardName, String? brandName}) {
    if (rewardName != null && rewardName.isNotEmpty) {
      currentRewardName = rewardName;
    }
    if (brandName != null && brandName.isNotEmpty) {
      currentBrandName = brandName;
    }
  }

  /// Clears journey state after success or abandon.
  static void clearJourney() {
    currentJourneyId = null;
    currentRewardId = null;
    currentPerkType = null;
    currentRewardName = null;
    currentBrandName = null;
    lastAction = null;
  }

  /// Props merged into every funnel / screen event.
  static Map<String, Object?> baseProps() => {
    'journey_id': ?currentJourneyId,
    'reward_id': ?currentRewardId,
    'perk_type': ?currentPerkType,
    'reward_name': ?currentRewardName,
    'brand_name': ?currentBrandName,
  };

  static String _uuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String h(int b) => b.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(h).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
