import 'package:flutter/material.dart';
import '../../models/past_reservation_model.dart';

/// 이용 완료 금액 정보를 표시하는 위젯
class PastReservationPriceWidget extends StatelessWidget {
  final PastReservationModel reservation;

  const PastReservationPriceWidget({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // completionInfo에서 데이터 가져오기
    final Map<String, dynamic>? completionInfo = reservation.originalData['completionInfo'] as Map<String, dynamic>?;

    // finalPrice와 finalUsedTime 가져오기
    final int totalPrice = completionInfo != null
        ? (completionInfo['finalPrice'] ?? reservation.originalData['totalPrice'] ?? 0)
        : (reservation.originalData['totalPrice'] ?? 0);

    // 이용 시간 정보
    final String usedTime = completionInfo != null
        ? (completionInfo['finalUsedTime'] ?? '${reservation.useDuration}시간')
        : (reservation.originalData['usedTime'] ?? '${reservation.useDuration}시간');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이용완료금액',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${reservation.originalData['currencySymbol'] ?? ''} ${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E5968), // 회색 계열로 변경
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF9AA4B2), // 더 어두운 회색으로 변경
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                usedTime,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}