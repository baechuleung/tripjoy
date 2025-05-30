import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// 날짜, 시간, 금액 등의 형식을 변환하는 유틸리티 클래스
class FormatterUtils {
  // 날짜 형식 변환 (Timestamp -> String)
  static String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return '-';

    DateTime dateTime;

    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      try {
        // yyyy-MM-dd 형식을 파싱
        final parts = timestamp.split('-');
        if (parts.length >= 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2].split(' ')[0]);
          dateTime = DateTime(year, month, day);
        } else {
          return timestamp;
        }
      } catch (e) {
        return timestamp; // 파싱 실패 시 원본 문자열 반환
      }
    } else {
      return '-'; // 지원하지 않는 유형
    }

    // 데이터베이스 저장용 포맷: yyyy-MM-dd
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }

  // UI 표시용 날짜 형식 변환 (Timestamp -> String)
  static String formatDateTimeForDisplay(dynamic timestamp) {
    if (timestamp == null) return '-';

    DateTime dateTime;

    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      try {
        // yyyy-MM-dd 형식을 파싱
        final parts = timestamp.split('-');
        if (parts.length >= 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2].split(' ')[0]);
          dateTime = DateTime(year, month, day);
        } else {
          return timestamp;
        }
      } catch (e) {
        return timestamp; // 파싱 실패 시 원본 문자열 반환
      }
    } else {
      return '-'; // 지원하지 않는 유형
    }

    // UI 표시용 포맷: yyyy년 MM월 dd일
    final formatter = DateFormat('yyyy년 MM월 dd일');
    return formatter.format(dateTime);
  }

  // 숫자에 천 단위 쉼표 추가
  static String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    );
  }

  // 시간 형식 변환 (24시간제 -> 12시간제)
  static String formatTime(String time24) {
    if (time24.isEmpty) return '-';

    try {
      // 24시간제 시간 형식을 파싱 (14:30)
      final parts = time24.split(':');
      if (parts.length < 2) return time24;

      int hour = int.parse(parts[0]);
      final minute = parts[1];

      final period = hour < 12 ? 'AM' : 'PM';
      hour = hour % 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $period';
    } catch (e) {
      return time24; // 파싱 실패 시 원본 반환
    }
  }
}