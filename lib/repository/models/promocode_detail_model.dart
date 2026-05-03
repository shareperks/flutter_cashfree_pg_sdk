import 'cashback_detail_model.dart';

/// `GET /rewards/promocode/:id`
///
/// Same envelope as cashback detail ([CashbackDetailResponse]) plus optional
/// [PromocodeChimed] on [CashbackDetailData.chimed].
typedef PromocodeDetailResponse = CashbackDetailResponse;
typedef PromocodeDetailData = CashbackDetailData;
