/// Response DTO for `GET /profile` and `PATCH /profile` from the
/// data_service `src/services/profile/` route.
class Profile {
  Profile({
    this.id,
    this.name,
    this.email,
    this.mobile,
    this.dob,
    this.image,
    this.referCode,
    this.isActive,
    this.isProfileComplete,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? mobile;

  /// ISO 8601 date-time, e.g. `1998-04-12T00:00:00.000Z`.
  final String? dob;
  final String? image;
  final String? referCode;
  final bool? isActive;
  final bool? isProfileComplete;
  final String? createdAt;
  final String? updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      dob: json['dob'] as String?,
      image: json['image'] as String?,
      referCode: json['referCode'] as String?,
      isActive: json['isActive'] as bool?,
      isProfileComplete: json['isProfileComplete'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

/// Body for `PATCH /profile`. Send only the fields you want to change.
/// Server requires at least one field present.
class ProfileUpdate {
  ProfileUpdate({
    this.name,
    this.email,
    this.mobile,
    this.dob,
    this.image,
  });

  final String? name;
  final String? email;

  /// 10-digit Indian mobile. The server also accepts `+91` / `91` / `0`
  /// prefixed forms and normalizes them.
  final String? mobile;

  /// ISO date string, e.g. `1998-04-12` or full ISO 8601.
  final String? dob;
  final String? image;

  bool get isEmpty =>
      name == null &&
      email == null &&
      mobile == null &&
      dob == null &&
      image == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (name != null) 'name': name,
    if (email != null) 'email': email,
    if (mobile != null) 'mobile': mobile,
    if (dob != null) 'dob': dob,
    if (image != null) 'image': image,
  };
}

/// Wrapper for the standard `{ success, data }` envelope returned by the
/// data_service profile routes.
class ProfileEnvelope {
  ProfileEnvelope({required this.success, this.data, this.message});

  final bool success;
  final Profile? data;
  final String? message;

  factory ProfileEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    return ProfileEnvelope(
      success: json['success'] as bool? ?? false,
      data: raw is Map<String, dynamic> ? Profile.fromJson(raw) : null,
      message: json['message'] as String?,
    );
  }
}
