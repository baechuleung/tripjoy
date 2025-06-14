import 'package:flutter/material.dart';
import '../../../../chat/screens/chat_screen.dart';
import '../../../../point_module/point_page.dart';
import '../services/chat_point_service.dart';

class FriendsChatActionButton extends StatelessWidget {
  final String friends_uid;
  final ChatPointService _pointService = ChatPointService();

  FriendsChatActionButton({
    super.key,
    required this.friends_uid,
  });

  // 포인트 부족 다이얼로그 표시
  void _showInsufficientPointsDialog(BuildContext context, int currentPoints) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('포인트 부족'),
          content: Text(
            '새로운 채팅을 시작하려면 ${_formatNumber(ChatPointService.chatPointCost)} 포인트가 필요합니다.\n'
                '현재 포인트: ${_formatNumber(currentPoints)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 포인트 충전 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PointPage(),
                  ),
                );
              },
              child: const Text('충전하기'),
            ),
          ],
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
        return AlertDialog(
          title: const Text('포인트 차감 안내'),
          content: Text(
            '채팅을 시작하면 ${_formatNumber(ChatPointService.chatPointCost)} 포인트가 차감됩니다.\n계속하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('계속하기'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // 숫자 포맷팅 (천 단위 콤마)
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // 채팅 화면으로 이동
  Future<void> _navigateToChatScreen(BuildContext context) async {
    try {
      // 현재 사용자 ID 가져오기
      final userId = _pointService.getCurrentUserId();
      if (userId == null) {
        throw Exception("로그인이 필요합니다.");
      }

      // 채팅 시작 가능 여부 확인
      final result = await _pointService.checkChatStartAvailability(userId, friends_uid);

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
          final success = await _pointService.deductPoints(userId, friends_uid);
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
      final friendsInfo = await _pointService.getFriendsInfo(friends_uid);
      if (friendsInfo == null) {
        throw Exception("프렌즈 정보를 찾을 수 없습니다.");
      }

      if (context.mounted) {
        // 채팅 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: userId,
              friendsId: friends_uid,
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
    return ElevatedButton(
      onPressed: () => _navigateToChatScreen(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF237AFF),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(
          color: Color(0xFF237AFF),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: const Text(
        '채팅하기',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}