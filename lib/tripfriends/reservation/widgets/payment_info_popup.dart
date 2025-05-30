import 'package:flutter/material.dart';

class PaymentInfoPopup extends StatelessWidget {
  const PaymentInfoPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 (중앙 정렬)
            const Center(
              child: Text(
                '프렌즈 현장결제 안내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 프렌즈 활동비는 어떻게 정해져요! (왼쪽 정렬)
            const Text(
              '프렌즈 활동비는 이렇게 정해져요!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),

            // 안내 텍스트 (왼쪽 정렬)
            const Text(
              '프렌즈 활동비는 각 프렌즈가 직접 설정한 금액에 따라 달라집니다.\n예약 전 아래 정보를 꼭 확인해주세요.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 현장결제 구조 (왼쪽 정렬)
            const Text(
              '현장결제 구조',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),

            // 기본요금
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '기본요금 : ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Expanded(
                  child: Text(
                    '프렌즈가 설정한 1시간 기준 이용요금',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 추가요금
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '추가요금 : ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Expanded(
                  child: Text(
                    '1시간 초과 시, 10분당 금액의 추가 요금 발생',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 지급방식
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '지급방식 : ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Expanded(
                  child: Text(
                    '프렌즈 이용 종료 후, 이용한 시간만큼 앱에서 자동으로 10분 단위로 계산된 비용을 확인 후, 현장에서 프렌즈에게 현금으로 직접 지급',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 안내 메시지 (왼쪽 정렬)
            const Text(
              '※ 별도의 카드 결제 및 이체는 지원되지 않으며, 반드시 현금으로 지급해주셔야합니다.',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 20),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF237AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}