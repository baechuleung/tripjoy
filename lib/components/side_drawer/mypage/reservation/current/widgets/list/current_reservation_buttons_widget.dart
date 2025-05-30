import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripjoy/chat/screens/chat_screen.dart';
import '../../controller/current_reservation_controller.dart';
import '../list/cancel_reservation_popup.dart';

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

  // 채팅 화면으로 이동
  Future<void> _navigateToChatScreen(BuildContext context, String friends_uid) async {
    try {
      // 프렌즈 정보 가져오기
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final friendsDoc = await firestore
          .collection('tripfriends_users')
          .doc(friends_uid)
          .get();

      if (!friendsDoc.exists) {
        throw Exception("프렌즈 정보를 찾을 수 없습니다.");
      }

      final friendsData = friendsDoc.data()!;
      final String friendsName = friendsData['name'] ?? "프렌즈";
      final String? friendsImage = friendsData['profileImageUrl'];

      if (context.mounted) {
        // 채팅 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: currentUserId,
              friendsId: friends_uid,
              friendsName: friendsName,
              friendsImage: friendsImage,
            ),
          ),
        );
      }
    } catch (e) {
      print('채팅 화면 이동 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 홈 화면으로 이동하는 메소드
  void _navigateToHome(BuildContext context) {
    print('홈으로 이동 시도...');
    // 모든 스택을 지우고 홈으로 이동 (더 명시적인 방법)
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  // 예약 취소 메서드 - 컨트롤러 호출
  Future<void> _handleCancelReservation(BuildContext context) async {
    try {
      // 예약 취소 확인 팝업 표시
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => const CancelReservationPopup(),
      );

      if (shouldCancel != true) return;

      // 컨트롤러 인스턴스 생성
      final controller = CurrentReservationController();

      // 컨트롤러의 취소 메서드 호출
      final isDeleted = await controller.cancelReservation(
        context,
        reservation,
        friendsId,
      );

      // 취소 결과에 따른 처리
      if (isDeleted && context.mounted) {
        print('예약이 성공적으로 취소되었습니다.');
        print('홈 화면으로 이동 시도...');

        // 홈 화면으로 이동 - 전용 메소드 사용
        _navigateToHome(context);
      } else {
        print('예약 취소에 실패했습니다.');

        // 취소 실패 시에도 리스트 새로고침
        if (onTimerExpired != null) {
          onTimerExpired!();
        }
      }
    } catch (e) {
      print('예약 취소 처리 중 오류가 발생했습니다: ${e.toString()}');

      // 오류 발생 시에도 리스트 새로고침
      if (onTimerExpired != null) {
        onTimerExpired!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // 채팅 화면으로 이동 - 프렌즈 정보를 Firestore에서 조회
                _navigateToChatScreen(context, friendsId);
              },
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
            ),
          ),

          SizedBox(width: 8),

          // 예약취소 버튼 (항상 표시, pending 상태일 때만 활성화)
          Expanded(
            child: OutlinedButton(
              onPressed: status == 'pending' ? () {
                // 예약취소 기능 실행 - 컨트롤러 메서드 호출
                _handleCancelReservation(context);
              } : null, // pending 상태가 아니면 비활성화
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
                // 비활성화 상태에서만 특별한 스타일 적용
                foregroundColor: Colors.black, // 활성화 상태에서는 검은색 텍스트
                disabledForegroundColor: Colors.grey.shade400, // 비활성화 상태에서는 연한 회색 텍스트
              ),
              child: Text(
                '예약취소',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}