import 'package:flutter/material.dart';
import 'services/reservation_service.dart';
import 'widgets/payment_info_card.dart';
import 'widgets/payment_info_popup.dart';

class PaymentAmountSection extends StatelessWidget {
  final int onSiteAmount;
  final ReservationService reservationService;
  final Map<String, dynamic> reservationData;

  const PaymentAmountSection({
    super.key,
    required this.onSiteAmount,
    required this.reservationService,
    required this.reservationData,
  });

  // 현장 결제 금액 계산 메서드
  int _calculateOnSiteAmount() {
    // reservationData에서 pricePerHour 가져오기
    final pricePerHour = reservationData['pricePerHour'] ?? 0;
    return pricePerHour;
  }

  // 10분당 금액 계산 메서드
  int _calculatePricePerTenMinutes() {
    final pricePerHour = reservationData['pricePerHour'] ?? 0;
    // 시간당 요금을 6으로 나누어 10분당 금액 계산
    return (pricePerHour / 6).round();
  }

  @override
  Widget build(BuildContext context) {
    // 현장 결제 금액 계산
    final calculatedOnSiteAmount = _calculateOnSiteAmount();
    // 10분당 금액 계산
    final pricePerTenMinutes = _calculatePricePerTenMinutes();

    return Container(
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
                  fontWeight: FontWeight.w700,
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
            currencySymbol: reservationData['currencySymbol'] ?? '₩',
            currentAmount: calculatedOnSiteAmount,
            formatCurrency: reservationService.formatCurrency,
          ),

          const SizedBox(height: 8),

          // 추가요금/10분당 카드
          PaymentInfoCard(
            title: '추가요금/10분당',
            iconData: Icons.account_balance_wallet,
            iconBgColor: const Color(0xFFFFEDED),
            iconColor: const Color(0xFFFF5252),
            currencySymbol: reservationData['currencySymbol'] ?? '₩',
            currentAmount: pricePerTenMinutes,
            formatCurrency: reservationService.formatCurrency,
          ),
        ],
      ),
    );
  }
}