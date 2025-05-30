import 'package:flutter/material.dart';

/// 지난 예약 정보 표시에 사용하는 포맷팅 유틸리티
class PastReservationFormatter {
  /// 날짜를 읽기 쉬운 형식으로 포맷팅
  static String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일(${getDayOfWeek(date.weekday)})';
  }

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

  /// 상태에 따른 색상 반환
  static Color getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending_review': return Colors.blue;
      case 'review_completed': return Colors.teal;
      case 'no_show': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'refund_requested': return Colors.deepOrange;
      case 'refund_completed': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  /// 상태에 따른 텍스트 반환
  static String getStatusText(String status) {
    switch (status) {
      case 'completed': return '이용완료';
      case 'pending_review': return '리뷰대기';
      case 'review_completed': return '리뷰완료';
      case 'no_show': return '불참';
      case 'cancelled': return '취소됨';
      case 'refund_requested': return '환불요청';
      case 'refund_completed': return '환불완료';
      default: return '상태미상';
    }
  }

  /// 날짜와 시간을 함께 포맷팅
  static String formatDateWithTime(DateTime date, String time) {
    return '${formatDate(date)} $time';
  }

  /// 이용 시간을 포맷팅 (시작-종료)
  static String formatTimeRange(String startTime, String endTime, int duration) {
    return '$startTime ~ $endTime (${duration}시간)';
  }

  /// 인원수 포맷팅
  static String formatPersonCount(int count) {
    return '$count명';
  }
}