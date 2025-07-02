import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripjoy/chat/screens/chat_screen.dart';
import 'message_handler.dart';
import '../fcm_service.dart';

class ChatHandler {
  // 대기 중인 채팅 메시지를 저장할 정적 변수
  static Map<String, dynamic>? _pendingChatData;

  // 현재 활성화된 채팅방 정보를 저장할 정적 변수들
  static String? _currentUserId;
  static String? _currentFriendId;
  static String? _currentChatId;
  static bool _isInChatScreen = false;

  // Getter 메서드들 추가 (외부에서 접근 가능)
  static bool get isInChatScreen => _isInChatScreen;
  static String? get currentChatId => _currentChatId;
  static String? get currentUserId => _currentUserId;
  static String? get currentFriendId => _currentFriendId;

  // 현재 채팅방 상태 업데이트 (ChatScreen에서 호출하도록 함)
  static void setCurrentChatRoom(String userId, String friendId, {String? chatId}) {
    _currentUserId = userId;
    _currentFriendId = friendId;

    // chatId가 제공되면 사용, 아니면 userId와 friendId를 조합하여 생성
    if (chatId != null) {
      _currentChatId = chatId;
    } else {
      // userId와 friendId를 정렬하여 일관된 chatId 형태를 생성
      List<String> ids = [userId, friendId];
      ids.sort();
      _currentChatId = '${ids[0]}_${ids[1]}';
    }

    _isInChatScreen = true;
    print('💬 [채팅] 현재 채팅방 설정: userId=$userId, friendId=$friendId, chatId=$_currentChatId');

    // 채팅방 진입 시 iOS 배지 클리어
    FCMService.clearBadge();

    // Firestore에 현재 활성 채팅방 정보 저장 (서버에서 확인 가능하도록)
    if (_currentChatId != null) {
      _updateActiveChatRoom(userId, _currentChatId!);
    }
  }

  // 채팅방에서 나갈 때 호출
  static void clearCurrentChatRoom() {
    if (_currentUserId != null) {
      // Firestore에서 활성 채팅방 정보 제거
      _clearActiveChatRoom(_currentUserId!);
    }

    _isInChatScreen = false;
    _currentUserId = null;
    _currentFriendId = null;
    _currentChatId = null;
    print('💬 [채팅] 채팅방 나감: 상태 초기화');
  }

  // Firestore에 현재 활성 채팅방 정보 업데이트
  static Future<void> _updateActiveChatRoom(String userId, String chatId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'activeChatId': chatId,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore에 활성 채팅방 정보 저장: $chatId');
    } catch (e) {
      print('⚠️ 활성 채팅방 정보 저장 실패: $e');
    }
  }

  // Firestore에서 활성 채팅방 정보 제거
  static Future<void> _clearActiveChatRoom(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'activeChatId': FieldValue.delete(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore에서 활성 채팅방 정보 제거');
    } catch (e) {
      print('⚠️ 활성 채팅방 정보 제거 실패: $e');
    }
  }

  // 앱이 시작될 때 호출되는 초기화 메서드
  static void initialize() {
    if (_pendingChatData != null) {
      print('🔄 앱 초기화 완료: 대기 중인 채팅 메시지 처리 시도');
      handleChatMessage(_pendingChatData!);
      _pendingChatData = null;
    }
  }

  static void handleChatMessage(Map<String, dynamic> data) {
    String? chatId = data['chat_id'];
    String? senderId = data['sender_id'];
    String? receiverId = data['receiver_id'];
    String? senderName = data['title'] ?? '프렌즈';

    print('💬 채팅 메시지 알림 처리: chatId=$chatId, senderId=$senderId, receiverId=$receiverId');

    if (chatId != null && senderId != null && receiverId != null) {
      if (messageHandlerNavigatorKey.currentState == null) {
        print('⚠️ 내비게이터 상태가 없습니다. 채팅 데이터 저장');
        _pendingChatData = Map<String, dynamic>.from(data);
        return;
      }

      _loadFriendsInfoAndNavigate(receiverId, senderId, chatId);
    } else {
      print('⚠️ 채팅 메시지 처리에 필요한 정보가 부족합니다.');
    }
  }

  static void processChatMessage(Map<String, dynamic> data) {
    print('💬 채팅 메시지 처리 중: ${data['chat_id']}');
  }

  static Future<void> _loadFriendsInfoAndNavigate(String userId, String friendsId, String chatId) async {
    try {
      print('🔍 친구 정보 조회 중: userId=$userId, friendsId=$friendsId, chatId=$chatId');

      DocumentSnapshot friendDoc = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(friendsId)
          .get();

      print('tripfriends_users에서 친구 정보 조회 결과: ${friendDoc.exists ? "존재함" : "없음"}');

      if (!friendDoc.exists) {
        friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendsId)
            .get();
        print('users에서 친구 정보 조회 결과: ${friendDoc.exists ? "존재함" : "없음"}');
      }

      String friendsName = "프렌즈";
      String? friendsImage;

      if (friendDoc.exists) {
        final data = friendDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          friendsName = data['name'] ?? "프렌즈";
          friendsImage = data['profileImageUrl'] ??
              data['profileUrl'] ??
              data['profileImage'] ??
              data['profile_image'];

          print('👤 친구 정보 로드 성공: 이름=$friendsName, 이미지=$friendsImage');
        }
      }

      _navigateToChatScreen(userId, friendsId, friendsName, friendsImage);

    } catch (e, stackTrace) {
      print('❌ 친구 정보 로드 오류: $e');
      print('스택 트레이스: $stackTrace');
      _navigateToChatScreen(userId, friendsId, "프렌즈", null);
    }
  }

  static void _navigateToChatScreen(String userId, String friendsId, String friendsName, String? friendsImage) {
    if (messageHandlerNavigatorKey?.currentState == null) {
      print('⚠️ navigatorKey.currentState가 null입니다');
      return;
    }

    print('🔔 채팅 화면으로 이동 시도: 사용자=$userId, 친구=$friendsId, 이름=$friendsName');

    try {
      final context = messageHandlerNavigatorKey!.currentContext!;
      final currentRoute = ModalRoute.of(context)?.settings.name;
      print('현재 경로(이동 전): $currentRoute');

      bool isAlreadyInChatRoom = false;
      messageHandlerNavigatorKey!.currentState!.popUntil((route) {
        if (route.settings.name == '/chat_screen') {
          final args = route.settings.arguments;
          if (args is Map<String, dynamic> &&
              args['friendsId'] == friendsId &&
              args['userId'] == userId) {
            isAlreadyInChatRoom = true;
            return true;
          }
        }
        return route.isFirst;
      });

      if (isAlreadyInChatRoom) {
        print('ℹ️ 이미 같은 채팅방에 있습니다');
        return;
      }

      messageHandlerNavigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: userId,
            friendsId: friendsId,
            friendsName: friendsName,
            friendsImage: friendsImage,
          ),
          settings: RouteSettings(
            name: '/chat_screen',
            arguments: {
              'userId': userId,
              'friendsId': friendsId,
            },
          ),
        ),
      );

      print('✅ 채팅 화면으로 이동 완료');
    } catch (e, stackTrace) {
      print('❌ 화면 이동 중 오류 발생: $e');
      print('스택 트레이스: $stackTrace');
    }
  }
}