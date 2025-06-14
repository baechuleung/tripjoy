import 'package:flutter/material.dart';
import './chat_button_widget.dart';
import './cancel_button_widget.dart';

/// 채팅 및 예약 취소 버튼 위젯
class CurrentReservationButtonsWidget extends StatelessWidget {
  final String currentUserId;
  final String friendsId;
  final Map<String, dynamic> reservation;
  final VoidCallback? onTimerExpired;
  final String status;

  const CurrentReservationButtonsWidget({
    Key? key,
    required this.currentUserId,
    required this.friendsId,
    required this.reservation,
    this.onTimerExpired,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ChatButtonWidget(
              currentUserId: currentUserId,
              friendsId: friendsId,
            ),
          ),

          SizedBox(width: 8),

          Expanded(
            child: CancelButtonWidget(
              friendsId: friendsId,
              reservation: reservation,
              onTimerExpired: onTimerExpired,
              status: status,
            ),
          ),
        ],
      ),
    );
  }
}