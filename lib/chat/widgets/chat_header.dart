// lib/chat/widgets/chat_header.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tripjoy/tripfriends/detail/screens/friends_detail_page.dart';
import 'chat_popup_menu.dart';

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final String userId;
  final String friendsId;
  final String chatId;
  final String friendsName;
  final String? friendsImage;

  const ChatHeader({
    Key? key,
    required this.userId,
    required this.friendsId,
    required this.chatId,
    required this.friendsName,
    this.friendsImage,
  }) : super(key: key);

  // 채팅 타입 가져오기
  Future<String> _getChatType() async {
    try {
      final database = FirebaseDatabase.instance;
      database.databaseURL = 'https://tripjoy-d309f-default-rtdb.asia-southeast1.firebasedatabase.app/';

      final snapshot = await database.ref().child('chat/$chatId/info/type').get();

      if (snapshot.exists && snapshot.value != null) {
        final type = snapshot.value.toString();
        return type == 'workmate' ? '워크메이트' : '트립프렌즈';
      }

      return '트립프렌즈'; // 기본값
    } catch (e) {
      print('채팅 타입 가져오기 오류: $e');
      return '트립프렌즈'; // 오류 시 기본값
    }
  }

  // 프렌즈 상세 페이지로 이동
  Future<void> _navigateToFriendsDetailPage(BuildContext context) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Firestore에서 프렌즈 정보 가져오기
      final docSnapshot = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(friendsId)
          .get();

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프렌즈 정보를 찾을 수 없습니다.')),
          );
        }
        return;
      }

      final friendsData = docSnapshot.data()!;

      // 프렌즈 상세 페이지로 이동
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendsDetailPage(
              friends: friendsData,
            ),
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그가 표시된 경우 닫기
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프렌즈 상세 페이지 이동 중 오류가 발생했습니다: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, // 앱바 배경색을 흰색으로 설정
      elevation: 0,
      title: GestureDetector(
        onTap: () => _navigateToFriendsDetailPage(context),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: friendsImage != null
                  ? NetworkImage(friendsImage!)
                  : null,
              child: friendsImage == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
              backgroundColor: Colors.green.shade100, // 프렌즈 아바타 색상
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendsName,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
                FutureBuilder<String>(
                  future: _getChatType(),
                  builder: (context, snapshot) {
                    final chatTypeText = snapshot.data ?? '트립프렌즈';
                    final textColor = chatTypeText == '워크메이트'
                        ? const Color(0xFFF67531)
                        : const Color(0xFF3182F6);

                    return Text(
                      chatTypeText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // 팝업 메뉴 위젯 사용
        ChatPopupMenu(
          userId: userId,
          friendsId: friendsId,
          chatId: chatId,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}