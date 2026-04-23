class CategoryModel {
  String? id;
  String? name;
  String? image;
  String? type;
  bool? isNew;

  CategoryModel({this.id, this.name, this.image, this.type, this.isNew});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    name = json['name'] as String?;
    image = json['image'] as String?;
    type = json['type'] as String?;
    isNew = json['isNew'] as bool?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'type': type,
      'isNew': isNew,
    };
  }
}

class CategoryListResponse {
  bool? success;
  List<CategoryModel>? data;

  CategoryListResponse({this.success, this.data});

  CategoryListResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    if (json['data'] != null) {
      data = <CategoryModel>[];
      for (final v in json['data'] as List<dynamic>) {
        data!.add(CategoryModel.fromJson(v as Map<String, dynamic>));
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
