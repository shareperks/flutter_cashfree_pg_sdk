/// DTO for `GET /cashback/tracking-link?offerId=<benefitId>`.
///
/// The endpoint resolves the benefit's campaign source (cuelinks / admitad)
/// and mints a click-attributed affiliate URL we hand to the OS browser.
///
/// Response shape (flat — not envelope-wrapped):
///
///     { "success": true, "link": "https://...", "provider": "cuelinks" }
///
/// Error shape (4xx / 5xx):
///
///     { "success": false, "error": "not_found", "message": "..." }
class CashbackTrackingLink {
  CashbackTrackingLink({required this.link, this.provider});

  /// Affiliate / shortened URL the user should be redirected to.
  final String link;

  /// `"cuelinks"` or `"admitad"`. Surfaced for analytics / logging only;
  /// the user-facing flow doesn't branch on it.
  final String? provider;

  factory CashbackTrackingLink.fromJson(Map<String, dynamic> json) =>
      CashbackTrackingLink(
        link: json['link'] as String,
        provider: json['provider'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'link': link,
    if (provider != null) 'provider': provider,
  };
}
