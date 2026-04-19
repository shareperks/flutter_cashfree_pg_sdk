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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['email'] = this.email;
    data['name'] = this.name;
    data['mobile'] = this.mobile;
    data['isActive'] = this.isActive;
    data['referCode'] = this.referCode;
    data['dob'] = this.dob;
    data['image'] = this.image;
    data['createAt'] = this.createAt;
    data['updateAt'] = this.updateAt;
    data['walletId'] = this.walletId;
    data['holdingImportsId'] = this.holdingImportsId;
    data['allowedSettingsId'] = this.allowedSettingsId;
    data['notificationId'] = this.notificationId;
    return data;
  }
}
