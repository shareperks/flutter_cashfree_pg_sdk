import 'home_common_models.dart';

class RewardsByCompanyResponse {
  bool? success;
  RewardsByCompanyData? data;

  RewardsByCompanyResponse({this.success, this.data});

  RewardsByCompanyResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    data = json['data'] is Map<String, dynamic>
        ? RewardsByCompanyData.fromJson(json['data'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (data != null) 'data': data!.toJson(),
    };
  }
}

class RewardsByCompanyData {
  CompanyItem? company;
  List<RewardItem>? rewards;
  List<BrandItem>? brands;

  RewardsByCompanyData({this.company, this.rewards, this.brands});

  RewardsByCompanyData.fromJson(Map<String, dynamic> json) {
    company = json['company'] is Map<String, dynamic>
        ? CompanyItem.fromJson(json['company'] as Map<String, dynamic>)
        : null;

    if (json['rewards'] is List) {
      rewards = (json['rewards'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => RewardItem.fromJson(e))
          .toList();
    }

    if (json['brands'] is List) {
      brands = (json['brands'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => BrandItem.fromJson(e))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (company != null) 'company': company!.toJson(),
      if (rewards != null) 'rewards': rewards!.map((e) => e.toJson()).toList(),
      if (brands != null) 'brands': brands!.map((e) => e.toJson()).toList(),
    };
  }
}

class CompanyItem {
  String? id;
  String? name;
  String? image;
  String? bannerImage;
  String? description;
  bool? listedOnExchange;
  String? isin;
  String? logo;
  bool? holding;

  CompanyItem({
    this.id,
    this.name,
    this.image,
    this.bannerImage,
    this.description,
    this.listedOnExchange,
    this.isin,
    this.logo,
    this.holding,
  });

  CompanyItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    image = json['image'] as String?;
    bannerImage = json['bannerImage'] as String?;
    description = json['description'] as String?;
    listedOnExchange = json['listedOnExchange'] as bool?;
    isin = json['isin'] as String?;
    logo = json['logo'] as String?;
    holding = json['holding'] as bool?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'bannerImage': bannerImage,
      'description': description,
      'listedOnExchange': listedOnExchange,
      'isin': isin,
      'logo': logo,
      'holding': holding,
    };
  }
}

