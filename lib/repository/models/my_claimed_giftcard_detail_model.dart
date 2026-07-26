import 'home_common_models.dart';

/// `GET /rewards/my-claimed/giftcard/:claimedId` — envelope `{ success, data }`.
class MyClaimedGiftcardDetailResponse {
  MyClaimedGiftcardDetailResponse({this.success, this.data});

  final bool? success;
  final MyClaimedGiftcardDetailData? data;

  factory MyClaimedGiftcardDetailResponse.fromJson(Map<String, dynamic> json) {
    return MyClaimedGiftcardDetailResponse(
      success: json['success'] as bool?,
      data: json['data'] is Map<String, dynamic>
          ? MyClaimedGiftcardDetailData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        if (data != null) 'data': data!.toJson(),
      };
}

/// Claimed gift card instance with full `card` + catalog `info`.
class MyClaimedGiftcardDetailData {
  MyClaimedGiftcardDetailData({
    this.id,
    this.isUsedByUser,
    this.paymentId,
    this.status,
    this.createdAt,
    this.card,
    this.info,
  });

  final String? id;
  final bool? isUsedByUser;
  final String? paymentId;
  final String? status;
  final String? createdAt;
  final MyClaimedGiftcardDetailCard? card;
  final MyClaimedGiftcardDetailInfo? info;

  factory MyClaimedGiftcardDetailData.fromJson(Map<String, dynamic> json) {
    return MyClaimedGiftcardDetailData(
      id: json['id'] as String?,
      isUsedByUser: json['isUsedByUser'] as bool?,
      paymentId: json['paymentId'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      card: json['card'] is Map<String, dynamic>
          ? MyClaimedGiftcardDetailCard.fromJson(
              json['card'] as Map<String, dynamic>,
            )
          : null,
      info: json['info'] is Map<String, dynamic>
          ? MyClaimedGiftcardDetailInfo.fromJson(
              json['info'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isUsedByUser': isUsedByUser,
        'paymentId': paymentId,
        'status': status,
        'createdAt': createdAt,
        if (card != null) 'card': card!.toJson(),
        if (info != null) 'info': info!.toJson(),
      };
}

/// Physical / redemption fields for the claimed voucher.
class MyClaimedGiftcardDetailCard {
  MyClaimedGiftcardDetailCard({
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

  factory MyClaimedGiftcardDetailCard.fromJson(Map<String, dynamic> json) {
    return MyClaimedGiftcardDetailCard(
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

/// Catalog / marketing info for the underlying perk.
class MyClaimedGiftcardDetailInfo {
  MyClaimedGiftcardDetailInfo({
    this.rewardId,
    this.name,
    this.brandId,
    this.brandName,
    this.image,
    this.banner,
    this.provider,
    this.categoryName,
    this.howToRedeem,
  });

  final String? rewardId;
  final String? name;
  final String? brandId;
  final String? brandName;
  final String? image;
  final String? banner;
  final String? provider;
  final String? categoryName;

  /// Redeem steps from `Credit.howToRedeem` (plain text or HTML).
  final String? howToRedeem;

  factory MyClaimedGiftcardDetailInfo.fromJson(Map<String, dynamic> json) {
    return MyClaimedGiftcardDetailInfo(
      rewardId: json['rewardId'] as String?,
      name: json['name'] as String?,
      brandId: json['brandId'] as String?,
      brandName: json['brandName'] as String?,
      image: json['image'] as String?,
      banner: json['banner'] as String?,
      provider: json['provider'] as String?,
      categoryName: json['categoryName'] as String?,
      howToRedeem: json['howToRedeem'] as String?,
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
        'howToRedeem': howToRedeem,
      };
}
