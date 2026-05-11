import 'home_common_models.dart';

/// One row from `GET /referral/all` (root JSON array).
class ReferralListEntry {
  ReferralListEntry({
    this.id,
    this.name,
    this.image,
    this.date,
    this.dateFormatted,
    this.status,
    this.pendingStep,
  });

  final String? id;
  final String? name;
  final String? image;

  /// ISO date string from API.
  final String? date;

  /// Human-readable date for display.
  final String? dateFormatted;

  /// e.g. `Demat linked`.
  final String? status;

  /// Steps remaining in onboarding (when applicable).
  final int? pendingStep;

  factory ReferralListEntry.fromJson(Map<String, dynamic> json) {
    return ReferralListEntry(
      id: json['id'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      date: json['date'] as String?,
      dateFormatted: json['dateFormatted'] as String?,
      status: json['status'] as String?,
      pendingStep: parseJsonInt(json['pendingStep']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'date': date,
        'dateFormatted': dateFormatted,
        'status': status,
        'pendingStep': pendingStep,
      };

  /// Parses the API root when it is a JSON array of referral objects.
  static List<ReferralListEntry> listFromJson(dynamic json) {
    if (json is! List) return <ReferralListEntry>[];
    return json
        .whereType<Map>()
        .map((e) => ReferralListEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
