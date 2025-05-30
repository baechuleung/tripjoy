// lib/chat/widgets/chat_navigation_bar.dart
import 'package:flutter/material.dart';

class ChatNavigationBar extends StatelessWidget {
  final bool isCheckingReservation;
  final bool isReservationCompleted;
  final VoidCallback onReservationPressed;

  const ChatNavigationBar({
    Key? key,
    required this.isCheckingReservation,
    required this.isReservationCompleted,
    required this.onReservationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: GestureDetector(
        onTap: isCheckingReservation || isReservationCompleted
            ? null
            : onReservationPressed,
        child: Container(
          height: 40,
          width: double.infinity, // 가로 꽉 차게 설정
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: isCheckingReservation || isReservationCompleted
                ? Colors.grey[300] // 로딩 중이거나 예약 완료 시 회색으로 변경
                : const Color(0xFFE8F2FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          child: Center(
            child: Text(
              '예약하기',
              style: TextStyle(
                color: isCheckingReservation || isReservationCompleted
                    ? Colors.grey[600] // 로딩 중이거나 예약 완료 시 글자색 변경
                    : const Color(0xFF3182F6),
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}