import 'home_common_models.dart';

class RewardListResponse {
  bool? success;
  List<RewardItem>? data;

  RewardListResponse({this.success, this.data});

  RewardListResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    if (json['data'] != null) {
      data = <RewardItem>[];
      for (final v in json['data'] as List<dynamic>) {
        data!.add(RewardItem.fromJson(v as Map<String, dynamic>));
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

