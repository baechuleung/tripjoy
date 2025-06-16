import 'package:flutter/material.dart';
import 'package:tripjoy/chat/screens/chat_screen.dart';
import '../../../services/chat_point_service.dart';
import '../popups/chat_point_popup.dart';

/// 프렌즈와 채팅하기 버튼 위젯
class ChatButtonWidget extends StatelessWidget {
  final String currentUserId;
  final String friendsId;
  final ChatPointService _pointService = ChatPointService();

  ChatButtonWidget({
    Key? key,
    required this.currentUserId,
    required this.friendsId,
  }) : super(key: key);

  // 포인트 부족 다이얼로그 표시
  void _showInsufficientPointsDialog(BuildContext context, int currentPoints) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChatPointPopup(
          type: ChatPointPopupType.insufficientPoints,
          requiredPoints: ChatPointService.chatPointCost,
          currentPoints: currentPoints,
        );
      },
    );
  }

  // 포인트 차감 확인 다이얼로그 표시
  Future<bool> _showPointDeductionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ChatPointPopup(
          type: ChatPointPopupType.pointDeduction,
          requiredPoints: ChatPointService.chatPointCost,
        );
      },
    ) ?? false;
  }

  // 채팅 화면으로 이동
  Future<void> _navigateToChatScreen(BuildContext context) async {
    try {
      // 채팅 시작 가능 여부 확인
      final result = await _pointService.checkChatStartAvailability(currentUserId, friendsId);

      // 포인트 부족한 경우
      if (result.needPoints) {
        if (context.mounted) {
          _showInsufficientPointsDialog(context, result.currentPoints);
        }
        return;
      }

      // 새로운 채팅방이고 포인트 차감 확인이 필요한 경우
      if (result.needsConfirmation) {
        if (context.mounted) {
          final confirmed = await _showPointDeductionDialog(context);
          if (!confirmed) {
            return; // 사용자가 취소한 경우
          }

          // 포인트 차감 처리
          final success = await _pointService.deductPoints(currentUserId, friendsId);
          if (!success) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('포인트 차감에 실패했습니다.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
      }

      // 프렌즈 정보 가져오기
      final friendsInfo = await _pointService.getFriendsInfo(friendsId);
      if (friendsInfo == null) {
        throw Exception("프렌즈 정보를 찾을 수 없습니다.");
      }

      if (context.mounted) {
        // 채팅 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: currentUserId,
              friendsId: friendsId,
              friendsName: friendsInfo['name'],
              friendsImage: friendsInfo['profileImageUrl'],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅 화면 이동 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _navigateToChatScreen(context),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        '프렌즈와 채팅하기',
        style: TextStyle(
          color: Colors.black,
          fontSize: 14,
        ),
      ),
    );
  }
}