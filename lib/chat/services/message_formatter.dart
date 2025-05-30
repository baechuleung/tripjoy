// lib/chat/services/message_formatter.dart - 트립조이 앱(고객용)
import 'package:intl/intl.dart';

class MessageFormatter {
  // 메시지 시간 포맷팅
  static String formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      // 오늘, 시간만 표시
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // 어제
      return '어제 ${DateFormat('HH:mm').format(time)}';
    } else {
      // 다른 날짜
      return DateFormat('MM/dd HH:mm').format(time);
    }
  }

  // 날짜 헤더 텍스트 포맷팅
  static String formatDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '오늘';
    } else if (messageDate == yesterday) {
      return '어제';
    } else {
      return DateFormat('yyyy년 MM월 dd일').format(timestamp);
    }
  }

  // 같은 날짜인지 확인
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}