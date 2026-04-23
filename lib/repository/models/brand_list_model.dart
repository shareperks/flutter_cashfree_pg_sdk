import 'home_common_models.dart';

class BrandListResponse {
  bool? success;
  List<BrandItem>? data;

  BrandListResponse({this.success, this.data});

  BrandListResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    if (json['data'] != null) {
      data = <BrandItem>[];
      for (final v in json['data'] as List<dynamic>) {
        data!.add(BrandItem.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (data != null) 'data': data!.map((v) => v.toJson()).toList(),
    };
  }
}

