import 'package:flutter/material.dart';
import '../current//utils/current_reservation_formatter.dart';

class CompletionConfirmationPopup extends StatelessWidget {
  final int totalPrice;
  final String usedTime;
  final String currencySymbol;

  const CompletionConfirmationPopup({
    Key? key,
    required this.totalPrice,
    required this.usedTime,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.white, // 배경색 흰색으로 설정
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 제목
            Text(
              '프렌즈 이용종료',
              style: TextStyle(
                color: const Color(0xFF353535),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 16),

            // 설명 텍스트 - 요구사항에 맞게 변경
            Text(
              '프렌즈 이용종료 후,\n총 이용요금을 카드 결제 및 계좌 이체가 아닌\n현금으로 지불해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF0059B7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 20),

            // 구분선
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[300],
            ),

            SizedBox(height: 20),

            // 이용 요금 - 여기서 currencySymbol 사용
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '이용요금',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$currencySymbol ${ReservationFormatter.formatCurrency(totalPrice)}',
                  style: TextStyle(
                    color: const Color(0xFF0059B7),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // 이용 시간
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '이용시간',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  usedTime,
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // 버튼 영역
            Row(
              children: [
                // 취소 버튼
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // 취소
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // 확인 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // 확인
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3182F6), // 파란색 버튼
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}