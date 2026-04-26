import 'home_common_models.dart';

class RewardsByBrandResponse {
  bool? success;
  RewardsByBrandData? data;

  RewardsByBrandResponse({this.success, this.data});

  RewardsByBrandResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    data = json['data'] != null
        ? RewardsByBrandData.fromJson(json['data'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    return {'success': success, if (data != null) 'data': data!.toJson()};
  }
}

class RewardsByBrandData {
  BrandItem? brand;
  List<RewardItem>? rewards;

  RewardsByBrandData({this.brand, this.rewards});

  RewardsByBrandData.fromJson(Map<String, dynamic> json) {
    brand = json['brand'] != null
        ? BrandItem.fromJson(json['brand'] as Map<String, dynamic>)
        : null;
    if (json['rewards'] != null) {
      rewards = <RewardItem>[];
      for (final v in json['rewards'] as List<dynamic>) {
        rewards!.add(RewardItem.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (brand != null) 'brand': brand!.toJson(),
      if (rewards != null) 'rewards': rewards!.map((v) => v.toJson()).toList(),
    };
  }
}
