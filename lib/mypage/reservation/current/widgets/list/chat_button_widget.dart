import 'package:flutter/material.dart';
import 'package:tripjoy/chat/screens/chat_screen.dart';
import 'package:firebase_database/firebase_database.dart';

/// 프렌즈와 채팅하기 버튼 위젯
class ChatButtonWidget extends StatelessWidget {
  final String currentUserId;
  final String friendsId;

  ChatButtonWidget({
    Key? key,
    required this.currentUserId,
    required this.friendsId,
  }) : super(key: key);

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
      final database = FirebaseDatabase.instance;
      database.databaseURL = 'https://tripjoy-d309f-default-rtdb.asia-southeast1.firebasedatabase.app/';

      final snapshot = await database.ref('friends/$friendsId').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('프렌즈 정보 가져오기 오류: $e');
      return null;
    }
  }

  // 채팅 화면으로 이동
  Future<void> _navigateToChatScreen(BuildContext context) async {
    try {
      // 프렌즈 정보 가져오기
      final friendsInfo = await _getFriendsInfo(friendsId);
      if (friendsInfo == null) {
        throw Exception("프렌즈 정보를 찾을 수 없습니다.");
      }

      // 채팅 타입을 'friends'로 설정
      await _setChatType(currentUserId, friendsId, 'friends');

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