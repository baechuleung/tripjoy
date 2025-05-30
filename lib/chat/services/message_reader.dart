// lib/chat/services/message_reader.dart - 트립조이 앱(고객용)
import 'package:firebase_database/firebase_database.dart';
import 'chat_service.dart';

class MessageReader {
  final FirebaseDatabase _database;
  final ChatService _chatService = ChatService();

  MessageReader() : _database = FirebaseDatabase.instance;

  // 메시지를 읽음 상태로 표시 - 개선된 버전
  Future<void> markMessagesAsRead(String userId, String friendsId) async {
    final String chatId = _chatService.getChatId(userId, friendsId);
    print('메시지 읽음 표시 시작 - 사용자ID: $userId, 프렌즈ID: $friendsId');

    try {
      // 1. 사용자의 채팅 목록에서 읽지 않은 메시지 카운트 리셋
      await _database.ref().child('users/$userId/chats/$chatId').update({
        'unreadCount': 0,
      });
      print('사용자 채팅 목록 unreadCount 리셋 완료');

      // 2. 중요: 프렌즈가 보낸 메시지만 찾아서 읽음 표시 업데이트
      final messagesSnapshot = await _database
          .ref()
          .child('chat/$chatId/messages')
          .orderByChild('senderId')
          .equalTo(friendsId)        // 프렌즈가 보낸 메시지만 가져오기
          .get();

      int updatedCount = 0;
      if (messagesSnapshot.exists && messagesSnapshot.value != null) {
        final messages = Map<String, dynamic>.from(messagesSnapshot.value as Map);
        print('프렌즈가 보낸 메시지 ${messages.length}개 읽음 표시 시작');

        // 각 메시지 읽음 상태로 업데이트
        for (var entry in messages.entries) {
          final key = entry.key;
          final message = Map<String, dynamic>.from(entry.value);

          // isRead가 false일 경우 true로 업데이트
          if (!(message['isRead'] as bool? ?? false)) {
            await _database.ref().child('chat/$chatId/messages/$key').update({
              'isRead': true
            });
            updatedCount++;
          }
        }
      }
      print('총 $updatedCount개 메시지 읽음 표시 완료');

      // 3. 채팅 정보의 읽지 않은 메시지 카운트 리셋
      await _database.ref().child('chat/$chatId/info').update({
        'unreadCount': 0,
      });
      print('채팅 정보 unreadCount 리셋 완료');
    } catch (e) {
      print('메시지 읽음 표시 과정 중 오류 발생: $e');
    }
  }

  // 터치 이벤트마다 호출될 간소화된 읽음 표시 함수
  Future<void> quickMarkAsRead(String userId, String friendsId) async {
    final String chatId = _chatService.getChatId(userId, friendsId);

    try {
      // 프렌즈가 보낸 메시지만 가져오기
      final messagesSnapshot = await _database
          .ref()
          .child('chat/$chatId/messages')
          .orderByChild('senderId')
          .equalTo(friendsId)
          .get();

      if (messagesSnapshot.exists && messagesSnapshot.value != null) {
        final messages = Map<String, dynamic>.from(messagesSnapshot.value as Map);

        // 읽지 않은 메시지만 업데이트
        List<Future> updatePromises = [];
        for (var entry in messages.entries) {
          final key = entry.key;
          final message = Map<String, dynamic>.from(entry.value);

          if (!(message['isRead'] as bool? ?? false)) {
            updatePromises.add(
                _database.ref().child('chat/$chatId/messages/$key').update({
                  'isRead': true
                })
            );
          }
        }

        // 모든 업데이트 완료 대기
        if (updatePromises.isNotEmpty) {
          await Future.wait(updatePromises);

          // 카운트 리셋
          await _database.ref().child('chat/$chatId/info').update({
            'unreadCount': 0,
          });

          await _database.ref().child('users/$userId/chats/$chatId').update({
            'unreadCount': 0,
          });
        }
      }
    } catch (e) {
      print('빠른 읽음 표시 오류: $e');
    }
  }
}