import 'package:flutter/material.dart';
import 'package:tripjoy/components/side_drawer/mypage/reservation/reservation_page.dart';
import 'message_handler.dart';

class ReservationHandler {
  static void handleReservationRequest(Map<String, dynamic> data) {
    String? reservationId = data['reservation_id'];
    if (reservationId != null) {
      print('🔍 예약 상세로 이동: $reservationId');
      _navigateToReservationPage();
    }
  }

  static void processReservationRequest(Map<String, dynamic> data) {
    print('🔍 예약 요청 처리 중: ${data['reservation_id']}');
  }

  static void _navigateToReservationPage() {
    if (messageHandlerNavigatorKey.currentState == null) {
      print('⚠️ navigatorKey.currentState가 null입니다');
      return;
    }

    try {
      final context = messageHandlerNavigatorKey.currentContext!;
      final currentRoute = ModalRoute.of(context)?.settings.name;
      print('현재 경로(이동 전): $currentRoute');

      if (!(currentRoute == '/reservation')) {
        print('🔔 예약 내역 화면으로 이동 시도...');

        messageHandlerNavigatorKey.currentState!.popUntil((route) => route.isFirst);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReservationPage(),
            settings: RouteSettings(name: '/reservation'),
          ),
        );

        print('✅ 예약 내역 화면으로 이동 완료');
      } else {
        print('ℹ️ 이미 예약 내역 화면에 있습니다');
      }
    } catch (e, stackTrace) {
      print('❌ 화면 이동 중 오류 발생: $e');
      print('스택 트레이스: $stackTrace');
    }
  }
}