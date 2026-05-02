import 'home_common_models.dart';

/// `GET /rewards/my-claimed` — envelope `{ success, data }`.
class MyClaimedRewardsResponse {
  MyClaimedRewardsResponse({this.success, this.data});

  final bool? success;
  final MyClaimedRewardsData? data;

  factory MyClaimedRewardsResponse.fromJson(Map<String, dynamic> json) {
    return MyClaimedRewardsResponse(
      success: json['success'] as bool?,
      data: json['data'] is Map<String, dynamic>
          ? MyClaimedRewardsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    if (data != null) 'data': data!.toJson(),
  };
}

/// `data` object: totals + claimed gift cards and promo codes.
class MyClaimedRewardsData {
  MyClaimedRewardsData({
    this.totalSaved,
    this.totalUnlocked,
    this.giftcards,
    this.promocodes,
  });

  final int? totalSaved;
  final int? totalUnlocked;
  final List<MyClaimedGiftcardItem>? giftcards;
  final List<MyClaimedPromocodeItem>? promocodes;

  factory MyClaimedRewardsData.fromJson(Map<String, dynamic> json) {
    return MyClaimedRewardsData(
      totalSaved: parseJsonInt(json['totalSaved']),
      totalUnlocked: parseJsonInt(json['totalUnlocked']),
      giftcards: _mapList(
        json['giftcards'],
        (e) => MyClaimedGiftcardItem.fromJson(e),
      ),
      promocodes: _mapList(
        json['promocodes'],
        (e) => MyClaimedPromocodeItem.fromJson(e),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalSaved': totalSaved,
    'totalUnlocked': totalUnlocked,
    if (giftcards != null)
      'giftcards': giftcards!.map((e) => e.toJson()).toList(),
    if (promocodes != null)
      'promocodes': promocodes!.map((e) => e.toJson()).toList(),
  };

  static List<T>? _mapList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) from,
  ) {
    if (raw is! List<dynamic>) return null;
    return raw.whereType<Map<String, dynamic>>().map(from).toList();
  }
}

/// One claimed gift card row.
class MyClaimedGiftcardItem {
  MyClaimedGiftcardItem({
    this.id,
    this.isUsedByUser,
    this.paymentId,
    this.status,
    this.card,
    this.info,
  });

  final String? id;
  final bool? isUsedByUser;
  final String? paymentId;
  final String? status;
  final MyClaimedGiftcardCard? card;
  final MyClaimedRewardInfo? info;

