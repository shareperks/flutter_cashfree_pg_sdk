import 'home_common_models.dart';

/// One FAQ row from listing `/informations/faqs` (or equivalent).
class InformationFaq {
  InformationFaq({
    this.id,
    this.type,
    this.question,
    this.answer,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? type;

  /// Maps JSON key `qus`.
  final String? question;
  final String? answer;
  final String? createdAt;
  final String? updatedAt;

  factory InformationFaq.fromJson(Map<String, dynamic> json) {
    return InformationFaq(
      id: json['id'] as String?,
      type: json['type'] as String?,
      question: json['qus'] as String?,
      answer: json['answer'] as String?,
      createdAt: json['createAt'] as String?,
      updatedAt: json['updateAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'qus': question,
        'answer': answer,
        'createAt': createdAt,
        'updateAt': updatedAt,
      };
}

/// Paginated FAQ list: `{ success, items, page, limit, total, totalPages }`.
class InformationFaqListResponse {
  InformationFaqListResponse({
    this.success,
    this.items,
    this.page,
    this.limit,
    this.total,
    this.totalPages,
  });

  final bool? success;
  final List<InformationFaq>? items;
  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;

  factory InformationFaqListResponse.fromJson(Map<String, dynamic> json) {
    List<InformationFaq>? list;
    final raw = json['items'];
    if (raw is List<dynamic>) {
      list = raw
          .map((e) => InformationFaq.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return InformationFaqListResponse(
      success: json['success'] as bool?,
      items: list,
      page: parseJsonInt(json['page']),
      limit: parseJsonInt(json['limit']),
      total: parseJsonInt(json['total']),
      totalPages: parseJsonInt(json['totalPages']),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        if (items != null)
          'items': items!.map((e) => e.toJson()).toList(),
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': totalPages,
      };
}
