import 'home_common_models.dart';

/// Brand row inside a voting listing (`item.brands` / `item.mySubmit`).
class VotingListingBrand {
  String? id;
  String? name;
  String? ticker;
  String? image;
  String? createAt;
  String? updateAt;

  VotingListingBrand({
    this.id,
    this.name,
    this.ticker,
    this.image,
    this.createAt,
    this.updateAt,
  });

  VotingListingBrand.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    ticker = json['ticker'] as String?;
    image = json['image'] as String?;
    createAt = json['createAt'] as String?;
    updateAt = json['updateAt'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ticker': ticker,
      'image': image,
      'createAt': createAt,
      'updateAt': updateAt,
    };
  }
}

/// Active voting window + candidates and optional user submission.
class VotingListingItem {
  String? id;
  String? startAt;
  String? endAt;
  bool? status;
  bool? isActive;
  List<VotingListingBrand>? brands;
  VotingListingBrand? mySubmit;
  String? submitAt;
  int? remainSec;

  /// Server-provided fractional hours remaining (e.g. `"206.0"`).
  String? remainHours;

  VotingListingItem({
    this.id,
    this.startAt,
    this.endAt,
    this.status,
    this.isActive,
    this.brands,
    this.mySubmit,
    this.submitAt,
    this.remainSec,
    this.remainHours,
  });

  VotingListingItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    startAt = json['startAt'] as String?;
    endAt = json['endAt'] as String?;
    status = json['status'] as bool?;
    isActive = json['isActive'] as bool?;
    if (json['brands'] != null) {
      brands = <VotingListingBrand>[];
      for (final v in json['brands'] as List<dynamic>) {
        brands!.add(VotingListingBrand.fromJson(v as Map<String, dynamic>));
      }
    }
    final my = json['mySubmit'];
    if (my is Map<String, dynamic>) {
      mySubmit = VotingListingBrand.fromJson(my);
    }
    submitAt = json['submitAt'] as String?;
    remainSec = parseJsonInt(json['remainSec']);
    remainHours = json['remainHours']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startAt': startAt,
      'endAt': endAt,
      'status': status,
      'isActive': isActive,
      if (brands != null) 'brands': brands!.map((v) => v.toJson()).toList(),
      if (mySubmit != null) 'mySubmit': mySubmit!.toJson(),
      'submitAt': submitAt,
      'remainSec': remainSec,
      'remainHours': remainHours,
    };
  }
}

/// `GET /api/voting/listing` (or equivalent) envelope.
class VotingListingResponse {
  bool? success;
  VotingListingItem? item;

  VotingListingResponse({this.success, this.item});

  VotingListingResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    final raw = json['item'];
    if (raw is Map<String, dynamic>) {
      item = VotingListingItem.fromJson(raw);
    }
  }

  Map<String, dynamic> toJson() {
    return {'success': success, if (item != null) 'item': item!.toJson()};
  }
}

/// Voting window as returned on submit (`item.voting`) — subset of listing fields + audit times.
class VotingSession {
  String? id;
  String? startAt;
  String? endAt;
  bool? isActive;
  String? createAt;
  String? updateAt;

  VotingSession({
    this.id,
    this.startAt,
    this.endAt,
    this.isActive,
    this.createAt,
    this.updateAt,
  });

  VotingSession.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    startAt = json['startAt'] as String?;
    endAt = json['endAt'] as String?;
    isActive = json['isActive'] as bool?;
    createAt = json['createAt'] as String?;
    updateAt = json['updateAt'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startAt': startAt,
      'endAt': endAt,
      'isActive': isActive,
      'createAt': createAt,
      'updateAt': updateAt,
    };
  }
}

/// Single vote submission row from `POST /api/voting/submit`.
class VotingSubmitItem {
  String? id;
  String? userId;
  String? createAt;
  String? updateAt;
  String? brandsId;
  String? votingId;
  VotingListingBrand? brand;
  VotingSession? voting;

  VotingSubmitItem({
    this.id,
    this.userId,
    this.createAt,
    this.updateAt,
    this.brandsId,
    this.votingId,
    this.brand,
    this.voting,
  });

  VotingSubmitItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    userId = json['userId'] as String?;
    createAt = json['createAt'] as String?;
    updateAt = json['updateAt'] as String?;
    brandsId = json['brandsId'] as String?;
    votingId = json['votingId'] as String?;
    final b = json['brand'];
    if (b is Map<String, dynamic>) {
      brand = VotingListingBrand.fromJson(b);
    }
    final v = json['voting'];
    if (v is Map<String, dynamic>) {
      voting = VotingSession.fromJson(v);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createAt': createAt,
      'updateAt': updateAt,
      'brandsId': brandsId,
      'votingId': votingId,
      if (brand != null) 'brand': brand!.toJson(),
      if (voting != null) 'voting': voting!.toJson(),
    };
  }
}

/// `POST /api/voting/submit` envelope (`item` is a [VotingSubmitItem]).
class VotingSubmitResponse {
  bool? success;
  VotingSubmitItem? item;

  VotingSubmitResponse({this.success, this.item});

  VotingSubmitResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    final raw = json['item'];
    if (raw is Map<String, dynamic>) {
      item = VotingSubmitItem.fromJson(raw);
    }
  }

  Map<String, dynamic> toJson() {
    return {'success': success, if (item != null) 'item': item!.toJson()};
  }
}