  factory MyClaimedGiftcardItem.fromJson(Map<String, dynamic> json) {
    return MyClaimedGiftcardItem(
      id: json['id'] as String?,
      isUsedByUser: json['isUsedByUser'] as bool?,
      paymentId: json['paymentId'] as String?,
      status: json['status'] as String?,
      card: json['card'] is Map<String, dynamic>
          ? MyClaimedGiftcardCard.fromJson(json['card'] as Map<String, dynamic>)
          : null,
      info: json['info'] is Map<String, dynamic>
          ? MyClaimedRewardInfo.fromJson(json['info'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'isUsedByUser': isUsedByUser,
    'paymentId': paymentId,
    'status': status,
    if (card != null) 'card': card!.toJson(),
    if (info != null) 'info': info!.toJson(),
  };
}

/// Gift card `card` block (codes, amounts, expiry).
class MyClaimedGiftcardCard {
  MyClaimedGiftcardCard({
    this.eligible,
    this.payAmount,
    this.rewardAmount,
    this.savedAmount,
    this.code,
    this.pin,
    this.expireAt,
    this.expireAtFormatted,
    this.remainingDays,
  });

  final bool? eligible;
  final int? payAmount;
  final int? rewardAmount;
  final int? savedAmount;
  final String? code;
  final String? pin;
  final String? expireAt;
  final String? expireAtFormatted;
  final int? remainingDays;

  factory MyClaimedGiftcardCard.fromJson(Map<String, dynamic> json) {
    return MyClaimedGiftcardCard(
      eligible: json['eligible'] as bool?,
      payAmount: parseJsonInt(json['payAmount']),
      rewardAmount: parseJsonInt(json['rewardAmount']),
      savedAmount: parseJsonInt(json['savedAmount']),
      code: json['code'] as String?,
      pin: json['pin'] as String?,
      expireAt: json['expireAt'] as String?,
      expireAtFormatted: json['expireAtFormatted'] as String?,
      remainingDays: parseJsonInt(json['remainingDays']),
    );
  }

  Map<String, dynamic> toJson() => {
    'eligible': eligible,
    'payAmount': payAmount,
    'rewardAmount': rewardAmount,
    'savedAmount': savedAmount,
    'code': code,
    'pin': pin,
    'expireAt': expireAt,
    'expireAtFormatted': expireAtFormatted,
    'remainingDays': remainingDays,
  };
}

/// One claimed promo code row.
class MyClaimedPromocodeItem {
  MyClaimedPromocodeItem({this.id, this.isUsedByUser, this.card, this.info});

  final String? id;
  final bool? isUsedByUser;
  final MyClaimedPromocodeCard? card;
  final MyClaimedRewardInfo? info;

  factory MyClaimedPromocodeItem.fromJson(Map<String, dynamic> json) {
    return MyClaimedPromocodeItem(
      id: json['id'] as String?,
      isUsedByUser: json['isUsedByUser'] as bool?,
      card: json['card'] is Map<String, dynamic>
          ? MyClaimedPromocodeCard.fromJson(
              json['card'] as Map<String, dynamic>,
            )
          : null,
      info: json['info'] is Map<String, dynamic>
          ? MyClaimedRewardInfo.fromJson(json['info'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'isUsedByUser': isUsedByUser,
    if (card != null) 'card': card!.toJson(),
    if (info != null) 'info': info!.toJson(),
  };
}

/// Promo `card` block — `eligible` is a string enum (e.g. `NON_HOLDINGS`).
class MyClaimedPromocodeCard {
  MyClaimedPromocodeCard({
    this.eligible,
    this.code,
    this.assignedAt,
    this.assignedAtFormatted,
    this.usedAt,
    this.usedAtFormatted,
  });

  final String? eligible;
  final String? code;
  final String? assignedAt;
  final String? assignedAtFormatted;
  final String? usedAt;
  final String? usedAtFormatted;

  factory MyClaimedPromocodeCard.fromJson(Map<String, dynamic> json) {
    final el = json['eligible'];
    return MyClaimedPromocodeCard(
      eligible: el is String ? el : el?.toString(),
      code: json['code'] as String?,
      assignedAt: json['assignedAt'] as String?,
      assignedAtFormatted: json['assignedAtFormatted'] as String?,
      usedAt: json['usedAt'] as String?,
      usedAtFormatted: json['usedAtFormatted'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (eligible != null) 'eligible': eligible,
    'code': code,
    'assignedAt': assignedAt,
    'assignedAtFormatted': assignedAtFormatted,
    'usedAt': usedAt,
    'usedAtFormatted': usedAtFormatted,
  };
}

/// Shared `info` for gift cards and promos (provider only on gift cards).
class MyClaimedRewardInfo {
  MyClaimedRewardInfo({
    this.rewardId,
    this.name,
    this.brandId,
    this.brandName,
    this.image,
    this.banner,
    this.provider,
    this.categoryName,
  });

  final String? rewardId;
  final String? name;
  final String? brandId;
  final String? brandName;
  final String? image;
  final String? banner;
  final String? provider;
  final String? categoryName;

  factory MyClaimedRewardInfo.fromJson(Map<String, dynamic> json) {
    return MyClaimedRewardInfo(
      rewardId: json['rewardId'] as String?,
      name: json['name'] as String?,
      brandId: json['brandId'] as String?,
      brandName: json['brandName'] as String?,
      image: json['image'] as String?,
      banner: json['banner'] as String?,
      provider: json['provider'] as String?,
      categoryName: json['categoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'rewardId': rewardId,
    'name': name,
    'brandId': brandId,
    'brandName': brandName,
    'image': image,
    'banner': banner,
    'provider': provider,
    'categoryName': categoryName,
  };
}
