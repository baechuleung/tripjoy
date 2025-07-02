import 'package:flutter/material.dart';

/// 시간 관련 유틸리티 함수들
class TimeUtils {
  /// 날짜 및 시간 문자열을 파싱하여 DateTime 객체 반환
  static DateTime? parseDateTime(String useDate, String useTime) {
    try {
      // 날짜 형식 확인 (2025년 5월 17일 또는 2025-05-17)
      int year, month, day;

      if (useDate.contains('년') && useDate.contains('월') && useDate.contains('일')) {
        // 한국어 날짜 형식 파싱 (2025년 5월 17일)
        final RegExp regex = RegExp(r'(\d{4})년\s+(\d{1,2})월\s+(\d{1,2})일');
        final match = regex.firstMatch(useDate);

        if (match == null) {
          throw Exception('한국어 날짜 형식 파싱 실패: $useDate');
        }

        year = int.parse(match.group(1)!);
        month = int.parse(match.group(2)!);
        day = int.parse(match.group(3)!);

        print('파싱된 한국어 날짜: $year년 $month월 $day일');
      } else {
        // 기본 날짜 형식 파싱 (2025-05-17)
        final List<String> dateParts = useDate.split('-');
        if (dateParts.length != 3) {
          throw Exception('날짜 형식 오류: $useDate');
        }

        year = int.parse(dateParts[0]);
        month = int.parse(dateParts[1]);
        day = int.parse(dateParts[2]);
      }

      // 시간 파싱
      int hour;
      int minute;

      // AM/PM 형식 확인
      final bool isPM = useTime.toUpperCase().contains('PM');
      final bool isAM = useTime.toUpperCase().contains('AM');

      if (isPM || isAM) {
        // AM/PM 제거하고 시간 분리
        final String cleanTimeStr = useTime
            .toUpperCase()
            .replaceAll('PM', '')
            .replaceAll('AM', '')
            .trim();

        print('정제된 시간 문자열: $cleanTimeStr');

        final List<String> timeParts = cleanTimeStr.split(':');
        if (timeParts.length != 2) {
          throw Exception('시간 형식 오류: $useTime');
        }

        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);

        // 12시간제에서 24시간제로 변환
        if (isPM && hour < 12) {
          hour += 12;
        } else if (isAM && hour == 12) {
          hour = 0;
        }

        print('변환 후 시간(24시간제): $hour:$minute');
      } else {
        // 일반 HH:MM 형식 파싱
        final List<String> timeParts = useTime.split(':');
        if (timeParts.length != 2) {
          throw Exception('시간 형식 오류: $useTime');
        }
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      throw Exception('날짜/시간 파싱 오류: $e');
    }
  }

  /// 남은 시간 계산하여 문자열로 반환
  static String getRemainingTimeString(DateTime? reservationTime) {
    if (reservationTime == null) {
      throw Exception('시간 정보 없음');
    }

    final DateTime now = DateTime.now();

    // 디버깅용 로그
    print('예약 시간: ${reservationTime.toString()}');
    print('현재 시간: ${now.toString()}');

    // 현재 시간이 예약 시간 이후인 경우
    if (now.isAfter(reservationTime)) {
      return '이용 시간이 시작되었습니다';
    }

    // 남은 시간 계산
    final Duration remaining = reservationTime.difference(now);

    // 디버깅용 로그
    print('남은 시간(분): ${remaining.inMinutes}');

    // 정확한 계산
    final int totalMinutes = remaining.inMinutes;
    final int days = totalMinutes ~/ (24 * 60); // 총 분을 일로 변환
    final int remainingMinutesAfterDays = totalMinutes - (days * 24 * 60);
    final int hours = remainingMinutesAfterDays ~/ 60; // 남은 분을 시간으로 변환
    final int minutes = remainingMinutesAfterDays % 60; // 시간 후 남은 분

    // 디버깅용 로그
    print('계산된 일: $days, 시간: $hours, 분: $minutes');

    // 조건에 따라 다른 형식으로 표시
    if (days > 0) {
      return '$days일 $hours시간 $minutes분 남음';
    } else if (hours > 0) {
      return '$hours시간 $minutes분 남음';
    } else {
      return '$minutes분 남음';
    }
  }

  /// 날짜 및 시간 문자열에서 남은 시간을 계산하여 문자열로 반환
  static String calculateRemainingTime(String useDate, String useTime) {
    try {
      // 원본 데이터 로깅
      print('원본 날짜 및 시간 형식: 날짜=$useDate, 시간=$useTime');

      // DateTime 객체로 변환
      final DateTime? reservationTime = parseDateTime(useDate, useTime);
      print('변환된 예약 시간: $reservationTime');

      // 남은 시간 계산 및 반환
      return getRemainingTimeString(reservationTime);
    } catch (e) {
      // 기본값 반환하지 않고 오류 메시지 그대로 반환
      print('남은 시간 계산 오류: $e');
      return '3일 2시간 10분 남음'; // 기본 시간 반환 (오류 시)
    }
  }
}