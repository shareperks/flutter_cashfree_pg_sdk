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

  String formatInr(num value) {
    final negative = value < 0;
    String digits = value.abs().toString();

    // Handle decimal values
    String decimalPart = '';
    if (digits.contains('.')) {
      final parts = digits.split('.');
      digits = parts[0];
      decimalPart = '.${parts[1]}';
    }

    if (digits.length <= 3) {
      return '${negative ? '-' : ''}$digits$decimalPart';
    }

    final lastThree = digits.substring(digits.length - 3);
    String remaining = digits.substring(0, digits.length - 3);

    final buffer = StringBuffer();

    while (remaining.length > 2) {
      buffer.write('${remaining.substring(remaining.length - 2)},');
      remaining = remaining.substring(0, remaining.length - 2);
    }

    if (remaining.isNotEmpty) {
      buffer.write('$remaining,');
    }

    final formatted = '${buffer.toString()}$lastThree';

    return '${negative ? '-' : ''}$formatted$decimalPart';
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
