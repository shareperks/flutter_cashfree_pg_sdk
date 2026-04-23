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
  final int? total;
  final List<RewardItem>? rewards;

  UnlockedPerksData({
    this.creditRewardsEligibly,
    this.offerRewardsEligibly,
    this.benefitRewardsEligibly,
    this.total,
    this.rewards,
  });

  static List<RewardItem>? _parseRewards(dynamic v) {
    if (v is! List) return null;
    return v
        .whereType<Map<String, dynamic>>()
        .map((e) => RewardItem.fromJson(e))
        .toList();
  }

  factory UnlockedPerksData.fromJson(Map<String, dynamic> json) {
    return UnlockedPerksData(
      creditRewardsEligibly: _parseRewards(json['creditRewardsEligibly']),
      offerRewardsEligibly: _parseRewards(json['offerRewardsEligibly']),
      benefitRewardsEligibly: _parseRewards(json['benefitRewardsEligibly']),
      total: parseJsonInt(json['total']),
      rewards: _parseRewards(json['rewards']),
    );
  }

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
      if (rewards != null) 'rewards': rewards!.map((e) => e.toJson()).toList(),
    };
  }
}
