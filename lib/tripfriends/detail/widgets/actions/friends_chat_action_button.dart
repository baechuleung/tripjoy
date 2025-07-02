import 'package:flutter/material.dart';
import '../../../../chat/screens/chat_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsChatActionButton extends StatelessWidget {
  final String friends_uid;

  FriendsChatActionButton({
    super.key,
    required this.friends_uid,
  });

  // 채팅 타입 설정 함수 추가
  Future<void> _setChatType(String userId, String friendsId, String type) async {
    try {
      final database = FirebaseDatabase.instance;
      database.databaseURL = 'https://tripjoy-d309f-default-rtdb.asia-southeast1.firebasedatabase.app/';

      List<String> ids = [userId, friendsId];
      ids.sort();
      final chatId = ids.join('_');

      await database.ref().child('chat/$chatId/info').update({
        'type': type,
      });

      print('채팅 타입 설정 완료: $type');
    } catch (e) {
      print('채팅 타입 설정 오류: $e');
    }
  }

  // 프렌즈 정보 가져오기
  Future<Map<String, dynamic>?> _getFriendsInfo(String friendsId) async {
    try {
      final friendsDoc = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(friendsId)
          .get();

      if (!friendsDoc.exists) {
        throw Exception("프렌즈 정보를 찾을 수 없습니다.");
      }

      final friendsData = friendsDoc.data()!;
      return {
        'name': friendsData['name'] ?? "프렌즈",
        'profileImageUrl': friendsData['profileImageUrl'],
      };
    } catch (e) {
      print('프렌즈 정보 조회 중 오류: $e');
      throw e;
    }
  }

  // 채팅 화면으로 이동
  Future<void> _navigateToChatScreen(BuildContext context) async {
    try {
      // 현재 사용자 ID 가져오기
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("로그인이 필요합니다.");
      }
      final userId = currentUser.uid;

      // 프렌즈 정보 가져오기
      final friendsInfo = await _getFriendsInfo(friends_uid);
      if (friendsInfo == null) {
        throw Exception("프렌즈 정보를 찾을 수 없습니다.");
      }

      // 채팅 타입을 'friends'로 설정
      await _setChatType(userId, friends_uid, 'friends');

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