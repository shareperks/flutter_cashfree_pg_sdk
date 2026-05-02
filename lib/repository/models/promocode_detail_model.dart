import 'cashback_detail_model.dart';

/// `GET /rewards/promocode/:id`
///
/// This payload matches the cashback detail shape (basicInfo/company/brand/category/
/// eligibility/content/relatedPerks), so we reuse the same typed models.
typedef PromocodeDetailResponse = CashbackDetailResponse;
typedef PromocodeDetailData = CashbackDetailData;
