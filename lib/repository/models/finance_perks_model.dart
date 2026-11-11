import 'home_common_models.dart';

/// `GET /api/company/:ticker/perks` — shareholder perks for one company.
///
/// `GET /api/perks` returns the same shape without the `ticker` / `isin`
/// envelope fields (see [FinancePerksResponse.maybeTicker]).
class FinancePerksResponse {
  final String? ticker;
  final String? isin;
  final List<FinanceGiftCard> giftCards;
  final List<FinanceCashback> cashbacks;
  final List<FinanceDiscountCode> discountCodes;

  FinancePerksResponse({
    this.ticker,
    this.isin,
    this.giftCards = const [],
    this.cashbacks = const [],
    this.discountCodes = const [],
  });

  factory FinancePerksResponse.fromJson(Map<String, dynamic> json) {
    return FinancePerksResponse(
      ticker: json['ticker'] as String?,
      isin: json['isin'] as String?,
      giftCards: _asList(json['giftCards'], FinanceGiftCard.fromJson),
      cashbacks: _asList(json['cashbacks'], FinanceCashback.fromJson),
      discountCodes: _asList(
        json['discountCodes'],
        FinanceDiscountCode.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    if (ticker != null) 'ticker': ticker,
    if (isin != null) 'isin': isin,
    'giftCards': giftCards.map((e) => e.toJson()).toList(),
    'cashbacks': cashbacks.map((e) => e.toJson()).toList(),
    'discountCodes': discountCodes.map((e) => e.toJson()).toList(),
  };

  bool get isEmpty =>
      giftCards.isEmpty && cashbacks.isEmpty && discountCodes.isEmpty;
}

List<T> _asList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return <T>[];
  return raw
      .whereType<Map>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

/// Reward eligibility tier shared by every perk kind.
class FinanceEligibility {
  final int? minHoldingQuantity;
  final int? minHoldingDays;
  final String? rewardType;
  final double? withHolderRewardRate;
  final double? withAnyHoldingRewardRate;
  final double? nonHolderRewardRate;

  FinanceEligibility({
    this.minHoldingQuantity,
    this.minHoldingDays,
    this.rewardType,
    this.withHolderRewardRate,
    this.withAnyHoldingRewardRate,
    this.nonHolderRewardRate,
  });

  factory FinanceEligibility.fromJson(Map<String, dynamic> json) {
    return FinanceEligibility(
      minHoldingQuantity: parseJsonInt(json['minHoldingQuantity']),
      minHoldingDays: parseJsonInt(json['minHoldingDays']),
      rewardType: json['rewardType'] as String?,
      withHolderRewardRate: parseJsonDouble(json['withHolderRewardRate']),
      withAnyHoldingRewardRate: parseJsonDouble(
        json['withAnyHoldingRewardRate'],
      ),
      nonHolderRewardRate: parseJsonDouble(json['nonHolderRewardRate']),
    );
  }

  Map<String, dynamic> toJson() => {
    'minHoldingQuantity': minHoldingQuantity,
    'minHoldingDays': minHoldingDays,
    'rewardType': rewardType,
    'withHolderRewardRate': withHolderRewardRate,
    'withAnyHoldingRewardRate': withAnyHoldingRewardRate,
    'nonHolderRewardRate': nonHolderRewardRate,
  };
}

/// `GET /api/company/:ticker/perks` → `giftCards[]`.
class FinanceGiftCard {
  final String? id;
  final String? title;
  final String? description;
  final String? image;
  final String? brandName;
  final String? brandImage;
  final String? companyName;
  final String? companyIsin;
  final String? provider;
  final String? optionType;
  final List<double> options;
  final double? minAmount;
  final double? maxAmount;
  final String? howToRedeem;
  final bool? topReward;
  final FinanceEligibility? eligibility;
  final String? terms;

  FinanceGiftCard({
    this.id,
    this.title,
    this.description,
    this.image,
    this.brandName,
    this.brandImage,
    this.companyName,
    this.companyIsin,
    this.provider,
    this.optionType,
    this.options = const [],
    this.minAmount,
    this.maxAmount,
    this.howToRedeem,
    this.topReward,
    this.eligibility,
    this.terms,
  });

  factory FinanceGiftCard.fromJson(Map<String, dynamic> json) {
    return FinanceGiftCard(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      brandName: json['brandName'] as String?,
      brandImage: json['brandImage'] as String?,
      companyName: json['companyName'] as String?,
      companyIsin: json['companyIsin'] as String?,
      provider: json['provider'] as String?,
      optionType: json['optionType'] as String?,
      options: (json['options'] as List?)
              ?.whereType<num>()
              .map((e) => e.toDouble())
              .toList() ??
          const [],
      minAmount: parseJsonDouble(json['minAmount']),
      maxAmount: parseJsonDouble(json['maxAmount']),
      howToRedeem: json['howToRedeem'] as String?,
      topReward: json['topReward'] as bool?,
      eligibility: json['eligibility'] is Map<String, dynamic>
          ? FinanceEligibility.fromJson(json['eligibility'] as Map<String, dynamic>)
          : null,
      terms: json['terms'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'image': image,
    'brandName': brandName,
    'brandImage': brandImage,
    'companyName': companyName,
    'companyIsin': companyIsin,
    'provider': provider,
    'optionType': optionType,
    'options': options,
    'minAmount': minAmount,
    'maxAmount': maxAmount,
    'howToRedeem': howToRedeem,
    'topReward': topReward,
    if (eligibility != null) 'eligibility': eligibility!.toJson(),
    'terms': terms,
  };
}

/// `GET /api/company/:ticker/perks` → `cashbacks[]`.
class FinanceCashback {
  final String? id;
  final String? title;
  final String? description;
  final String? image;
  final String? brandName;
  final String? brandImage;
  final String? companyName;
  final String? companyIsin;
  final bool? topReward;
  final FinanceEligibility? eligibility;
  final String? terms;

  FinanceCashback({
    this.id,
    this.title,
    this.description,
    this.image,
    this.brandName,
    this.brandImage,
    this.companyName,
    this.companyIsin,
    this.topReward,
    this.eligibility,
    this.terms,
  });

  factory FinanceCashback.fromJson(Map<String, dynamic> json) {
    return FinanceCashback(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      brandName: json['brandName'] as String?,
      brandImage: json['brandImage'] as String?,
      companyName: json['companyName'] as String?,
      companyIsin: json['companyIsin'] as String?,
      topReward: json['topReward'] as bool?,
      eligibility: json['eligibility'] is Map<String, dynamic>
          ? FinanceEligibility.fromJson(json['eligibility'] as Map<String, dynamic>)
          : null,
      terms: json['terms'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'image': image,
    'brandName': brandName,
    'brandImage': brandImage,
    'companyName': companyName,
    'companyIsin': companyIsin,
    'topReward': topReward,
    if (eligibility != null) 'eligibility': eligibility!.toJson(),
    'terms': terms,
  };
}

/// `GET /api/company/:ticker/perks` → `discountCodes[]`.
class FinanceDiscountCode {
  final String? id;
  final String? title;
  final String? description;
  final String? image;
  final String? brandName;
  final String? brandImage;
  final String? companyName;
  final String? companyIsin;
  final bool? topReward;
  final FinanceEligibility? eligibility;
  final String? terms;

  FinanceDiscountCode({
    this.id,
    this.title,
    this.description,
    this.image,
    this.brandName,
    this.brandImage,
    this.companyName,
    this.companyIsin,
    this.topReward,
    this.eligibility,
    this.terms,
  });

  factory FinanceDiscountCode.fromJson(Map<String, dynamic> json) {
    return FinanceDiscountCode(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      brandName: json['brandName'] as String?,
      brandImage: json['brandImage'] as String?,
      companyName: json['companyName'] as String?,
      companyIsin: json['companyIsin'] as String?,
      topReward: json['topReward'] as bool?,
      eligibility: json['eligibility'] is Map<String, dynamic>
          ? FinanceEligibility.fromJson(json['eligibility'] as Map<String, dynamic>)
          : null,
      terms: json['terms'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'image': image,
    'brandName': brandName,
    'brandImage': brandImage,
    'companyName': companyName,
    'companyIsin': companyIsin,
    'topReward': topReward,
    if (eligibility != null) 'eligibility': eligibility!.toJson(),
    'terms': terms,
  };
}

/// `GET /api/company/:ticker/profile`.
class FinanceProfileResponse {
  final String? ticker;
  final FinanceProfile? profile;

  FinanceProfileResponse({this.ticker, this.profile});

  factory FinanceProfileResponse.fromJson(Map<String, dynamic> json) {
    return FinanceProfileResponse(
      ticker: json['ticker'] as String?,
      profile: json['profile'] is Map<String, dynamic>
          ? FinanceProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (ticker != null) 'ticker': ticker,
    if (profile != null) 'profile': profile!.toJson(),
  };
}

class FinanceProfile {
  final String? name;
  final String? symbol;
  final String? nseCode;
  final String? bseCode;
  final String? isin;
  final String? sector;
  final String? industry;
  final String? subIndustry;
  final double? marketCap;
  final String? description;

  FinanceProfile({
    this.name,
    this.symbol,
    this.nseCode,
    this.bseCode,
    this.isin,
    this.sector,
    this.industry,
    this.subIndustry,
    this.marketCap,
    this.description,
  });

  factory FinanceProfile.fromJson(Map<String, dynamic> json) {
    return FinanceProfile(
      name: json['name'] as String?,
      symbol: json['symbol'] as String?,
      nseCode: json['nse_code'] as String?,
      bseCode: json['bse_code'] as String?,
      isin: json['isin'] as String?,
      sector: json['sector'] as String?,
      industry: json['industry'] as String?,
      subIndustry: json['sub_industry'] as String?,
      marketCap: parseJsonDouble(json['market_cap']),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'symbol': symbol,
    'nse_code': nseCode,
    'bse_code': bseCode,
    'isin': isin,
    'sector': sector,
    'industry': industry,
    'sub_industry': subIndustry,
    'market_cap': marketCap,
    'description': description,
  };
}
