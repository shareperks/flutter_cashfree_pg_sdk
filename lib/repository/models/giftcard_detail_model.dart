import 'home_common_models.dart';

/// `GET /rewards/giftcard/:id` envelope.
class GiftcardDetailResponse {
  bool? success;
  GiftcardDetailData? data;

  GiftcardDetailResponse({this.success, this.data});

  GiftcardDetailResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    final raw = json['data'];
    if (raw is Map<String, dynamic>) {
      data = GiftcardDetailData.fromJson(raw);
    }
  }

  Map<String, dynamic> toJson() {
    return {'success': success, if (data != null) 'data': data!.toJson()};
  }
}

class GiftcardDetailData {
  GiftcardBasicInfo? basicInfo;
  GiftcardAmount? amount;
  GiftcardCategoryRef? category;
  GiftcardBrandRef? brand;
  GiftcardEligibility? eligibility;
  GiftcardLegalContent? content;
  GiftcardCompany? company;

  /// Same shape as home listing rewards — reuse [RewardItem].
  List<RewardItem>? relatedPerks;

  GiftcardDetailData({
    this.basicInfo,
    this.amount,
    this.category,
    this.brand,
    this.eligibility,
    this.content,
    this.company,
    this.relatedPerks,
  });

  GiftcardDetailData.fromJson(Map<String, dynamic> json) {
    final bi = json['basicInfo'];
    if (bi is Map<String, dynamic>) {
      basicInfo = GiftcardBasicInfo.fromJson(bi);
    }
    final am = json['amount'];
    if (am is Map<String, dynamic>) {
      amount = GiftcardAmount.fromJson(am);
    }
    final cat = json['category'];
    if (cat is Map<String, dynamic>) {
      category = GiftcardCategoryRef.fromJson(cat);
    }
    final br = json['brand'];
    if (br is Map<String, dynamic>) {
      brand = GiftcardBrandRef.fromJson(br);
    }
    final el = json['eligibility'];
    if (el is Map<String, dynamic>) {
      eligibility = GiftcardEligibility.fromJson(el);
    }
    final ct = json['content'];
    if (ct is Map<String, dynamic>) {
      content = GiftcardLegalContent.fromJson(ct);
    }
    final co = json['company'];
    if (co is Map<String, dynamic>) {
      company = GiftcardCompany.fromJson(co);
    }
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
      if (amount != null) 'amount': amount!.toJson(),
      if (category != null) 'category': category!.toJson(),
      if (brand != null) 'brand': brand!.toJson(),
      if (eligibility != null) 'eligibility': eligibility!.toJson(),
      if (content != null) 'content': content!.toJson(),
      if (company != null) 'company': company!.toJson(),
      if (relatedPerks != null)
        'relatedPerks': relatedPerks!.map((v) => v.toJson()).toList(),
    };
  }
}

class GiftcardBasicInfo {
  String? id;
  String? bannerImage;
  String? image;
  String? title;
  String? ticker;
  String? perkId;
  String? type;
  bool? isEligible;
  int? days;
  int? quantity;

  GiftcardBasicInfo({
    this.id,
    this.bannerImage,
    this.image,
    this.title,
    this.ticker,
    this.perkId,
    this.type,
    this.isEligible,
    this.days,
    this.quantity,
  });

  GiftcardBasicInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    bannerImage = json['bannerImage'] as String?;
    image = json['image'] as String?;
    title = json['title'] as String?;
    ticker = json['ticker'] as String?;
    perkId = json['perkId'] as String?;
    type = json['type'] as String?;
    isEligible = json['isEligible'] as bool?;
    days = parseJsonInt(json['days']);
    quantity = parseJsonInt(json['quantity']);
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
      'days': days,
      'quantity': quantity,
    };
  }
}

class GiftcardAmount {
  int? min;
  int? max;
  List<int>? options;
  String? optionType;
  bool? isAmountSelectable;
  bool? isAmountEditable;

  GiftcardAmount({
    this.min,
    this.max,
    this.options,
    this.optionType,
    this.isAmountSelectable,
    this.isAmountEditable,
  });

  GiftcardAmount.fromJson(Map<String, dynamic> json) {
    min = parseJsonInt(json['min']);
    max = parseJsonInt(json['max']);
    if (json['options'] != null) {
      options = <int>[];
      for (final v in json['options'] as List<dynamic>) {
        final n = parseJsonInt(v);
        if (n != null) options!.add(n);
      }
    }
    optionType = json['optionType'] as String?;
    isAmountSelectable = json['isAmountSelectable'] as bool?;
    isAmountEditable = json['isAmountEditable'] as bool?;
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      if (options != null) 'options': options,
      'optionType': optionType,
      'isAmountSelectable': isAmountSelectable,
      'isAmountEditable': isAmountEditable,
    };
  }
}

class GiftcardCategoryRef {
  String? id;
  String? name;
  String? image;

  GiftcardCategoryRef({this.id, this.name, this.image});

  GiftcardCategoryRef.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    image = json['image'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image};
  }
}

class GiftcardBrandRef {
  String? id;
  String? name;
  String? image;

  GiftcardBrandRef({this.id, this.name, this.image});

  GiftcardBrandRef.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    image = json['image'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image};
  }
}

class GiftcardEligibility {
  int? days;
  int? quantity;
  String? rewardType;
  int? withHolderRewardRate;
  int? nonHolderRewardRate;
  bool? isEligible;
  GiftcardBrokerConnected? isBrokerConnected;

  GiftcardEligibility({
    this.days,
    this.quantity,
    this.rewardType,
    this.withHolderRewardRate,
    this.nonHolderRewardRate,
    this.isEligible,
    this.isBrokerConnected,
  });

  GiftcardEligibility.fromJson(Map<String, dynamic> json) {
    days = parseJsonInt(json['days']);
    quantity = parseJsonInt(json['quantity']);
    rewardType = json['rewardType'] as String?;
    withHolderRewardRate = parseJsonInt(json['withHolderRewardRate']);
    nonHolderRewardRate = parseJsonInt(json['nonHolderRewardRate']);
    isEligible = json['isEligible'] as bool?;
    final bc = json['isBrokerConnected'];
    if (bc is Map<String, dynamic>) {
      isBrokerConnected = GiftcardBrokerConnected.fromJson(bc);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'quantity': quantity,
      'rewardType': rewardType,
      'withHolderRewardRate': withHolderRewardRate,
      'nonHolderRewardRate': nonHolderRewardRate,
      'isEligible': isEligible,
      if (isBrokerConnected != null)
        'isBrokerConnected': isBrokerConnected!.toJson(),
    };
  }
}

class GiftcardBrokerConnected {
  bool? connected;
  bool? reqReimport;

  GiftcardBrokerConnected({this.connected, this.reqReimport});

  GiftcardBrokerConnected.fromJson(Map<String, dynamic> json) {
    connected = json['connected'] as bool?;
    reqReimport = json['reqReimport'] as bool?;
  }

  Map<String, dynamic> toJson() {
    return {'connected': connected, 'reqReimport': reqReimport};
  }
}

class GiftcardLegalContent {
  String? id;
  String? description;
  String? termsAndConditions;

  GiftcardLegalContent({this.id, this.description, this.termsAndConditions});

  GiftcardLegalContent.fromJson(Map<String, dynamic> json) {
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

class GiftcardCompany {
  String? id;
  String? name;
  String? image;
  String? isin;
  bool? listedOnExchange;

  GiftcardCompany({
    this.id,
    this.name,
    this.image,
    this.isin,
    this.listedOnExchange,
  });

  GiftcardCompany.fromJson(Map<String, dynamic> json) {
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
