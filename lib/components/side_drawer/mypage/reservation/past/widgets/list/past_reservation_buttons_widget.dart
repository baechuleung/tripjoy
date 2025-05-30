import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripjoy/chat/screens/chat_screen.dart';
import '../../../../review/review_page_write.dart';
import '../../../popup/review_already_exists_popup.dart';

/// 채팅 및 리뷰 버튼 위젯
class PastReservationButtonsWidget extends StatelessWidget {
  final String currentUserId;
  final String friendsId;
  final Map<String, dynamic> reservation;

  const PastReservationButtonsWidget({
    Key? key,
    required this.currentUserId,
    required this.friendsId,
    required this.reservation,
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

  // 리뷰 작성 페이지로 이동
  Future<bool> _checkReviewExists(String friendsId, String reservationNumber) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      // 해당 예약번호로 작성된 리뷰가 있는지 확인
      if (friendsId.isEmpty) {
        return false;
      }

      final reviewQuery = await firestore
          .collection('tripfriends_users')
          .doc(friendsId)
          .collection('reviews')
          .where('reservationNumber', isEqualTo: reservationNumber)
          .get();

      return reviewQuery.docs.isNotEmpty;
    } catch (e) {
      print('리뷰 확인 중 오류 발생: $e');
      return false;
    }
  }

  void _navigateToReviewPage(BuildContext context, Map<String, dynamic> reservation, String friendsId) async {
    try {
      final reviewExists = await _checkReviewExists(friendsId, reservation['reservationNumber'] ?? '');

      if (reviewExists) {
        // 이미 리뷰가 있는 경우 팝업 표시
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => const ReviewAlreadyExistsPopup(),
          );
        }
      } else {
        // 리뷰가 없는 경우 리뷰 작성 페이지로 이동
        if (context.mounted) {
          // 레퍼런스 경로 생성
          final path = 'tripfriends_users/${reservation['friends_uid']}/reservations/${reservation['id']}';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewPageWrite(
                reservation: {
                  ...reservation,
                  '_path': path,
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('리뷰 페이지 이동 중 오류 발생: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리뷰 페이지 이동 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          // 하단 버튼 영역
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // 채팅 화면으로 이동
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

              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // 리뷰 작성 페이지로 이동
                    _navigateToReviewPage(context, reservation, friendsId);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xFFFF3E6C), // 배경색 추가
                    side: BorderSide.none, // 테두리 제거
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '리뷰 작성하기',
                    style: TextStyle(
                      color: Colors.white, // 텍스트 색상을 흰색으로 변경 (배경이 어두워졌으므로)
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}