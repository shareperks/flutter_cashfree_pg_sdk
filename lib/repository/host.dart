class Host {
  static String baseUrl = 'https://api.starvest.com';
  static String authUrl = 'https://auth.shareperks.in';
  // static String authUrl = 'http://127.0.0.1:3004';

  static String listingUrl = 'https://listing.shareperks.in';
  // static String listingUrl = 'http://127.0.0.1:3004';
  static String brokerUrl = 'https://broker.shareperks.in';
  static String submitApi = 'https://from-api.shareperks.in';
  static String holdingApi = "https://holding-api.shareperks.in";

  /// Payout / withdraw API (`POST /payout/request`). Point to your service (e.g. `http://127.0.0.1:3004` for local).
  static String payoutUrl = 'https://listing.shareperks.in';

  /// Gmail coupon scrape service (connect Google, list email coupons).
  static String linkAccountUrl = 'https://link-account.shareperks.in';

  /// Finance / Screener API — shareholder perks, company profile, image proxy.
  /// Endpoints live under `/api/...` (see docs). Mobile apps load perk images
  /// directly from `backend-api.shareperks.in`, so this base is only used for
  /// the JSON endpoints.
  static String financeApi = 'https://finance.shareperks.in';
}
