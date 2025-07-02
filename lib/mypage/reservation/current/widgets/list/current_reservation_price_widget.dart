import 'package:flutter/material.dart';
import '../../models/current_reservation_model.dart';
import '../../utils/current_reservation_formatter.dart';
import '../../utils/price_time_service.dart';

/// 실시간 요금 정보를 표시하는 위젯
class CurrentReservationPriceWidget extends StatelessWidget {
  final Reservation reservation;

  const CurrentReservationPriceWidget({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 가격 관련 데이터
    final int pricePerHour = reservation.originalData['pricePerHour'] ?? 0;
    final int additionalPrice = reservation.originalData['additionalPrice'] ?? 0;

    // 통화 심볼 가져오기 - originalData에서 직접 가져옴
    final String currencySymbol = reservation.originalData['currencySymbol'] ?? '';

    // 이용 중인지 여부 확인
    final bool isInProgress = reservation.status == 'in_progress';
    final bool isPending = reservation.status == 'pending';

    // 예약 날짜 및 시간 - useDate와 startTime 사용
    String useDate = reservation.originalData['useDate'] ?? '';
    String startTime = reservation.originalData['startTime'] ?? '';

    // 한국어 날짜 형식을 YYYY-MM-DD 형식으로 변환
    if (useDate.contains('년') && useDate.contains('월')) {
      useDate = _convertDateFormat(useDate);
    }

    // 시간 형식 변환 (오후/오전 포함 -> HH:MM)
    if (startTime.contains('오전') || startTime.contains('오후') ||
        startTime.contains('AM') || startTime.contains('PM')) {
      startTime = _convertTimeFormat(startTime);
    }

    // PriceTimeService를 사용하여 실시간 요금 계산
    Map<String, dynamic> realTimePriceInfo = PriceTimeService.calculateRealTimePrice(
      status: reservation.status,
      pricePerHour: pricePerHour,
      useDate: useDate,
      startTime: startTime,
      reservationData: reservation.originalData,  // 전체 reservation 데이터 전달
    );

    // 시간 정보 (이용시간 또는 남은 시간)
    String timeInfo = "";
    Color timeColor = Colors.blue;

    // 상태에 따라 이용시간 또는 남은시간 표시
    if (isInProgress) {
      // 이용중 상태: 이용시간 표시 (파란색)
      timeInfo = realTimePriceInfo['usedTime'];
      timeColor = Colors.blue;
    } else if (isPending) {
      // 예약완료 상태: 남은시간 표시 (녹색)
      try {
        timeInfo = PriceTimeService.calculateTimeRemaining(
          useDate,
          startTime,
          reservation.originalData,
        );
        timeColor = Colors.green;
      } catch (e) {
        timeInfo = "1일 남음";
        timeColor = Colors.green;
      }
    } else {
      // 다른 상태 (경과): 경과 시간 (빨간색)
      try {
        timeInfo = PriceTimeService.calculateTimeRemaining(
          useDate,
          startTime,
          reservation.originalData,
        );
        timeColor = Colors.red;
      } catch (e) {
        timeInfo = "시간 정보 없음";
        timeColor = Colors.grey;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '실시간 요금',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$currencySymbol ${ReservationFormatter.formatCurrency(realTimePriceInfo['totalPrice'])}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            // 시간 정보 표시
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: timeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                timeInfo,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          '기본요금 $currencySymbol ${ReservationFormatter.formatCurrency(pricePerHour)}/1시간 | 추가요금 $currencySymbol ${ReservationFormatter.formatCurrency(pricePerHour ~/ 6)}/10분',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // 날짜 형식 변환 함수 (한국어 형식 -> YYYY-MM-DD)
  String _convertDateFormat(String koreanDate) {
    try {
      // 숫자만 추출
      final RegExp numRegex = RegExp(r'\d+');
      final matches = numRegex.allMatches(koreanDate).toList();

      if (matches.length >= 3) {
        final year = matches[0].group(0)!;
        final month = matches[1].group(0)!.padLeft(2, '0');
        final day = matches[2].group(0)!.padLeft(2, '0');

        final result = '$year-$month-$day';
        return result;
      }

      return koreanDate; // 변환 실패 시 원본 반환
    } catch (e) {
      return koreanDate; // 오류 발생 시 원본 반환
    }
  }

  // 시간 형식 변환 함수 (오후/오전 포함 -> HH:MM)
  String _convertTimeFormat(String koreanTime) {
    try {
      // 오전/오후 확인
      bool isPM = koreanTime.contains('오후') || koreanTime.contains('PM');

      // 숫자와 콜론만 남기기 위한 정제
      String cleanTime = koreanTime
          .replaceAll('오전', '')
          .replaceAll('오후', '')
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();

      // 시간:분 구분
      if (cleanTime.contains(':')) {
        List<String> parts = cleanTime.split(':');
        if (parts.length >= 2) {
          // 불필요한 문자 제거
          String hourStr = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
          String minuteStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');

          int hour = int.parse(hourStr);
          int minute = int.parse(minuteStr);

          // 오후인 경우 12시간 더하기 (12시는 제외)
          if (isPM && hour < 12) {
            hour += 12;
          }
          // 오전 12시는 0시로 변환
          else if (!isPM && hour == 12) {
            hour = 0;
          }

          final result = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          return result;
        }
      }

      return koreanTime; // 변환 실패 시 원본 반환
    } catch (e) {
      return koreanTime; // 오류 발생 시 원본 반환
    }
  }
}