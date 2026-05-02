/// `GET /reward/content/:id` — terms short text + full HTML for reward detail / legal screens.
class RewardContent {
  RewardContent({
    this.id,
    this.termsAndConditionsSort,
    this.termsAndConditionsFull,
    this.createAt,
    this.updateAt,
  });

  final String? id;

  /// Plain / sort preview (e.g. numbered lines with `\n`).
  final String? termsAndConditionsSort;

  /// Full terms as HTML (e.g. for `flutter_html` or WebView).
  final String? termsAndConditionsFull;

  final String? createAt;
  final String? updateAt;

  factory RewardContent.fromJson(Map<String, dynamic> json) {
    return RewardContent(
      id: json['id'] as String?,
      termsAndConditionsSort: json['termsAndConditionsSort'] as String?,
      termsAndConditionsFull: json['termsAndConditionsFull'] as String?,
      createAt: json['createAt'] as String?,
      updateAt: json['updateAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'termsAndConditionsSort': termsAndConditionsSort,
        'termsAndConditionsFull': termsAndConditionsFull,
        'createAt': createAt,
        'updateAt': updateAt,
      };
}
