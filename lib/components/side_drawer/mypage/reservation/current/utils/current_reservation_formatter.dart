import 'package:flutter/material.dart';
import '../models/current_reservation_model.dart';

/// 예약 관련 유틸리티 함수를 제공하는 클래스
class ReservationFormatter {
  /// 요일 텍스트 반환
  static String getDayOfWeek(int day) {
    switch (day) {
      case 1: return '월';
      case 2: return '화';
      case 3: return '수';
      case 4: return '목';
      case 5: return '금';
      case 6: return '토';
      case 7: return '일';
      default: return '';
    }
  }

  /// 날짜를 읽기 쉬운 형식으로 포맷팅
  static String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일(${getDayOfWeek(date.weekday)})';
  }

  /// 남은 시간을 읽기 쉬운 형식으로 포맷팅
  static String formatRemainingTime(Duration remainingTime) {
    if (remainingTime.inDays > 0) {
      return '${remainingTime.inDays}일 ${remainingTime.inHours % 24}시간 남음';
    } else if (remainingTime.inHours > 0) {
      return '${remainingTime.inHours}시간 ${remainingTime.inMinutes % 60}분 남음';
    } else if (remainingTime.inMinutes > 0) {
      return '${remainingTime.inMinutes}분 남음';
    } else {
      return '곧 시작';
    }
  }

  /// 경과 시간을 읽기 쉬운 형식으로 포맷팅
  static String formatElapsedTime(Duration elapsedTime) {
    if (elapsedTime.inHours > 0) {
      return '${elapsedTime.inHours}시간 ${elapsedTime.inMinutes % 60}분 진행중';
    } else {
      return '${elapsedTime.inMinutes}분 진행중';
    }
  }

  /// 예약 종료 시간 계산
  static DateTime calculateReservationEndTime(String useDate, String useTime, int useDuration) {
    try {
      final dateParts = useDate.split('-');
      final timeParts = useTime.split(':');

      if (dateParts.length == 3 && timeParts.length == 2) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final startTime = DateTime(year, month, day, hour, minute);
        final endTime = startTime.add(Duration(hours: useDuration));

        return endTime;
      }
    } catch (e) {
      print('예약 종료 시간 계산 오류: $e');
    }

    return DateTime.now();
  }

  /// 시간 표시 텍스트 가져오기 - 상태와 상관없이 남은 시간 또는 진행 중인 시간만 표시
  static String getTimeDisplayText(Reservation reservation) {
    // 항상 시작 시간과 종료 시간을 기준으로 시간 정보 표시
    final startTime = reservation.reservationStartTime;
    final endTime = reservation.reservationEndTime;

    if (startTime == null || endTime == null) {
      return '';
    }

    final now = DateTime.now();

    // 시작 전
    if (now.isBefore(startTime)) {
      final remainingTime = startTime.difference(now);
      return formatRemainingTime(remainingTime);
    }

    // 진행 중
    if (now.isAfter(startTime) && now.isBefore(endTime)) {
      final elapsedTime = now.difference(startTime);
      return formatElapsedTime(elapsedTime);
    }

    // 종료됨 - 아무것도 표시하지 않음
    return '';
  }

  /// 시간 상태 태그 배경색 가져오기
  static Color getTimeTagBackgroundColor(String statusCode, String timeText) {
    // 진행 중인 경우 (XX분 진행중)
    if (timeText.contains('진행중')) {
      return const Color(0xFFE6F7EF); // 초록색 배경
    }

    // 남은 시간 표시인 경우 (XX분 남음)
    if (timeText.contains('남음')) {
      return const Color(0xFFFFEEEE); // 빨간색 배경
    }

    return const Color(0xFFF5F5F5); // 기본 회색 배경
  }

  /// 시간 상태 태그 텍스트색 가져오기
  static Color getTimeTagTextColor(String statusCode, String timeText) {
    // 진행 중인 경우
    if (timeText.contains('진행중')) {
      return Colors.green; // 초록색 텍스트
    }

    // 남은 시간 표시인 경우
    if (timeText.contains('남음')) {
      return Colors.red; // 빨간색 텍스트
    }

    return Colors.grey; // 기본 회색 텍스트
  }

  /// 숫자 포맷팅 함수
  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

/// UI 관련 상수값을 정의하는 클래스
class AppColors {
  // 주요 색상
  static const Color primary = Color(0xFF237AFF);
  static const Color background = Colors.white;
  static const Color cardShadow = Color(0x0D000000); // 5% 투명도
  static const Color divider = Color(0xFFEEEEEE);

  // 텍스트 색상
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF333333);
  static const Color textLight = Color(0xFF666666);

  // 배경 색상
  static const Color backgroundLight = Color(0xFFF9F9F9);
  static const Color tagBackground = Color(0xFFEEF4FF);
}

/// 스타일 관련 상수값을 정의하는 클래스
class AppStyles {
  // 텍스트 스타일
  static const TextStyle heading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textMedium,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    color: AppColors.textLight,
    fontWeight: FontWeight.w500,
  );

  // 버튼 스타일
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: AppColors.primary,
    minimumSize: const Size(double.infinity, 48),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // 카드 장식
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final BoxDecoration infoRowDecoration = BoxDecoration(
    color: AppColors.backgroundLight,
    borderRadius: BorderRadius.circular(8),
  );
}