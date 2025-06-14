// lib/chat/widgets/chat_warning_notice.dart
import 'package:flutter/material.dart';

class ChatWarningNotice extends StatelessWidget {
  const ChatWarningNotice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF4E5968),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '채팅 시 유의사항',
                style: TextStyle(
                  color: const Color(0xFFFF3E6C),
                  fontSize: 13,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '프렌즈를 외부 채팅 앱 으로 유도할 경우, ',
                  style: TextStyle(
                    color: const Color(0xFF4E5968),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                TextSpan(
                  text: '트립조이 이용이 제한될 수 있습니다.',
                  style: TextStyle(
                    color: const Color(0xFFFF3E6C),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                  ),
                ),
                TextSpan(
                  text: ' 안전한 이용을 위해',
                  style: TextStyle(
                    color: const Color(0xFF4E5968),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: ' 플랫폼 내 채팅을 이용',
                  style: TextStyle(
                    color: const Color(0xFFFF3E6C),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                ),
                TextSpan(
                  text: '해 주세요.',
                  style: TextStyle(
                    color: const Color(0xFF4E5968),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}