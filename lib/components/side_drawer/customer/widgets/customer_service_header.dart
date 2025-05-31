import 'package:flutter/material.dart';

class CustomerServiceHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF3182F6), size: 20),
              SizedBox(width: 8),
              Text(
                '문의하기 전에 확인해주세요',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3182F6),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• 자주 묻는 질문(FAQ)를 먼저 확인해주세요\n'
                '• 문의 답변은 평일 기준 1-2일 내에 이메일로 발송됩니다\n'
                '• 긴급한 문의는 카카오톡 채널을 이용해주세요',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}