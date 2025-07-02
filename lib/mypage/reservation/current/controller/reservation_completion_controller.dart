// lib/components/side_drawer/mypage/reservation/current/controller/reservation_completion_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/price_time_service.dart';

class ReservationCompletionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 이용종료 시 실시간 요금과 이용 시간을 DB에 저장하는 메서드
  Future<bool> completeReservation({
    required String friendsId,
    required String reservationId,
    required Map<String, dynamic> reservationData,
  }) async {
    try {
      // 현재 시간 생성
      final Timestamp now = Timestamp.now();

      // 가격 관련 데이터
      final int pricePerHour = reservationData['pricePerHour'] ?? 0;
      final String useDate = reservationData['useDate'] ?? '';
      final String startTime = reservationData['startTime'] ?? '';

      // 실시간 요금 계산
      Map<String, dynamic> realTimePriceInfo = PriceTimeService.calculateRealTimePrice(
        status: 'in_progress',
        pricePerHour: pricePerHour,
        useDate: useDate,
        startTime: startTime,
        reservationData: reservationData,
      );

      // 최종 요금과 이용 시간
      final int finalPrice = realTimePriceInfo['totalPrice'];
      final String finalUsedTime = realTimePriceInfo['usedTime'];

      // 완료 정보를 맵 형태로 묶기
      final Map<String, dynamic> completionInfo = {
        'completedAt': now,
        'finalPrice': finalPrice,
        'finalUsedTime': finalUsedTime,
      };

      // 예약 정보 업데이트
      await _firestore
          .collection('tripfriends_users')
          .doc(friendsId)
          .collection('reservations')
          .doc(reservationId)
          .update({
        'status': 'completed',
        'completionInfo': completionInfo,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'completed',
            'message': '프렌즈 이용이 완료되었습니다. 최종 금액: $finalPrice, 이용 시간: $finalUsedTime',
            'timestamp': now,
          }
        ]),
      });

      print('이용 완료: 최종 금액: $finalPrice, 이용 시간: $finalUsedTime');
      return true;
    } catch (e) {
      print('이용종료 처리 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    }
  }
}