// lib/chat/services/chat_service.dart - 수정된 버전
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  final FirebaseDatabase _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 푸시 알림 API 엔드포인트
  final String _notificationApiUrl = 'https://us-central1-tripjoy-d309f.cloudfunctions.net/main/send-chat-notification';

  // 현재 활성화된 채팅방 ID 관리 (싱글톤 패턴 사용)
  static String? _activeChatId;

  // 현재 활성화된 채팅방 setter
  static void setActiveChatId(String? chatId) {
    _activeChatId = chatId;
    print('현재 활성화된 채팅방 ID 설정: $_activeChatId');
  }

  // 현재 활성화된 채팅방 getter
  static String? get activeChatId => _activeChatId;

  ChatService() : _database = FirebaseDatabase.instance {
    // Firebase Realtime Database URL 설정
    _database.databaseURL =
    'https://tripjoy-d309f-default-rtdb.asia-southeast1.firebasedatabase.app/';
  }

  // 프렌즈 정보 가져오기 (이름, 프로필 이미지 등)
  Future<Map<String, dynamic>> getFriendsInfo(String friendsId) async {
    try {
      final friendsDoc = await _firestore.collection('tripfriends_users').doc(
          friendsId).get();

      if (friendsDoc.exists && friendsDoc.data() != null) {
        return friendsDoc.data()!;
      }

      // 프렌즈 정보가 없는 경우
      return {
        'name': '프렌즈',
        'email': '알 수 없음',
        'profileImageUrl': null
      };
    } catch (e) {
      print('프렌즈 정보 가져오기 오류: $e');
      return {
        'name': '프렌즈',
        'email': '알 수 없음',
        'profileImageUrl': null
      };
    }
  }

  // 채팅 ID 생성 (정렬하여 일관된 ID 생성)
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // 항상 동일한 채팅 ID를 얻기 위해 정렬
    return ids.join('_');
  }

  // 푸시 알림 전송 API 호출
  Future<void> _sendChatNotification({
    required String chatId,
    required String senderId,
    required String message,
    required String receiverId,
  }) async {
    try {
      // 현재 활성화된 채팅방인지 확인
      if (chatId == _activeChatId) {
        print('현재 활성화된 채팅방이므로 알림을 보내지 않습니다: $chatId');
        return;
      }

      // 디버깅 로그 추가
      print(
          '푸시 알림 요청 데이터: chatId=$chatId, senderId=$senderId, receiverId=$receiverId');
      print('receiverId 길이: ${receiverId.length}');
      print('receiverId 내용: $receiverId');

      final Map<String, dynamic> requestBody = {
        'chatId': chatId,
        'senderId': senderId,
        'message': message,
        'receiverId': receiverId,
      };

      print('요청 JSON: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(_notificationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('푸시 알림 전송 성공: ${response.body}');
      } else {
        print('푸시 알림 전송 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('푸시 알림 API 호출 오류: $e');
    }
  }

  // 메시지 보내기
  Future<void> sendMessage(String userId, String friendsId,
      String content) async {
    final String chatId = getChatId(userId, friendsId);
    final now = DateTime.now();

    // 디버깅 로그 추가
    print(
        'sendMessage 호출됨 - 보내는 사람ID: $userId, 받는 사람ID: $friendsId, 내용: $content');

    // 수정된 코드:
    final message = ChatMessage(
      senderId: userId,
      // reservation.uid (현재 로그인한 사용자)
      receiverId: friendsId,
      // reservation.friends_uid (프렌즈 ID)
      content: content,
      timestamp: now,
      isRead: false,
    );

    try {
      // 메시지 추가
      final messageRef = _database.ref().child('chat/$chatId/messages').push();
      await messageRef.set(message.toMap());

      // 저장된 데이터 확인을 위한 디버깅 로그
      print('메시지 저장됨 - 보낸이: ${message.senderId}, 받는이: ${message.receiverId}');

      // 채팅 정보 업데이트
      await _database.ref().child('chat/$chatId/info').update({
        'latestMessage': content,
        'timestamp': now.millisecondsSinceEpoch,
        'lastSenderId': userId,
        'participants': [userId, friendsId],
        'unreadCount': ServerValue.increment(1),
      });

      // 사용자의 채팅 목록 업데이트
      await _database.ref().child('users/$userId/chats/$chatId').update({
        'otherUserId': friendsId,
        'latestMessage': content,
        'timestamp': now.millisecondsSinceEpoch,
        'unreadCount': 0, // 사용자는 자신의 메시지를 읽은 상태
      });

      // 프렌즈의 채팅 목록 업데이트
      await _database.ref().child('users/$friendsId/chats/$chatId').update({
        'otherUserId': userId,
        'latestMessage': content,
        'timestamp': now.millisecondsSinceEpoch,
        'unreadCount': ServerValue.increment(1), // 프렌즈의 읽지 않은 메시지 수 증가
      });

      // 푸시 알림 전송 API 호출 - 프렌즈에게 알림 보내기
      _sendChatNotification(
        chatId: chatId,
        senderId: userId,
        message: content,
        receiverId: friendsId,
      );
    } catch (e) {
      print('메시지 전송 오류: $e');
      throw e;
    }
  }

  // 특정 채팅의 메시지 목록 가져오기
  Stream<List<ChatMessage>> getMessages(String userId, String friendsId) {
    final String chatId = getChatId(userId, friendsId);
    print('사용자앱 - 채팅 ID 확인: $chatId, userId: $userId, friendsId: $friendsId');

    return _database
        .ref()
        .child('chat/$chatId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      print('사용자앱 - 데이터 존재여부: ${event.snapshot.exists}');
      final List<ChatMessage> messages = [];

      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        print('사용자앱 - 원본 메시지 데이터: $data');

        data.forEach((key, value) {
          final messageData = Map<String, dynamic>.from(value);
          print(
              '사용자앱 - 메시지 상세: senderId=${messageData['senderId']}, receiverId=${messageData['receiverId']}, isRead=${messageData['isRead']}');
          messages.add(ChatMessage.fromMap(messageData));
        });

        // 시간순 정렬
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      return messages;
    });
  }

  // 예약 상태 확인 함수 추가 (chat_screen.dart에서 이동)
  Future<bool> checkReservationStatus(String friendsId) async {
    try {
      final snapshot = await _firestore
          .collection('tripfriends_users')
          .doc(friendsId)
          .collection('reservations')
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          final status = doc.data()['status'];
          // status 값이 'in_progress'인 경우 확인
          if (status != null && status == 'in_progress') {
            return true; // in_progress 상태의 예약이 있음
          }
        }
      }

      return false; // in_progress 상태의 예약이 없음
    } catch (error) {
      print('예약 상태 확인 오류: $error');
      return false; // 오류 발생 시 기본값으로 false 반환
    }
  }

  // ChatScreen에서 이동된 예약정보 가져오기 로직
  Future<Map<String, dynamic>> loadReservationData(String userId, String friendsId) async {
    try {
      // Firestore 인스턴스 가져오기
      final firestore = FirebaseFirestore.instance;

      // 1. 프렌즈 정보 가져오기 (통화 정보, 시간당 요금 등)
      print("tripfriends_users 문서 가져오기 시작");
      print("조회 경로: tripfriends_users/$friendsId");

      final friendsDoc = await firestore
          .collection('tripfriends_users')
          .doc(friendsId)
          .get();

      Map<String, dynamic> friendsData = {};
      if (friendsDoc.exists && friendsDoc.data() != null) {
        friendsData = friendsDoc.data()!;
        print("프렌즈 정보 로드 성공");
        print("currencyCode: ${friendsData['currencyCode']}");
        print("currencySymbol: ${friendsData['currencySymbol']}");
        print("pricePerHour: ${friendsData['pricePerHour']}");
      } else {
        print("프렌즈 정보를 찾을 수 없음");
      }

      // 2. plan_requests 문서 가져오기 (조건 없이)
      print("plan_requests 문서 찾기 시작 - 모든 문서");
      print("조회 경로: users/$userId/plan_requests");

      final querySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('plan_requests')
          .get();

      if (querySnapshot.docs.isEmpty) {
        // 문서가 없는 경우
        print("문서가 없음. 여행할 나라와 도시를 선택해야 합니다.");
        return {'error': 'no_plan_requests'};
      }

      // 가장 최근 문서 찾기
      print("총 ${querySnapshot.docs.length}개의 문서 발견");

      final sortedDocs = querySnapshot.docs.toList()
        ..sort((a, b) {
          final aTimestamp = a.data().containsKey('timestamp')
              ? a.data()['timestamp'] as int
              : 0;
          final bTimestamp = b.data().containsKey('timestamp')
              ? b.data()['timestamp'] as int
              : 0;
          return bTimestamp.compareTo(aTimestamp); // 내림차순 정렬
        });

      final doc = sortedDocs.first;
      final requestId = doc.id;
      Map<String, dynamic> reservationData = doc.data();

      print("사용할 문서: $requestId");
      print("문서 데이터: $reservationData");

      // 문서 데이터에 requestId 필드 추가 (없는 경우)
      if (!reservationData.containsKey('requestId')) {
        reservationData['requestId'] = requestId;
      }

      // 프렌즈 정보(통화, 시간당 요금 등) 추가
      if (friendsData.isNotEmpty) {
        if (friendsData.containsKey('currencyCode')) {
          reservationData['currencyCode'] = friendsData['currencyCode'];
        }
        if (friendsData.containsKey('currencySymbol')) {
          reservationData['currencySymbol'] = friendsData['currencySymbol'];
        }
        if (friendsData.containsKey('pricePerHour')) {
          reservationData['pricePerHour'] = friendsData['pricePerHour'];
        }
      }

      print("ReservationPage로 이동 중 - 전달 데이터 최종 확인:");
      print("  userId: $userId");
      print("  friendsId: $friendsId");
      print("  requestId: $requestId");
      print("  추가된 필드: currencyCode, currencySymbol, pricePerHour");
      print("  데이터 필드: ${reservationData.keys.toList()}");

      return {
        'userId': userId,
        'friendsId': friendsId,
        'requestId': requestId,
        'reservationData': reservationData,
      };
    } catch (e) {
      print('========== 데이터 조회 중 오류 발생 ==========');
      print('오류 내용: $e');
      print('오류 스택: ${StackTrace.current}');
      return {'error': e.toString()};
    }
  }

  // 메시지 읽음 표시 함수 - 수정된 버전
  Future<void> markMessagesAsRead(String userId, String friendsId) async {
    try {
      final String chatId = getChatId(userId, friendsId);
      print('메시지 읽음 표시 시작 - chatId: $chatId, userId: $userId, friendsId: $friendsId');

      // 메시지 읽음 상태 업데이트
      final messagesRef = _database.ref().child('chat/$chatId/messages');
      final snapshot = await messagesRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // 상대방(프렌즈)이 보낸 읽지 않은 메시지 찾기
        List<String> unreadMessageKeys = [];
        data.forEach((key, value) {
          final messageData = Map<String, dynamic>.from(value);
          // 중요: 프렌즈가 보낸 메시지 중 읽지 않은 메시지만 찾기
          if (messageData['senderId'] == friendsId &&
              messageData['receiverId'] == userId &&
              messageData['isRead'] == false) {
            unreadMessageKeys.add(key);
            print('읽지 않은 메시지 발견: key=$key, content=${messageData['content']}');
          }
        });

        print('총 ${unreadMessageKeys.length}개의 읽지 않은 메시지 발견');

        // 읽지 않은 메시지를 읽음 상태로 업데이트
        for (var key in unreadMessageKeys) {
          await messagesRef.child(key).update({'isRead': true});
          print('메시지 읽음 표시 완료: $key');
        }

        // 채팅 목록의 읽지 않은 메시지 수 초기화
        await _database.ref().child('users/$userId/chats/$chatId').update({
          'unreadCount': 0,
        });

        // 채팅방 전체 읽지 않은 메시지 수 업데이트
        await _database.ref().child('chat/$chatId/info').update({
          'unreadCount': 0,
        });

        print('✅ 메시지 읽음 표시 완료: ${unreadMessageKeys.length}개 업데이트됨');
      }
    } catch (e) {
      print('❌ 메시지 읽음 상태 업데이트 오류: $e');
    }
  }

  // 빠른 읽음 표시 함수 (디바운싱 적용) - 수정된 버전
  Future<void> quickMarkAsRead(String userId, String friendsId) async {
    try {
      final String chatId = getChatId(userId, friendsId);
      print('빠른 읽음 표시 시작 - userId: $userId, friendsId: $friendsId');

      // 메시지의 실제 읽음 상태도 업데이트
      final messagesRef = _database.ref().child('chat/$chatId/messages');
      final snapshot = await messagesRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // 읽지 않은 메시지만 필터링하여 업데이트
        List<Future> updatePromises = [];
        data.forEach((key, value) {
          final messageData = Map<String, dynamic>.from(value);
          if (messageData['senderId'] == friendsId &&
              messageData['receiverId'] == userId &&
              messageData['isRead'] == false) {
            updatePromises.add(
                messagesRef.child(key).update({'isRead': true})
            );
          }
        });

        // 모든 업데이트 완료 대기
        if (updatePromises.isNotEmpty) {
          await Future.wait(updatePromises);
          print('빠른 읽음 표시: ${updatePromises.length}개 메시지 업데이트');
        }
      }

      // 채팅 목록의 읽지 않은 메시지 수 초기화
      await _database.ref().child('users/$userId/chats/$chatId').update({
        'unreadCount': 0,
      });
    } catch (e) {
      print('빠른 읽음 표시 오류: $e');
    }
  }
}