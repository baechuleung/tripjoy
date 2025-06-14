import 'package:flutter/material.dart';
import 'friends_reservation_action_button.dart';
import 'friends_chat_action_button.dart';

class FriendsReservationButton extends StatelessWidget {
  final String friends_uid;

  const FriendsReservationButton({
    super.key,
    required this.friends_uid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      child: Row(
        children: [
          // 채팅하기 버튼
          Expanded(
            flex: 4,
            child: FriendsChatActionButton(friends_uid: friends_uid),
          ),

          const SizedBox(width: 8),

          // 예약하기 버튼
          Expanded(
            flex: 6,
            child: FriendsReservationActionButton(friends_uid: friends_uid),
          ),
        ],
      ),
    );
  }
}