class UserModel {
  String? id;
  String? email;
  String? name;
  String? mobile;
  bool? isActive;
  String? referCode;
  String? dob;
  String? image;
  String? createAt;
  String? updateAt;
  String? walletId;
  String? holdingImportsId;
  String? allowedSettingsId;
  String? notificationId;

  UserModel({
    this.id,
    this.email,
    this.name,
    this.mobile,
    this.isActive,
    this.referCode,
    this.dob,
    this.image,
    this.createAt,
    this.updateAt,
    this.walletId,
    this.holdingImportsId,
    this.allowedSettingsId,
    this.notificationId,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    name = json['name'];
    mobile = json['mobile'];
    isActive = json['isActive'];
    referCode = json['referCode'];
    dob = json['dob'];
    image = json['image'];
    createAt = json['createAt'];
    updateAt = json['updateAt'];
    walletId = json['walletId'];
    holdingImportsId = json['holdingImportsId'];
    allowedSettingsId = json['allowedSettingsId'];
    notificationId = json['notificationId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['email'] = email;
    data['name'] = name;
    data['mobile'] = mobile;
    data['isActive'] = isActive;
    data['referCode'] = referCode;
    data['dob'] = dob;
    data['image'] = image;
    data['createAt'] = createAt;
    data['updateAt'] = updateAt;
    data['walletId'] = walletId;
    data['holdingImportsId'] = holdingImportsId;
    data['allowedSettingsId'] = allowedSettingsId;
    data['notificationId'] = notificationId;
    return data;
  }
}
