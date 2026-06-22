/// Parsed error body for listing/payment APIs (`400`, `401`, `500`, …).
class ApiValidationIssue {
  const ApiValidationIssue({required this.path, required this.message});

  final String path;
  final String message;

  factory ApiValidationIssue.fromJson(Map<String, dynamic> json) {
    final rawPath = json['path'];
    final path = rawPath is List
        ? rawPath.map((e) => e.toString()).join('.')
        : rawPath?.toString() ?? '';
    return ApiValidationIssue(
      path: path,
      message: json['message'] as String? ?? '',
    );
  }
}

class ApiErrorResponse implements Exception {
  const ApiErrorResponse({
    required this.success,
    required this.message,
    this.issues,
  });

  final bool success;
  final String message;
  final List<ApiValidationIssue>? issues;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'] as List<dynamic>?;
    return ApiErrorResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Something went wrong',
      issues: rawIssues
          ?.map((e) => ApiValidationIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// First Zod issue message, else [message].
  String get displayMessage {
    final first = issues?.where((i) => i.message.isNotEmpty).firstOrNull;
    if (first != null) return first.message;
    return message;
  }

  @override
  String toString() => displayMessage;
}
