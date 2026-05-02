/// Auth API `/api/settings` — notification & perk preference toggles.
class UserSettings {
  UserSettings({
    this.id,
    this.notifications,
    this.perksUpdates,
    this.walletUpdates,
    this.createAt,
    this.updateAt,
  });

  final String? id;
  final bool? notifications;
  final bool? perksUpdates;
  final bool? walletUpdates;

  /// Present on PUT responses.
  final String? createAt;

  /// Present on PUT responses.
  final String? updateAt;

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String?,
      notifications: json['notifications'] as bool?,
      perksUpdates: json['perksUpdates'] as bool?,
      walletUpdates: json['walletUpdates'] as bool?,
      createAt: json['createAt'] as String?,
      updateAt: json['updateAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (notifications != null) 'notifications': notifications,
        if (perksUpdates != null) 'perksUpdates': perksUpdates,
        if (walletUpdates != null) 'walletUpdates': walletUpdates,
        if (createAt != null) 'createAt': createAt,
        if (updateAt != null) 'updateAt': updateAt,
      };
}

/// Body for `PUT /api/settings` — include only fields you want to change.
class UserSettingsUpdate {
  UserSettingsUpdate({
    this.notifications,
    this.perksUpdates,
    this.walletUpdates,
  });

  final bool? notifications;
  final bool? perksUpdates;
  final bool? walletUpdates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (notifications != null) 'notifications': notifications,
      if (perksUpdates != null) 'perksUpdates': perksUpdates,
      if (walletUpdates != null) 'walletUpdates': walletUpdates,
    };
  }

  /// Sends all three flags (matches typical client payloads).
  factory UserSettingsUpdate.all({
    required bool notifications,
    required bool perksUpdates,
    required bool walletUpdates,
  }) {
    return UserSettingsUpdate(
      notifications: notifications,
      perksUpdates: perksUpdates,
      walletUpdates: walletUpdates,
    );
  }
}
