import 'package:flutter/material.dart';

class FriendsNoticeItem extends StatelessWidget {
  const FriendsNoticeItem({super.key});

  @override
  Widget build(BuildContext context) {
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

          // 예약금
          _buildNoticeItem(
            icon: Icons.payment_rounded,
            title: '예약금',
            content: '트립조이 앱 내에서 결제됩니다.',
          ),

          const SizedBox(height: 12),

          // 현장결제
          _buildNoticeItem(
            icon: Icons.account_balance_wallet_outlined,
            title: '현장결제',
            content: '트립프렌즈에게 직접 지불합니다.',
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    // 모든 아이템에 동일한 색상 적용
    const Color iconBgColor = Color(0xFFEBEFFF);
    const Color iconColor = Color(0xFF6979F8);
    const Color titleColor = Color(0xFF5462FF);

    // 글자 간격 조정 - 3글자인 경우만 letterSpacing 적용
    final double letterSpacing = title.length == 3 ? 4.0 : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 원형 아이콘
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),

        const SizedBox(width: 8),

        // 제목 (letter spacing 적용)
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: titleColor,
            letterSpacing: letterSpacing,
          ),
        ),

        const SizedBox(width: 8),

        // 구분선
        const Text(
          ' | ',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFFDDDDDD),
          ),
        ),

        const SizedBox(width: 8),

        // 내용
        Expanded(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5362FF),
            ),
          ),
        ),
      ],
    );
  }
}