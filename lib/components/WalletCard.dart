import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class WalletCard extends StatelessWidget {
  final double amount;
  const WalletCard({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 6),
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: const Color(0x3F5182FE)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                'Wallet Balance',
                style: TextStyle(
                  color: const Color(0xFF5182FE) /* Information */,
                  fontSize: 16,
                  fontFamily: 'Albert Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹ $amount',
                style: TextStyle(
                  color: const Color(0xFF333333),
                  fontSize: 22,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Available to withdraw',
                style: TextStyle(
                  color: SharePerksColors.accent,
                  fontSize: 10,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          Container(
            width: 60,
            height: 60,
            decoration: ShapeDecoration(
              color: const Color(0xFF5283FE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: Icon(
                HugeIconsSolid.wallet01,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionData {
  final double amount;
  final String date;
  final String time;
  final String type;

  TransactionData({
    required this.amount,
    required this.date,
    required this.time,
    required this.type,
  }) {}
}

class TransactionCard extends StatelessWidget {
  final TransactionData data;
  const TransactionCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: SharePerksColors.borderLight),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(0),

        leading: SizedBox(
          width: 10,
          child: Icon(
            data.type == "CREDIT"
                ? HugeIconsSolid.arrowDown02
                : HugeIconsSolid.arrowUp02,
            size: 30,
            color: data.type == "CREDIT" ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          '₹ ${data.amount}',
          style: TextStyle(
            color: const Color(0xFF333333),
            fontSize: 16,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${data.date}',
          style: TextStyle(
            color: const Color(0xFF898989),
            fontSize: 12,
            fontFamily: SharePerksFonts.inter,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.time}',
                style: TextStyle(
                  color: const Color(0xFF898989),
                  fontSize: 12,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
