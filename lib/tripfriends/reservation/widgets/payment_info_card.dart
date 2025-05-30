import 'package:flutter/material.dart';

class PaymentInfoCard extends StatelessWidget {
  final String title;
  final String? subtitle; // 인원수 표시를 위한 subtitle 추가
  final IconData iconData;
  final Color iconBgColor;
  final Color iconColor;
  final String currencySymbol;
  final int currentAmount;
  final String Function(int) formatCurrency;

  const PaymentInfoCard({
    super.key,
    required this.title,
    this.subtitle, // 선택적 파라미터
    required this.iconData,
    required this.iconBgColor,
    required this.iconColor,
    this.currencySymbol = '₩',
    required this.currentAmount,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 영역: 타이틀만 표시 (아이콘 제거)
          subtitle != null
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬 유지
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
              // 서브타이틀 텍스트만 정렬 속성 추가
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10), // 패딩으로 위치 조정
                child: Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center, // 텍스트 자체를 가운데 정렬
                ),
              ),
            ],
          )
              : Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),

          // 오른쪽 영역: 금액 표시
          Text(
            '$currencySymbol ${formatCurrency(currentAmount)}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF353535),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}