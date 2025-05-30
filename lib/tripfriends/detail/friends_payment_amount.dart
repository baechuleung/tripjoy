import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../reservation/widgets/payment_info_popup.dart';
import '../reservation/widgets/payment_info_card.dart';

class FriendsPaymentAmount extends StatelessWidget {
  final Map<String, dynamic> friends;

  const FriendsPaymentAmount({
    super.key,
    required this.friends,
  });

  // 시간당 금액 가져오기
  int _getPricePerHour() {
    return friends['pricePerHour'] ?? '';
  }

  // 10분당 금액 계산 메서드
  int _calculatePricePerTenMinutes() {
    final pricePerHour = _getPricePerHour();
    // 시간당 요금을 6으로 나누어 10분당 금액 계산
    return (pricePerHour / 6).round();
  }

  // 금액 포맷팅
  String _formatCurrency(int amount) {
    final numberFormat = NumberFormat('#,###');
    return numberFormat.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // 현장 결제 금액 계산
    final pricePerHour = _getPricePerHour();
    // 10분당 금액 계산
    final pricePerTenMinutes = _calculatePricePerTenMinutes();
    // 통화 기호
    final currencySymbol = friends['currencySymbol'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '현장 결제 금액',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              // 안내 텍스트와 아이콘 추가
              GestureDetector(
                onTap: () {
                  // 팝업창 표시
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.5),
                    builder: (BuildContext context) {
                      return const PaymentInfoPopup();
                    },
                  );
                },
                child: Row(
                  children: [
                    const Text(
                      '현장 결제 금액 안내',
                      style: TextStyle(
                        color: Color(0xFFFF3E6C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Color(0xFFFF3E6C),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 구분선 추가
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 0),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFEEEEEE),
            ),
          ),
          const SizedBox(height: 20),

          // 기본요금/1시간 카드
          PaymentInfoCard(
            title: '기본요금/1시간',
            iconData: Icons.account_balance_wallet,
            iconBgColor: const Color(0xFFFFEDED),
            iconColor: const Color(0xFFFF5252),
            currencySymbol: currencySymbol,
            currentAmount: pricePerHour,
            formatCurrency: _formatCurrency,
          ),

          const SizedBox(height: 8),

          // 추가요금/10분당 카드
          PaymentInfoCard(
            title: '추가요금/10분당',
            iconData: Icons.account_balance_wallet,
            iconBgColor: const Color(0xFFFFEDED),
            iconColor: const Color(0xFFFF5252),
            currencySymbol: currencySymbol,
            currentAmount: pricePerTenMinutes,
            formatCurrency: _formatCurrency,
          ),
        ],
      ),
    );
  }
}