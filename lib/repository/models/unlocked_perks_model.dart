import 'home_common_models.dart';

class UnlockedPerksResponse {
  final bool? success;
  final UnlockedPerksData? data;

  UnlockedPerksResponse({this.success, this.data});

  factory UnlockedPerksResponse.fromJson(Map<String, dynamic> json) {
    return UnlockedPerksResponse(
      success: json['success'] as bool?,
      data: json['data'] is Map<String, dynamic>
          ? UnlockedPerksData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, if (data != null) 'data': data!.toJson()};
  }
}

class UnlockedPerksData {
  final List<RewardItem>? creditRewardsEligibly;
  final List<RewardItem>? offerRewardsEligibly;
  final List<RewardItem>? benefitRewardsEligibly;

  /// Controller `total` = `rewards.length` (includes Member / brokerage-only).
  final int? total;

  /// Rewards that are both `isNew` and `isEligible` (Shareholder unlocked).
  final int? newRewards;

  /// Present on the raw service payload; may be `bool` or `0`/`1`.
  final bool? anyRewardsEligible;

  final List<RewardItem>? rewards;

  UnlockedPerksData({
    this.creditRewardsEligibly,
    this.offerRewardsEligibly,
    this.benefitRewardsEligibly,
    this.total,
    this.newRewards,
    this.anyRewardsEligible,
    this.rewards,
  });

  static List<RewardItem>? _parseRewards(dynamic v) {
    if (v is! List) return null;
    return v
        .whereType<Map>()
        .map((e) => RewardItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `anyRewardsEligible` can be `true`/`false` or `1`/`0`.
  static bool? _parseAnyRewardsEligible(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final lower = v.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  factory UnlockedPerksData.fromJson(Map<String, dynamic> json) {
    return UnlockedPerksData(
      creditRewardsEligibly: _parseRewards(json['creditRewardsEligibly']),
      offerRewardsEligibly: _parseRewards(json['offerRewardsEligibly']),
      benefitRewardsEligibly: _parseRewards(json['benefitRewardsEligibly']),
      total: parseJsonInt(json['total']),
      newRewards: parseJsonInt(json['newRewards']),
      anyRewardsEligible: _parseAnyRewardsEligible(json['anyRewardsEligible']),
      rewards: _parseRewards(json['rewards']),
    );
  }

  /// All listed rewards across type buckets (falls back to [rewards]).
  List<RewardItem> get allRewards {
    if (rewards != null && rewards!.isNotEmpty) return rewards!;
    return [
      ...?benefitRewardsEligibly,
      ...?creditRewardsEligibly,
      ...?offerRewardsEligibly,
    ];
  }

  /// Shareholder unlocked = `isEligible === true` (maximum reward).
  int get shareholderUnlockedCount =>
      allRewards.where((r) => r.isEligible == true).length;

  /// Member unlocked = brokerage-only (`isBrokerageEligible` and not fully eligible).
  int get memberUnlockedCount => allRewards
      .where((r) => r.isEligible != true && r.isBrokerageEligible == true)
      .length;

  Map<String, dynamic> toJson() {
    return {
      if (creditRewardsEligibly != null)
        'creditRewardsEligibly': creditRewardsEligibly!
            .map((e) => e.toJson())
            .toList(),
      if (offerRewardsEligibly != null)
        'offerRewardsEligibly': offerRewardsEligibly!
            .map((e) => e.toJson())
            .toList(),
      if (benefitRewardsEligibly != null)
        'benefitRewardsEligibly': benefitRewardsEligibly!
            .map((e) => e.toJson())
            .toList(),
      'total': total,
      'newRewards': newRewards,
      'anyRewardsEligible': anyRewardsEligible,
      if (rewards != null) 'rewards': rewards!.map((e) => e.toJson()).toList(),
    };
  }
}
