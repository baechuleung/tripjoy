import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/past_reservation_model.dart';
import './past_reservation_profile_widget.dart';
import './past_reservation_price_widget.dart';
import './past_reservation_info_widget.dart';
import './past_reservation_buttons_widget.dart';

/// 지난 예약 정보를 표시하는 카드 위젯
class PastReservationInfo extends StatelessWidget {
  final PastReservationModel reservation;
  final String currentUserId;
  final String docId;
  final Function() onReload;

  const PastReservationInfo({
    Key? key,
    required this.reservation,
    required this.currentUserId,
    required this.docId,
    required this.onReload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 예약번호 가져오기
    final String reservationNumber = reservation.reservationNumber;

    // 프렌즈 ID
    final String friendsId = reservation.originalData['friends_uid'] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // 카드 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 예약번호, 상태 표시
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '예약번호 $reservationNumber',
                            style: TextStyle(
                              color: const Color(0xFF4E5968),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '이용완료',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // 프렌즈 프로필 정보 위젯
                  PastReservationProfileWidget(friendsId: friendsId),
                  SizedBox(height: 12),
                  // 요금 표시 위젯
                  PastReservationPriceWidget(reservation: reservation),
                  SizedBox(height: 12),
                  // 예약 정보 위젯
                  PastReservationInfoWidget(reservation: reservation),
                ],
              ),
            ),
            // 버튼 영역
            PastReservationButtonsWidget(
              currentUserId: currentUserId,
              friendsId: friendsId,
              reservation: reservation.originalData,
            ),
          ],
        ),
      ),
    );
  }
}