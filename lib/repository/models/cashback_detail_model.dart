import 'home_common_models.dart';

/// `GET /rewards/cashback/:id` envelope.
class CashbackDetailResponse {
  bool? success;
  CashbackDetailData? data;

  CashbackDetailResponse({this.success, this.data});

  CashbackDetailResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    final raw = json['data'];
    if (raw is Map<String, dynamic>) {
      data = CashbackDetailData.fromJson(raw);
    }
  }

  Map<String, dynamic> toJson() {
    return {'success': success, if (data != null) 'data': data!.toJson()};
  }
}

class CashbackDetailData {
  CashbackBasicInfo? basicInfo;
  CashbackCompany? company;
  CashbackBrandRef? brand;
  CashbackCategoryRef? category;
  CashbackEligibility? eligibility;
  CashbackLegalContent? content;

  /// Present on `GET /rewards/promocode/:id` — claim state and revealed code.
  PromocodeChimed? chimed;

  /// Same shape as home listing rewards — reuse [RewardItem].
  List<RewardItem>? relatedPerks;

  CashbackDetailData({
    this.basicInfo,
    this.company,
    this.brand,
    this.category,
    this.eligibility,
    this.content,
    this.chimed,
    this.relatedPerks,
  });

  CashbackDetailData.fromJson(Map<String, dynamic> json) {
    final bi = json['basicInfo'];
    if (bi is Map<String, dynamic>) basicInfo = CashbackBasicInfo.fromJson(bi);

    final co = json['company'];
    if (co is Map<String, dynamic>) company = CashbackCompany.fromJson(co);

    final br = json['brand'];
    if (br is Map<String, dynamic>) brand = CashbackBrandRef.fromJson(br);

    final cat = json['category'];
    if (cat is Map<String, dynamic>) {
      category = CashbackCategoryRef.fromJson(cat);
    }

    final el = json['eligibility'];
    if (el is Map<String, dynamic>) {
      eligibility = CashbackEligibility.fromJson(el);
    }

    final ct = json['content'];
    if (ct is Map<String, dynamic>) content = CashbackLegalContent.fromJson(ct);

    final ch = json['chimed'];
    if (ch is Map<String, dynamic>) chimed = PromocodeChimed.fromJson(ch);

    final rp = json['relatedPerks'];
    if (rp is List) {
      relatedPerks = rp
          .whereType<Map>()
          .map((e) => RewardItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (basicInfo != null) 'basicInfo': basicInfo!.toJson(),
      if (company != null) 'company': company!.toJson(),
      if (brand != null) 'brand': brand!.toJson(),
      if (category != null) 'category': category!.toJson(),
      if (eligibility != null) 'eligibility': eligibility!.toJson(),
      if (content != null) 'content': content!.toJson(),
      if (chimed != null) 'chimed': chimed!.toJson(),
      if (relatedPerks != null)
        'relatedPerks': relatedPerks!.map((v) => v.toJson()).toList(),
    };
  }
}

class CashbackBasicInfo {
  String? id;
  String? bannerImage;
  String? image;
  String? title;
  String? ticker;
  String? perkId;
  String? type;
  bool? isEligible;
  bool? isBrokerageEligible;

  CashbackBasicInfo({
    this.id,
    this.bannerImage,
    this.image,
    this.title,
    this.ticker,
    this.perkId,
    this.type,
    this.isEligible,
    this.isBrokerageEligible,
  });

  CashbackBasicInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    bannerImage = json['bannerImage'] as String?;
    image = json['image'] as String?;
    title = json['title'] as String?;
    ticker = json['ticker'] as String?;
    perkId = json['perkId'] as String?;
    type = json['type'] as String?;
    isEligible = json['isEligible'] as bool?;
    isBrokerageEligible = json['isBrokerageEligible'] as bool?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bannerImage': bannerImage,
      'image': image,
      'title': title,
      'ticker': ticker,
      'perkId': perkId,
      'type': type,
      'isEligible': isEligible,
      'isBrokerageEligible': isBrokerageEligible,
    };
  }
}

class CashbackCompany {
  String? id;
  String? name;
  String? image;
  String? isin;
  bool? listedOnExchange;

  CashbackCompany({
    this.id,
    this.name,
    this.image,
    this.isin,
    this.listedOnExchange,
  });

