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
                  color: const Color(0xFF353535),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              )
            ),
            const SizedBox(height: 16),

            // 프렌즈 활동비는 어떻게 정해져요! (왼쪽 정렬)
            const Text(
              '프렌즈 활동비는 이렇게 정해져요!',
              style: TextStyle(
                color: const Color(0xFF353535),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.20,
              ),
            ),
            const SizedBox(height: 8),

            // 안내 텍스트 (왼쪽 정렬)
            const Text(
              '프렌즈 활동비는 아래 기준에 따라 자동 계산됩니다.\n예약 전 아래 내용을 꼭 확인해주세요!',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.50,
              ),
            ),
            const SizedBox(height: 20),

            // 현장결제 구조 (왼쪽 정렬)
            const Text(
              '현장결제 구조',
              style: TextStyle(
                color: const Color(0xFF353535),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.20,
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
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Text(
                    '1시간 기준 (앱에 표시된 금액 기준)',
                    style: TextStyle(
                      color: const Color(0xFF4E5968),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Text(
                    '1시간 초과 시,\n10분당 금액의 추가 요금 발생',
                    style: TextStyle(
                      color: const Color(0xFF4E5968),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '프렌즈 이용 종료 후,\n이용한 시간만큼 앱에서 자동으로\n10분 단위로 계산된 비용을 확인한 후,\n현장에서 프렌즈에게\n',
                          style: TextStyle(
                            color: const Color(0xFF4E5968),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: '현금으로 직접 지급',
                          style: TextStyle(
                            color: const Color(0xFFFF3E6C),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFFF3E6C), // 밑줄 색상 (선택사항)
                          ),
                        ),
                        TextSpan(
                          text: ' 해주세요.',
                          style: TextStyle(
                            color: const Color(0xFF4E5968),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            height: 1.50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 안내 메시지 (왼쪽 정렬)
            const Text(
              '※ 카드 결제 및 이체는 지원되지 않으며,\n 반드시 현금으로 지급해주셔야 합니다.',
              style: TextStyle(
                color: const Color(0xFFFF3E6C),
                fontSize: 14,
                fontWeight: FontWeight.w600,
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