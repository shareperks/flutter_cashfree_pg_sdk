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

  /// Company data service (Screener-style company details, financials, peers).
  /// Base already includes the `/api/v1` prefix.
  ///
  /// Pointed at the service running locally on port 4003.
  static String companyDataApi = 'http://localhost:4003/api/v1';
  // static String companyDataApi = 'http://10.0.2.2:4003/api/v1'; // Android emulator
  // static String companyDataApi = 'http://192.168.1.4:4003/api/v1'; // physical device
  // static String companyDataApi = 'https://company-api.shareperks.in/api/v1'; // deployed
}
