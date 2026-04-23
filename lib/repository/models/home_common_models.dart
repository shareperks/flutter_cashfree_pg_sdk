// Shared JSON models for home listing payloads (rewards, brands, slides, categories).
import 'category_model.dart';

/// Parses int from JSON (handles int, double, or string).
int? parseJsonInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class User {
  String? id;
  String? name;
  String? email;
  String? mobile;
  String? image;

  User({this.id, this.name, this.email, this.mobile, this.image});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    email = json['email'] as String?;
    mobile = json['mobile'] as String?;
    image = json['image'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'image': image,
    };
  }
}

/// Listing reward: same shape for [UnlockedRewards.rewards] and [HomeData.topRewards].
class RewardItem {
  String? id;
  String? title;
  String? description;
  String? image;
  String? bannerImage;
  String? brandId;
  String? brandName;
  String? brandImage;
  String? isin;
  String? companyId;
  String? companyName;
  String? categoryId;
  String? categoryName;
  String? tickerName;
  String? type;
  bool? isEligible;
  bool? isNew;
  bool? topPerk;
  int? quantity;
  int? holdingDays;

  RewardItem({
    this.id,
    this.title,
    this.description,
    this.image,
    this.bannerImage,
    this.brandId,
    this.brandName,
    this.brandImage,
    this.isin,
    this.companyId,
    this.companyName,
    this.categoryId,
    this.categoryName,
    this.tickerName,
    this.type,
    this.isEligible,
    this.isNew,
    this.topPerk,
    this.quantity,
    this.holdingDays,
  });

  RewardItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    title = json['title'] as String?;
    description = json['description'] as String?;
    image = json['image'] as String?;
    bannerImage = json['bannerImage'] as String?;
    brandId = json['brandId'] as String?;
    brandName = json['brandName'] as String?;
    brandImage = json['brandImage'] as String?;
    isin = json['isin'] as String?;
    companyId = json['companyId'] as String?;
    companyName = json['companyName'] as String?;
    categoryId = json['categoryId'] as String?;
    categoryName = json['categoryName'] as String?;
    tickerName = json['tickerName'] as String?;
    type = json['type'] as String?;
    isEligible = json['isEligible'] as bool?;
    isNew = json['isNew'] as bool?;
    topPerk = json['topPerk'] as bool?;
    quantity = parseJsonInt(json['quantity']);
    holdingDays = parseJsonInt(json['holdingDays']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'bannerImage': bannerImage,
      'brandId': brandId,
      'brandName': brandName,
      'brandImage': brandImage,
      'isin': isin,
      'companyId': companyId,
      'companyName': companyName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'tickerName': tickerName,
      'type': type,
      'isEligible': isEligible,
      'isNew': isNew,
      'topPerk': topPerk,
      'quantity': quantity,
      'holdingDays': holdingDays,
    };
  }
}

class BrandItem {
  String? id;
  String? name;
  String? image;
  String? description;
  String? bannerImage;
  String? companyId;
  String? companyName;
  bool? listedOnExchange;
  String? isin;
  String? categoryName;
  String? categoryId;
  String? brandId;
  String? brandName;
  String? brandImage;
  String? tickerName;
  String? type;
  bool? isTopBrand;
  bool? isNew;

  BrandItem({
    this.id,
    this.name,
    this.image,
    this.description,
    this.bannerImage,
    this.companyId,
    this.companyName,
    this.listedOnExchange,
    this.isin,
    this.categoryName,
    this.categoryId,
    this.brandId,
    this.brandName,
    this.brandImage,
    this.tickerName,
    this.type,
    this.isTopBrand,
    this.isNew,
  });

  BrandItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    image = json['image'] as String?;
    description = json['description'] as String?;
    bannerImage = json['bannerImage'] as String?;
    companyId = json['companyId'] as String?;
    companyName = json['companyName'] as String?;
    listedOnExchange = json['listedOnExchange'] as bool?;
    isin = json['isin'] as String?;
    categoryName = json['categoryName'] as String?;
    categoryId = json['categoryId'] as String?;
    brandId = json['brandId'] as String?;
    brandName = json['brandName'] as String?;
    brandImage = json['brandImage'] as String?;
    tickerName = json['tickerName'] as String?;
    type = json['type'] as String?;
    isTopBrand = json['isTopBrand'] as bool?;
    isNew = json['isNew'] as bool?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'bannerImage': bannerImage,
      'companyId': companyId,
      'companyName': companyName,
      'listedOnExchange': listedOnExchange,
      'isin': isin,
      'categoryName': categoryName,
      'categoryId': categoryId,
      'brandId': brandId,
      'brandName': brandName,
      'brandImage': brandImage,
      'tickerName': tickerName,
      'type': type,
      'isTopBrand': isTopBrand,
      'isNew': isNew,
    };
  }
}

class HomeSlide {
  String? id;
  String? image;
  String? type;
  String? rewardId;
  int? order;

  /// JSON key `interface` (reserved in Dart).
  String? slideInterface;
  String? imageUrl;
  bool? isEligible;

  HomeSlide({
    this.id,
    this.image,
    this.type,
    this.rewardId,
    this.order,
    this.slideInterface,
    this.imageUrl,
    this.isEligible,
  });

  HomeSlide.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    image = json['image'] as String?;
    type = json['type'] as String?;
    rewardId = json['rewardId'] as String?;
    order = parseJsonInt(json['order']);
    slideInterface = json['interface'] as String?;
    imageUrl = json['imageUrl'] as String?;
    isEligible = json['isEligible'] as bool?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'type': type,
      'rewardId': rewardId,
      'order': order,
      'interface': slideInterface,
      'imageUrl': imageUrl,
      'isEligible': isEligible,
    };
  }
}

/// Backward-compatible home payload category model.
///
/// The API now returns the same shape as [CategoryModel], including `isNew`.
class HomeCategory extends CategoryModel {
  HomeCategory({super.id, super.name, super.image, super.type, super.isNew});

  HomeCategory.fromJson(super.json) : super.fromJson();
}
