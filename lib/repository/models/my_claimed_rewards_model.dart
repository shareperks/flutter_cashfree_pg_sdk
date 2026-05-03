import 'home_common_models.dart';

/// `GET /rewards/my-claimed` — `{ success, data }`.
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

/// `data`: totals, month stats, holding state, flat [perks] list.
class MyClaimedRewardsData {
  MyClaimedRewardsData({
    this.totalSaved,
    this.savedThisMonth,
    this.totalUnlocked,
    this.thisMonthUnlocked,
    this.isConnected,
    this.perks,
  });

  final int? totalSaved;
  final int? savedThisMonth;
  final int? totalUnlocked;
  final int? thisMonthUnlocked;
  final MyClaimedHoldingConnection? isConnected;
  final List<MyClaimedPerk>? perks;

  factory MyClaimedRewardsData.fromJson(Map<String, dynamic> json) {
    return MyClaimedRewardsData(
      totalSaved: parseJsonInt(json['totalSaved']),
      savedThisMonth: parseJsonInt(json['savedThisMonth']),
      totalUnlocked: parseJsonInt(json['totalUnlocked']),
      thisMonthUnlocked: parseJsonInt(json['thisMonthUnlocked']),
      isConnected: json['isConnected'] is Map<String, dynamic>
          ? MyClaimedHoldingConnection.fromJson(
              json['isConnected'] as Map<String, dynamic>,
            )
          : null,
      perks: _mapPerks(json['perks']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalSaved': totalSaved,
        'savedThisMonth': savedThisMonth,
        'totalUnlocked': totalUnlocked,
        'thisMonthUnlocked': thisMonthUnlocked,
        if (isConnected != null) 'isConnected': isConnected!.toJson(),
        if (perks != null) 'perks': perks!.map((e) => e.toJson()).toList(),
      };

  static List<MyClaimedPerk>? _mapPerks(dynamic raw) {
    if (raw is! List<dynamic>) return null;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MyClaimedPerk.fromJson)
        .toList();
  }
}

class MyClaimedHoldingConnection {
  MyClaimedHoldingConnection({this.connected, this.reqReimport});

  final bool? connected;
  final bool? reqReimport;

  factory MyClaimedHoldingConnection.fromJson(Map<String, dynamic> json) {
    return MyClaimedHoldingConnection(
      connected: json['connected'] as bool?,
      reqReimport: json['reqReimport'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'connected': connected,
        'reqReimport': reqReimport,
      };
}

/// One row in `data.perks` (gift card, offer, etc.).
class MyClaimedPerk {
  MyClaimedPerk({
    this.claimedId,
    this.rewardId,
    this.image,
    this.name,
    this.rewardValue,
    this.expiredAt,
    this.expireAtFormatted,
    this.type,
    this.used,
    this.term,
    this.expired,
    this.code,
  });

  /// Claimed-instance id (for `GET /rewards/my-claimed/giftcard/:claimedId`).
  final String? claimedId;

  /// Catalog reward id (for perk detail screens).
  final String? rewardId;

  final String? image;
  final String? name;
  final int? rewardValue;

  /// ISO expiry (API field `expiredAt`).
  final String? expiredAt;

  final String? expireAtFormatted;

  /// e.g. `CREDIT`, `OFFER`, `BENEFIT`.
  final String? type;
  final bool? used;

  /// Pre-formatted label, e.g. `₹ 10.00` or `₹ 0 OFF`.
  final String? term;

  /// Server-side expiry flag; when null, [isExpired] falls back to [expiredAt].
  final bool? expired;

  /// Promo code for `OFFER` rows; omitted for e.g. `CREDIT`.
  final String? code;

  factory MyClaimedPerk.fromJson(Map<String, dynamic> json) {
    return MyClaimedPerk(
      claimedId: json['claimedId'] as String? ?? json['id'] as String?,
      rewardId: json['rewardId'] as String?,
      image: json['image'] as String?,
      name: json['name'] as String?,
      rewardValue: parseJsonInt(json['rewardValue']),
      expiredAt: json['expiredAt'] as String? ?? json['expireAt'] as String?,
      expireAtFormatted: json['expireAtFormatted'] as String?,
      type: json['type'] as String?,
      used: json['used'] as bool?,
      term: json['term'] as String?,
      expired: json['expired'] as bool?,
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'claimedId': claimedId,
        'rewardId': rewardId,
        'image': image,
        'name': name,
        'rewardValue': rewardValue,
        'expiredAt': expiredAt,
        'expireAtFormatted': expireAtFormatted,
        'type': type,
        'used': used,
        'term': term,
        'expired': expired,
        'code': code,
      };

  /// Uses [expired] when set; otherwise derives from [expiredAt].
  bool get isExpired {
    if (expired != null) return expired == true;
    final raw = expiredAt?.trim();
    if (raw == null || raw.isEmpty) return false;
    final d = DateTime.tryParse(raw);
    if (d == null) return false;
    return d.isBefore(DateTime.now());
  }
}
