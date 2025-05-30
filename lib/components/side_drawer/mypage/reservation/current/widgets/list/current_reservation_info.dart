import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/current_reservation_model.dart';
import '../../utils/current_reservation_formatter.dart';
import '../../controller/current_reservation_controller.dart';
import '../../controller/reservation_completion_controller.dart';
import './current_reservation_profile_widget.dart';
import './current_reservation_price_widget.dart';
import './current_reservation_info_widget.dart';
import './current_reservation_buttons_widget.dart';
import '../../../popup/completion_confirmation_popup.dart';
import '../../utils/price_time_service.dart';

/// 현재 예약 정보를 표시하는 카드 위젯
class CurrentReservationInfo extends StatelessWidget {
  final Reservation reservation;
  final String currentUserId;
  final Function(Reservation) onViewDetail;
  final VoidCallback? onTimerExpired;

  const CurrentReservationInfo({
    Key? key,
    required this.reservation,
    required this.currentUserId,
    required this.onViewDetail,
    this.onTimerExpired,
  }) : super(key: key);

  // 이용종료 처리
  Future<bool> _completeReservation(BuildContext context, String friendsId, String reservationId) async {
    try {
      // ReservationCompletionController 사용
      final completionController = ReservationCompletionController();

      final success = await completionController.completeReservation(
        friendsId: friendsId,
        reservationId: reservationId,
        reservationData: reservation.originalData,
      );

      if (success) {
        print('이용이 완료되었습니다.');

        // 리스트 새로고침을 위해 콜백 호출
        if (onTimerExpired != null) {
          onTimerExpired!();
        }
        return true;
      } else {
        print('이용종료 처리에 실패했습니다.');
        return false;
      }
    } catch (e) {
      print('이용종료 처리 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 예약번호 가져오기
    final String reservationNumber = reservation.reservationNumber;

    // 프렌즈 ID
    final String friendsId = reservation.originalData['friends_uid'] ?? '';

    // 이용 중인지 여부 확인
    final bool isInProgress = reservation.status == 'in_progress';
    final bool isPending = reservation.status == 'pending';

    // 예약 날짜 및 시간 - useDate와 startTime 사용
    String useDate = reservation.originalData['useDate'] ?? '';
    String startTime = reservation.originalData['startTime'] ?? '';
    int pricePerHour = reservation.originalData['pricePerHour'] ?? 0;
    String currencySymbol = reservation.originalData['currencySymbol'] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isInProgress ? Color(0xFFE8F2FF) : Colors.white, // in_progress 상태일 때 배경색 변경
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // 카드 상단 영역 (클릭 기능 제거)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 예약번호와 상태
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '예약번호 $reservationNumber',
                        style: TextStyle(
                          color: const Color(0xFF4E5968),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // 상태 표시 (간단하게 표시)
                      Text(
                        isInProgress
                            ? '이용중'
                            : isPending
                            ? '예약완료'
                            : '',
                        style: TextStyle(
                          color: isInProgress
                              ? const Color(0xFF0059B7)
                              : isPending
                              ? Colors.green
                              : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // 프렌즈 프로필 정보 위젯
                  CurrentReservationProfileWidget(friendsId: friendsId),

                  SizedBox(height: 12),

                  // 요금 표시 위젯 (남은 시간/이용 시간 포함)
                  CurrentReservationPriceWidget(reservation: reservation),

                  SizedBox(height: 12),

                  // 예약 정보 위젯
                  CurrentReservationInfoWidget(reservation: reservation),
                ],
              ),
            ),

            // 버튼 영역 (클릭해도 상세 페이지로 이동하지 않음)
            Column(
              children: [
                // 이용종료하기 버튼 (진행 중일 때만 표시)
                if (isInProgress) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // PriceTimeService 활용하여 실시간 요금 계산
                          Map<String, dynamic> realTimePriceInfo = PriceTimeService.calculateRealTimePrice(
                            status: 'in_progress',
                            pricePerHour: pricePerHour,
                            useDate: useDate,
                            startTime: startTime,
                            reservationData: reservation.originalData,
                          );

                          int finalPrice = realTimePriceInfo['totalPrice'];
                          String usedTime = realTimePriceInfo['usedTime'];

                          // 이용종료 확인 팝업 표시 - currencySymbol 전달
                          final shouldComplete = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false, // 배경 탭으로 닫기 방지
                            builder: (context) => CompletionConfirmationPopup(
                              totalPrice: finalPrice,
                              usedTime: usedTime,
                              currencySymbol: currencySymbol,
                            ),
                          );

                          // 이용종료하기 버튼 클릭 시 처리 부분
                          if (shouldComplete == true) {
                            // 이용종료하기 기능 실행
                            final success = await _completeReservation(
                              context,
                              friendsId,
                              reservation.id,
                            );

                            if (success && context.mounted) {
                              // 성공 시 콜백만 호출 (페이지 이동 없음)
                              if (onTimerExpired != null) {
                                onTimerExpired!();
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3182F6), // 파란색 버튼
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          '이용종료하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // 하단 버튼 영역
                CurrentReservationButtonsWidget(
                  currentUserId: currentUserId,
                  friendsId: friendsId,
                  reservation: reservation.originalData,
                  onTimerExpired: onTimerExpired,
                  status: reservation.status,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}