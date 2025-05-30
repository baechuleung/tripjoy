// lib/components/side_drawer/mypage/reservation/current/models/current_reservation_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 예약 정보를 담는 모델 클래스
class Reservation {
  final String id;
  final String parentId;
  final DateTime? scheduledDateTime;
  final String status;
  final String reservationNumber;
  final int personCount;
  final String startTime;
  final String endTime;
  final int useDuration;
  final DateTime? reservationStartTime;
  final DateTime? reservationEndTime;
  final String? detailRequest;
  final Map<String, dynamic> originalData;

  Reservation({
    this.id = '',
    this.parentId = '',
    this.scheduledDateTime,
    required this.status,
    required this.reservationNumber,
    this.personCount = 1,
    this.startTime = '',
    this.endTime = '',
    required this.useDuration,
    this.reservationStartTime,
    this.reservationEndTime,
    this.detailRequest,
    required this.originalData,
  });

  /// 문서 스냅샷으로부터 Reservation 객체 생성
  factory Reservation.fromSnapshot(DocumentSnapshot doc, String parentId) {
    final data = doc.data() as Map<String, dynamic>;

    // 기본 정보 추출
    final useDate = data['useDate'] as String? ?? '날짜 없음';
    final useTime = data['useTime'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final personCount = data['personCount'] ?? 0;
    final reservationNumber = data['reservationNumber'] ?? '';
    final detailRequest = data['detailRequest'] as String?;
    final useDuration = data['useDuration'] as int? ?? 0;

    // 날짜 및 시간 계산
    final scheduledDateTime = parseDate(useDate);
    final timeRange = calculateTimeRange(useTime, useDuration, scheduledDateTime);

    // 예약 시작시간과 종료시간 계산
    DateTime? reservationStartTime;
    DateTime? reservationEndTime;

    if (useTime.isNotEmpty) {
      try {
        final timeParts = useTime.split(':');
        if (timeParts.length == 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          reservationStartTime = DateTime(
            scheduledDateTime.year,
            scheduledDateTime.month,
            scheduledDateTime.day,
            hour,
            minute,
          );

          reservationEndTime = reservationStartTime.add(Duration(hours: useDuration));
        }
      } catch (e) {
        print('시간 변환 오류: $e');
      }
    }

    return Reservation(
      id: doc.id,
      parentId: parentId,
      scheduledDateTime: scheduledDateTime,
      status: status,
      reservationNumber: reservationNumber,
      personCount: personCount,
      startTime: timeRange['startTime']!,
      endTime: timeRange['endTime']!,
      useDuration: useDuration,
      reservationStartTime: reservationStartTime,
      reservationEndTime: reservationEndTime,
      detailRequest: detailRequest,
      originalData: data,
    );
  }

  /// Map에서 Reservation 객체 생성 (간소화된 버전)
  factory Reservation.fromMap(Map<String, dynamic> data) {
    final String id = data['id'] ?? '';
    final String status = data['status'] ?? 'pending';
    final String reservationNumber = data['reservationNumber'] ?? '';
    final int useDuration = int.tryParse(data['useDuration']?.toString() ?? '0') ?? 0;

    return Reservation(
      id: id,
      status: status,
      reservationNumber: reservationNumber,
      useDuration: useDuration,
      originalData: data,
    );
  }

  /// 남은 시간 계산
  Duration getRemainingTime() {
    if (reservationStartTime == null) {
      return Duration.zero;
    }

    final now = DateTime.now();
    return reservationStartTime!.difference(now);
  }

  /// 경과 시간 계산
  Duration getElapsedTime() {
    if (reservationStartTime == null) {
      return Duration.zero;
    }

    final now = DateTime.now();
    return now.difference(reservationStartTime!);
  }

  /// 현재 시간 기준 상태 체크
  bool get isUpcoming =>
      reservationStartTime != null &&
          DateTime.now().isBefore(reservationStartTime!);

  bool get isInProgress =>
      reservationStartTime != null &&
          reservationEndTime != null &&
          DateTime.now().isAfter(reservationStartTime!) &&
          DateTime.now().isBefore(reservationEndTime!);
}

/// 예약 상태를 정의하는 클래스
class ReservationStatus {
  // 세 가지 주요 상태
  static const String PENDING = 'pending';         // 대기 상태 (예약확정)
  static const String IN_PROGRESS = 'in_progress'; // 서비스 진행 중 상태
  static const String COMPLETED = 'completed';     // 완료 상태

  /// 상태 코드에 대한 라벨 반환
  static String getLabel(String statusCode) {
    switch (statusCode) {
      case PENDING: return '예약확정';
      case IN_PROGRESS: return '진행 중';
      case COMPLETED: return '완료';
      default: return '상태 없음';
    }
  }

  /// 상태 코드에 대한 색상 반환
  static Color getColor(String statusCode) {
    switch (statusCode) {
      case PENDING: return Colors.blue;        // 예약확정 - 파란색
      case IN_PROGRESS: return Colors.green;   // 진행 중 - 초록색
      case COMPLETED: return Colors.purple;    // 완료 - 보라색
      default: return Colors.grey;
    }
  }

  /// 진행 중인 상태인지 확인
  static bool isActive(String statusCode) =>
      statusCode == PENDING ||
          statusCode == IN_PROGRESS;
}

/// 날짜 문자열을 DateTime으로 파싱
DateTime parseDate(String dateStr) {
  try {
    // 한국어 날짜 형식 확인 ("2025년 5월 17일")
    if (dateStr.contains('년') && dateStr.contains('월') && dateStr.contains('일')) {
      print('한국어 날짜 형식 감지: $dateStr');

      // 숫자만 추출
      final RegExp numRegex = RegExp(r'\d+');
      final matches = numRegex.allMatches(dateStr).toList();

      if (matches.length >= 3) {
        final year = int.parse(matches[0].group(0)!);
        final month = int.parse(matches[1].group(0)!);
        final day = int.parse(matches[2].group(0)!);

        print('파싱된 날짜: $year-$month-$day');
        return DateTime(year, month, day);
      }

      print('한국어 날짜에서 충분한 숫자를 찾을 수 없음: $dateStr');
      throw FormatException('한국어 날짜 형식에서 충분한 숫자를 찾을 수 없음: $dateStr');
    }

    // 기본 날짜 형식 (YYYY-MM-DD)
    return DateTime.parse(dateStr);
  } catch (e) {
    print('날짜 파싱 오류: $e');
    print('문제가 된 날짜 문자열: $dateStr');
    return DateTime.now();
  }
}

/// 시간 정보 계산
Map<String, String> calculateTimeRange(String useTime, int useDuration, DateTime scheduledDateTime) {
  String startTime = useTime;
  String endTime = '';

  if (useTime.isNotEmpty) {
    try {
      final timeParts = useTime.split(':');
      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final startDateTime = DateTime(
          scheduledDateTime.year,
          scheduledDateTime.month,
          scheduledDateTime.day,
          hour,
          minute,
        );

        final endDateTime = startDateTime.add(Duration(hours: useDuration));
        endTime = '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('시간 변환 오류: $e');
    }
  }

  return {
    'startTime': startTime,
    'endTime': endTime,
  };
}