  CashbackCompany.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    image = json['image'] as String?;
    isin = json['isin'] as String?;
    listedOnExchange = json['listedOnExchange'] as bool?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'isin': isin,
      'listedOnExchange': listedOnExchange,
    };
  }
}

class CashbackBrandRef {
  String? id;
  String? name;
  String? image;

  CashbackBrandRef({this.id, this.name, this.image});

  CashbackBrandRef.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    image = json['image'] as String?;
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'image': image};
}

class CashbackCategoryRef {
  String? id;
  String? name;
  String? image;

  CashbackCategoryRef({this.id, this.name, this.image});

  CashbackCategoryRef.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    image = json['image'] as String?;
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'image': image};
}

class CashbackEligibility {
  int? days;
  int? quantity;
  bool? isEligible;
  bool? isBrokerageEligible;
  String? rewardType;
  double? withHolderRewardRate;
  double? withAnyHoldingRewardRate;
  double? nonHolderRewardRate;
  RewardBrokerConnected? isBrokerConnected;

  CashbackEligibility({
    this.days,
    this.quantity,
    this.isEligible,
    this.isBrokerageEligible,
    this.rewardType,
    this.withHolderRewardRate,
    this.withAnyHoldingRewardRate,
    this.nonHolderRewardRate,
    this.isBrokerConnected,
  });

  CashbackEligibility.fromJson(Map<String, dynamic> json) {
    days = parseJsonInt(json['days']);
    quantity = parseJsonInt(json['quantity']);
    isEligible = json['isEligible'] as bool?;
    isBrokerageEligible = json['isBrokerageEligible'] as bool?;
    rewardType = json['rewardType'] as String?;
    withHolderRewardRate = parseJsonDouble(json['withHolderRewardRate']);
    withAnyHoldingRewardRate = parseJsonDouble(json['withAnyHoldingRewardRate']);
    nonHolderRewardRate = parseJsonDouble(json['nonHolderRewardRate']);

    final bc = json['isBrokerConnected'];
    if (bc is Map<String, dynamic>) {
      isBrokerConnected = RewardBrokerConnected.fromJson(bc);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'quantity': quantity,
      'isEligible': isEligible,
      'isBrokerageEligible': isBrokerageEligible,
      'rewardType': rewardType,
      'withHolderRewardRate': withHolderRewardRate,
      'withAnyHoldingRewardRate': withAnyHoldingRewardRate,
      'nonHolderRewardRate': nonHolderRewardRate,
      if (isBrokerConnected != null)
        'isBrokerConnected': isBrokerConnected!.toJson(),
    };
  }
}

class RewardBrokerConnected {
  bool? connected;
  bool? reqReimport;

  RewardBrokerConnected({this.connected, this.reqReimport});

  RewardBrokerConnected.fromJson(Map<String, dynamic> json) {
    connected = json['connected'] as bool?;
    reqReimport = json['reqReimport'] as bool?;
  }

  Map<String, dynamic> toJson() => {
    'connected': connected,
    'reqReimport': reqReimport,
  };
}

/// `data.chimed` on `GET /rewards/promocode/:id`.
class PromocodeChimed {
  bool? claimed;
  String? code;
  bool? isEligible;
  String? chimedAt;
  String? claimedId;

  PromocodeChimed({
    this.claimed,
    this.code,
    this.isEligible,
    this.chimedAt,
    this.claimedId,
  });

  PromocodeChimed.fromJson(Map<String, dynamic> json) {
    claimed = json['claimed'] as bool?;
    code = json['code'] as String?;
    claimedId = json['claimedId'] as String?;
    isEligible = json['isEligible'] as bool?;
    chimedAt = json['chimedAt'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'claimed': claimed,
      'code': code,
      'isEligible': isEligible,
      'chimedAt': chimedAt,
      'claimedId': claimedId,
    };
  }
}

class CashbackLegalContent {
  String? id;
  String? description;
  String? termsAndConditions;

  CashbackLegalContent({this.id, this.description, this.termsAndConditions});

  CashbackLegalContent.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    description = json['description'] as String?;
    termsAndConditions = json['termsAndConditions'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'termsAndConditions': termsAndConditions,
    };
  }
}
