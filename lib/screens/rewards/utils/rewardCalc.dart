import 'package:shareperks/repository/models/giftcard_detail_model.dart';

class GiftCardCalcCalcData {
  final double amount;
  final double discountedAmount;
  final double percent;

  const GiftCardCalcCalcData({
    required this.amount,
    required this.discountedAmount,
    required this.percent,
  });

  /// Face value minus discounted price (savings in ₹).
  double get savings => amount - discountedAmount;

  bool get hasDiscount => percent > 0 && savings > 0;

  String formatInr(double value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    if (digits.length <= 3) {
      return negative ? '-$digits' : digits;
    }
    final buffer = StringBuffer();
    final firstGroup = digits.length % 3;
    if (firstGroup == 0) {
      buffer.write(digits.substring(0, 3));
      var index = 3;
      while (index < digits.length) {
        buffer.write(',${digits.substring(index, index + 3)}');
        index += 3;
      }
    } else {
      buffer.write(digits.substring(0, firstGroup));
      var index = firstGroup;
      while (index < digits.length) {
        buffer.write(',${digits.substring(index, index + 3)}');
        index += 3;
      }
    }
    return negative ? '-${buffer.toString()}' : buffer.toString();
  }

  String get formattedFaceValue => '₹ ${formatInr(amount)}';

  String get formattedPayable => '₹ ${formatInr(discountedAmount)}';

  String get formattedPercentOff => '$percent% Off';
}

class GiftCardCalc {
  GiftCardCalc(this.data, {required this.isEligible});

  final GiftcardDetailData data;
  final bool isEligible;

  num get rewardRatePercent {
    final rate = isEligible
        ? data.eligibility?.withHolderRewardRate
        : data.eligibility?.nonHolderRewardRate;
    return (rate ?? 0).clamp(0, 100);
  }

  /// Applies shareholder / non-shareholder [rewardRatePercent] to [amount].
  GiftCardCalcCalcData calc(double amount) {
    if (amount <= 0) {
      return const GiftCardCalcCalcData(
        amount: 0,
        discountedAmount: 0,
        percent: 0,
      );
    }

    final percent = rewardRatePercent;
    final discountedAmount = ((amount * (100 - percent)) / 100).round();

    return GiftCardCalcCalcData(
      amount: amount,
      discountedAmount: discountedAmount.toDouble(),
      percent: percent.toDouble(),
    );
  }
}
