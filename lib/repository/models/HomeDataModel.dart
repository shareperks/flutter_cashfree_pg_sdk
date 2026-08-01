import 'home_common_models.dart';

export 'home_common_models.dart';
export 'category_model.dart';

/// Backward-compatible aliases for previous class names.
typedef TopRewards = RewardItem;
typedef TopBrands = BrandItem;
typedef Slides = HomeSlide;
typedef Categories = HomeCategory;
typedef Rewards = RewardItem;

class HomeDataModel {
  bool? success;
  Data? data;

  HomeDataModel({this.success, this.data});

  HomeDataModel.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    data = json['data'] != null
        ? Data.fromJson(json['data'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    return {'success': success, if (data != null) 'data': data!.toJson()};
  }
}

class Data {
  User? user;
  UnlockedRewards? unlockedRewards;
  List<HomeSlide>? slides;
  List<RewardItem>? topRewards;
  List<BrandItem>? topBrands;
  List<HomeCategory>? categories;
  int? newRewards;

  Data({
    this.user,
    this.unlockedRewards,
    this.slides,
    this.topRewards,
    this.topBrands,
    this.categories,
    this.newRewards,
  });

  Data.fromJson(Map<String, dynamic> json) {
    user = json['user'] != null
        ? User.fromJson(json['user'] as Map<String, dynamic>)
        : null;
    unlockedRewards = json['unlockedRewards'] != null
        ? UnlockedRewards.fromJson(
            json['unlockedRewards'] as Map<String, dynamic>,
          )
        : null;
    if (json['slides'] != null) {
      slides = <HomeSlide>[];
      for (final v in json['slides'] as List<dynamic>) {
        slides!.add(HomeSlide.fromJson(v as Map<String, dynamic>));
      }
    }
    if (json['topRewards'] != null) {
      topRewards = <RewardItem>[];
      for (final v in json['topRewards'] as List<dynamic>) {
        topRewards!.add(RewardItem.fromJson(v as Map<String, dynamic>));
      }
    }
    if (json['topBrands'] != null) {
      topBrands = <BrandItem>[];
      for (final v in json['topBrands'] as List<dynamic>) {
        topBrands!.add(BrandItem.fromJson(v as Map<String, dynamic>));
      }
    }
    if (json['categories'] != null) {
      categories = <HomeCategory>[];
      for (final v in json['categories'] as List<dynamic>) {
        categories!.add(HomeCategory.fromJson(v as Map<String, dynamic>));
      }
    }
    newRewards = parseJsonInt(json['newRewards']);
  }

  Map<String, dynamic> toJson() {
    return {
      if (user != null) 'user': user!.toJson(),
      if (unlockedRewards != null) 'unlockedRewards': unlockedRewards!.toJson(),
      if (slides != null) 'slides': slides!.map((v) => v.toJson()).toList(),
      if (topRewards != null)
        'topRewards': topRewards!.map((v) => v.toJson()).toList(),
      if (topBrands != null)
        'topBrands': topBrands!.map((v) => v.toJson()).toList(),
      if (categories != null)
        'categories': categories!.map((v) => v.toJson()).toList(),
      'newRewards': newRewards,
    };
  }
}

class UnlockedRewards {
  bool? isImportInProgress;
  bool? isBrokeConnected;
  bool? remainderReimport;
  int? credit;
  int? offer;
  int? benefit;
  int? total;

  /// From `eligibleRewardCounts.anyRewardsEligible`.
  /// May be `true`/`false` or `1`/`0` (and occasionally a count).
  bool? anyRewardsEligible;

  /// Numeric form of [anyRewardsEligible] when the API sends a count / `0`/`1`.
  int? fullUnlockedCount;

  List<RewardItem>? rewards;

  UnlockedRewards({
    this.isImportInProgress,
    this.isBrokeConnected,
    this.remainderReimport,
    this.credit,
    this.offer,
    this.benefit,
    this.total,
    this.anyRewardsEligible,
    this.fullUnlockedCount,
    this.rewards,
  });

  UnlockedRewards.fromJson(Map<String, dynamic> json) {
    isImportInProgress = json['isImportInProgress'] as bool?;
    isBrokeConnected = json['isBrokeConnected'] as bool?;
    remainderReimport = json['remainderReimport'] as bool?;
    credit = parseJsonInt(json['credit']);
    offer = parseJsonInt(json['offer']);
    benefit = parseJsonInt(json['benefit']);
    total = parseJsonInt(json['total']);

    // Prefer the dedicated field from `/home-data`.
    fullUnlockedCount = parseJsonInt(json['fullUnlockedCount']);

    final anyEligible = json['anyRewardsEligible'];
    if (anyEligible is bool) {
      anyRewardsEligible = anyEligible;
    } else if (anyEligible != null) {
      // Legacy: some responses encoded eligibility/count in this field.
      final asCount = parseJsonInt(anyEligible);
      anyRewardsEligible = (asCount ?? 0) > 0;
      fullUnlockedCount ??= asCount;
    }

    if (json['rewards'] != null) {
      rewards = <RewardItem>[];
      for (final v in json['rewards'] as List<dynamic>) {
        rewards!.add(RewardItem.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'isImportInProgress': isImportInProgress,
      'isBrokeConnected': isBrokeConnected,
      'remainderReimport': remainderReimport,
      'credit': credit,
      'offer': offer,
      'benefit': benefit,
      'total': total,
      'anyRewardsEligible': anyRewardsEligible,
      'fullUnlockedCount': fullUnlockedCount,
      if (rewards != null) 'rewards': rewards!.map((v) => v.toJson()).toList(),
    };
  }
}
