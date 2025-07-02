// lib/chat/services/chat_list_service.dart - 트립프렌즈 앱(고객용)
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/chat_list_item.dart';
import '../services/chat_service.dart';

class ChatListService {
  final String customerId;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ChatService _chatService = ChatService();

  // 텍스트 변수들
  String _noMessageText = '메시지 없음';
  String _blockedChatText = '차단된 채팅';

  ChatListService({required this.customerId}) {
    _database.databaseURL = 'https://tripjoy-d309f-default-rtdb.asia-southeast1.firebasedatabase.app/';
  }

  // 채팅 목록 가져오기 - 성능 개선
  Future<List<ChatListItem>> getChatList() async {
    try {
      print('채팅 목록 가져오기 시작 - 사용자 ID: $customerId');

      // 사용자의 채팅 목록 경로
      final snapshot = await _database.ref()
          .child('users/$customerId/chats')
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        print('채팅 목록 없음: users/$customerId/chats');
        return [];
      }

      final Map<dynamic, dynamic> chatsData = Map<dynamic, dynamic>.from(snapshot.value as Map);
      print('채팅 목록 데이터 가져옴: ${chatsData.length}개');

      // 채팅 데이터를 리스트로 변환
      final List<MapEntry<dynamic, dynamic>> chatsList = chatsData.entries.toList();

      // 클라이언트 측에서 타임스탬프로 정렬 (내림차순)
      chatsList.sort((a, b) => (b.value['timestamp'] ?? 0)
          .compareTo(a.value['timestamp'] ?? 0));

      // 프렌즈 ID 목록 생성 - 병렬 처리를 위한 준비
      final Map<String, Map<String, dynamic>> chatDataMap = {};

      for (var entry in chatsList) {
        final chatId = entry.key as String;
        final chatData = Map<String, dynamic>.from(entry.value);
        chatDataMap[chatId] = chatData;
      }

      // 결과 리스트
      List<ChatListItem> resultList = [];

      // 병렬로 모든 프렌즈 정보 가져오기
      final friendsInfoFutures = <String, Future<Map<String, dynamic>>>{};

      for (var chatId in chatDataMap.keys) {
        final otherUserId = chatDataMap[chatId]!['otherUserId'] as String? ?? '';
        if (otherUserId.isNotEmpty) {
          friendsInfoFutures[otherUserId] = _chatService.getFriendsInfo(otherUserId);
        }
      }

      // 모든 프렌즈 정보 병렬로 가져오기 기다림
      final friendsInfoResults = <String, Map<String, dynamic>>{};
      for (var entry in friendsInfoFutures.entries) {
        try {
          friendsInfoResults[entry.key] = await entry.value;
        } catch (e) {
          print('프렌즈 정보 로드 오류 (건너뜀): ${entry.key} - $e');
          // 오류 발생 시 기본값 설정
          friendsInfoResults[entry.key] = {
            'name': '프렌즈',
            'profileImageUrl': null
          };
        }
      }

      // 채팅 타입 정보 가져오기 - 병렬 처리
      final chatTypeFutures = <String, Future<String?>>{};
      for (var chatId in chatDataMap.keys) {
        chatTypeFutures[chatId] = _chatService.getChatTypeById(chatId);
      }

      // 모든 채팅 타입 정보 병렬로 가져오기
      final chatTypeResults = <String, String?>{};
      for (var entry in chatTypeFutures.entries) {
        try {
          chatTypeResults[entry.key] = await entry.value;
        } catch (e) {
          print('채팅 타입 로드 오류 (건너뜀): ${entry.key} - $e');
          chatTypeResults[entry.key] = null;
        }
      }

      // 채팅 목록 항목 생성
      for (var chatId in chatDataMap.keys) {
        final chatData = chatDataMap[chatId]!;

        // 필수 데이터 추출 (null 체크 추가)
        final otherUserId = chatData['otherUserId'] as String? ?? '';
        final latestMessage = chatData['latestMessage'] as String? ?? _noMessageText;
        final timestamp = chatData['timestamp'] is int ? chatData['timestamp'] as int : 0;
        final unreadCount = chatData['unreadCount'] is int ? chatData['unreadCount'] as int : 0;
        final isBlocked = chatData['blocked'] == true;

        // 이미 가져온 프렌즈 정보 사용
        if (otherUserId.isNotEmpty && friendsInfoResults.containsKey(otherUserId)) {
          final friendsInfo = friendsInfoResults[otherUserId]!;
          final friendsName = friendsInfo['name'] ?? '프렌즈';
          final friendsImage = friendsInfo['profileImageUrl'];

          // 시간 포맷팅
          final formattedTime = _formatTimestamp(timestamp);

          // 차단된 채팅인 경우 메시지 변경
          final displayMessage = isBlocked ? _blockedChatText : latestMessage;

          // 채팅 타입 가져오기
          final chatType = chatTypeResults[chatId];

          // 채팅 목록 아이템 생성
          final chatItem = ChatListItem(
            chatId: chatId,
            friendsId: otherUserId,
            friendsName: friendsName,
            friendsImage: friendsImage,
            lastMessage: displayMessage,
            formattedTime: formattedTime,
            timestamp: timestamp,
            unreadCount: unreadCount,
            isBlocked: isBlocked,
            type: chatType,
          );

          resultList.add(chatItem);
        }
      }

      print('총 ${resultList.length}개의 채팅 항목 처리 완료');
      return resultList;
    } catch (e) {
      print('채팅 목록 가져오기 오류: $e');
      throw e;
    }
  }

  // 실시간 채팅 목록 스트림 - 성능 개선
  Stream<List<ChatListItem>> getChatListStream() {
    return _database.ref()
        .child('users/$customerId/chats')
        .onValue
        .asyncMap((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return [];
      }

      final Map<dynamic, dynamic> chatsData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      // 채팅 데이터를 리스트로 변환
      final List<MapEntry<dynamic, dynamic>> chatsList = chatsData.entries.toList();

      // 클라이언트 측에서 타임스탬프로 정렬 (내림차순)
      chatsList.sort((a, b) => (b.value['timestamp'] ?? 0)
          .compareTo(a.value['timestamp'] ?? 0));

      // 프렌즈 ID 목록 생성 - 병렬 처리를 위한 준비
      final Map<String, Map<String, dynamic>> chatDataMap = {};

      for (var entry in chatsList) {
        final chatId = entry.key as String;
        final chatData = Map<String, dynamic>.from(entry.value);
        chatDataMap[chatId] = chatData;
      }

      // 결과 리스트
      List<ChatListItem> resultList = [];

      // 병렬로 모든 프렌즈 정보 가져오기
      final friendsInfoFutures = <String, Future<Map<String, dynamic>>>{};

      for (var chatId in chatDataMap.keys) {
        final otherUserId = chatDataMap[chatId]!['otherUserId'] as String? ?? '';
        if (otherUserId.isNotEmpty) {
          friendsInfoFutures[otherUserId] = _chatService.getFriendsInfo(otherUserId);
        }
      }

      // 모든 프렌즈 정보 병렬로 가져오기 기다림
      final friendsInfoResults = <String, Map<String, dynamic>>{};
      for (var entry in friendsInfoFutures.entries) {
        try {
          friendsInfoResults[entry.key] = await entry.value;
        } catch (e) {
          print('프렌즈 정보 로드 오류 (건너뜀): ${entry.key} - $e');
          // 오류 발생 시 기본값 설정
          friendsInfoResults[entry.key] = {
            'name': '프렌즈',
            'profileImageUrl': null
          };
        }
      }

      // 채팅 타입 정보 가져오기 - 병렬 처리
      final chatTypeFutures = <String, Future<String?>>{};
      for (var chatId in chatDataMap.keys) {
        chatTypeFutures[chatId] = _chatService.getChatTypeById(chatId);
      }

      // 모든 채팅 타입 정보 병렬로 가져오기
      final chatTypeResults = <String, String?>{};
      for (var entry in chatTypeFutures.entries) {
        try {
          chatTypeResults[entry.key] = await entry.value;
        } catch (e) {
          print('채팅 타입 로드 오류 (건너뜀): ${entry.key} - $e');
          chatTypeResults[entry.key] = null;
        }
      }

      // 채팅 목록 항목 생성
      for (var chatId in chatDataMap.keys) {
        final chatData = chatDataMap[chatId]!;

        // 필수 데이터 추출 (null 체크 추가)
        final otherUserId = chatData['otherUserId'] as String? ?? '';
        final latestMessage = chatData['latestMessage'] as String? ?? _noMessageText;
        final timestamp = chatData['timestamp'] is int ? chatData['timestamp'] as int : 0;
        final unreadCount = chatData['unreadCount'] is int ? chatData['unreadCount'] as int : 0;
        final isBlocked = chatData['blocked'] == true;

        // 이미 가져온 프렌즈 정보 사용
        if (otherUserId.isNotEmpty && friendsInfoResults.containsKey(otherUserId)) {
          final friendsInfo = friendsInfoResults[otherUserId]!;
          final friendsName = friendsInfo['name'] ?? '프렌즈';
          final friendsImage = friendsInfo['profileImageUrl'];

          // 시간 포맷팅
          final formattedTime = _formatTimestamp(timestamp);

          // 차단된 채팅인 경우 메시지 변경
          final displayMessage = isBlocked ? _blockedChatText : latestMessage;

          // 채팅 타입 가져오기
          final chatType = chatTypeResults[chatId];

          // 채팅 목록 아이템 생성
          final chatItem = ChatListItem(
            chatId: chatId,
            friendsId: otherUserId,
            friendsName: friendsName,
            friendsImage: friendsImage,
            lastMessage: displayMessage,
            formattedTime: formattedTime,
            timestamp: timestamp,
            unreadCount: unreadCount,
            isBlocked: isBlocked,
            type: chatType,
          );

          resultList.add(chatItem);
        }
      }

      return resultList;
    });
  }

  // 채팅방 삭제하기
  Future<void> deleteChat(String chatId) async {
    try {
      // 사용자의 채팅 목록에서 채팅방 삭제
      await _database.ref()
          .child('users/$customerId/chats/$chatId')
          .remove();

      print('채팅 삭제 완료: $chatId');
      return;
    } catch (e) {
      print('채팅 삭제 오류: $e');
      throw e;
    }
  }

  // 시간 포맷팅 함수
  String _formatTimestamp(int timestamp) {
    if (timestamp <= 0) {
      return '';
    }

    try {
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime yesterday = today.subtract(const Duration(days: 1));
      final DateTime messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate == today) {
        // 오늘 - 시간만 표시
        return DateFormat('HH:mm').format(dateTime);
      } else if (messageDate == yesterday) {
        // 어제
        return 'Yesterday';
      } else if (now.difference(dateTime).inDays < 7) {
        // 일주일 이내 - 요일 표시
        return DateFormat('EEEE', 'ko_KR').format(dateTime);
      } else {
        // 그 외 - 날짜 표시
        return DateFormat('yy.MM.dd').format(dateTime);
      }
    } catch (e) {
      print('시간 포맷팅 오류: $e');
      return '';
    }
  }
}