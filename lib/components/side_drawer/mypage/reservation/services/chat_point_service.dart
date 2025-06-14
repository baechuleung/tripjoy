import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPointService {
  static const int chatPointCost = 2000; // 2천 포인트
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 로그인한 사용자 ID 가져오기
  String? getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.uid;
  }

  // 프렌즈 정보 가져오기
  Future<Map<String, dynamic>?> getFriendsInfo(String friendsId) async {
    try {
      final friendsDoc = await _firestore
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

  // 채팅 시작 가능 여부 확인 (포인트 체크 포함)
  Future<ChatStartResult> checkChatStartAvailability(String userId, String friendsId) async {
    try {
      // 이미 채팅방이 존재하는지 확인
      final chatExists = await isChatRoomExists(userId, friendsId);

      if (chatExists) {
        print('기존 채팅방으로 이동 가능');
        return ChatStartResult(
          canStart: true,
          isNewChat: false,
          currentPoints: 0, // 기존 채팅방은 포인트 체크 불필요
        );
      }

      // 새로운 채팅방인 경우 포인트 확인
      final currentPoints = await getUserPoints(userId);
      print('현재 포인트: $currentPoints');

      if (currentPoints < chatPointCost) {
        return ChatStartResult(
          canStart: false,
          isNewChat: true,
          currentPoints: currentPoints,
          needPoints: true,
        );
      }

      return ChatStartResult(
        canStart: true,
        isNewChat: true,
        currentPoints: currentPoints,
        needsConfirmation: true,
      );
    } catch (e) {
      print('채팅 시작 가능 여부 확인 중 오류: $e');
      throw e;
    }
  }

  // 이미 채팅방이 존재하는지 확인
  Future<bool> isChatRoomExists(String userId, String friendsId) async {
    try {
      // 사용자의 포인트 히스토리에서 해당 프렌즈와의 채팅 기록이 있는지 확인
      final historyQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('points_history')
          .where('type', isEqualTo: 'chat')
          .where('friendsId', isEqualTo: friendsId)
          .limit(1)
          .get();

      if (historyQuery.docs.isNotEmpty) {
        print('포인트 히스토리에 채팅 기록이 있습니다');
        return true;
      }

      print('새로운 채팅방입니다');
      return false;
    } catch (e) {
      print('채팅방 확인 중 오류: $e');
      return false;
    }
  }

  // 포인트 잔액 확인
  Future<int> getUserPoints(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception("사용자 정보를 찾을 수 없습니다.");
      }

      final userData = userDoc.data()!;
      return userData['points'] ?? 0;
    } catch (e) {
      print('포인트 조회 중 오류: $e');
      throw e;
    }
  }

  // 포인트 차감 가능 여부 확인
  Future<bool> canDeductPoints(String userId) async {
    try {
      final currentPoints = await getUserPoints(userId);
      return currentPoints >= chatPointCost;
    } catch (e) {
      return false;
    }
  }

  // 포인트 차감 처리
  Future<bool> deductPoints(String userId, String friendsId) async {
    try {
      // 이미 채팅방이 존재하는지 확인
      final chatExists = await isChatRoomExists(userId, friendsId);
      if (chatExists) {
        print('이미 존재하는 채팅방입니다. 포인트를 차감하지 않습니다.');
        return true; // 포인트 차감 없이 true 반환
      }

      // 현재 포인트 확인
      final currentPoints = await getUserPoints(userId);

      // 포인트가 부족한 경우
      if (currentPoints < chatPointCost) {
        return false;
      }

      // 트랜잭션으로 포인트 차감 처리
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);

        // 포인트 차감
        transaction.update(userRef, {
          'points': FieldValue.increment(-chatPointCost),
        });

        // 포인트 히스토리 추가
        final historyRef = userRef.collection('points_history').doc();
        transaction.set(historyRef, {
          'amount': -chatPointCost,
          'type': 'chat',
          'description': '채팅하기',
          'friendsId': friendsId,
          'createdAt': FieldValue.serverTimestamp(),
          'balance': currentPoints - chatPointCost,
        });

        // 채팅방 생성 (중복 차감 방지)
        final List<String> ids = [userId, friendsId]..sort();
        final String chatRoomId = ids.join('_');
        final chatRef = _firestore.collection('chats').doc(chatRoomId);

        transaction.set(chatRef, {
          'participants': [userId, friendsId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTime': null,
        }, SetOptions(merge: true));
      });

      return true;
    } catch (e) {
      print('포인트 차감 중 오류: $e');
      throw e;
    }
  }

  // 포인트 차감 내역 조회
  Future<List<Map<String, dynamic>>> getPointHistory(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('points_history')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('포인트 내역 조회 중 오류: $e');
      return [];
    }
  }
}

// 채팅 시작 가능 여부 결과 클래스
class ChatStartResult {
  final bool canStart;
  final bool isNewChat;
  final int currentPoints;
  final bool needPoints;
  final bool needsConfirmation;

  ChatStartResult({
    required this.canStart,
    required this.isNewChat,
    required this.currentPoints,
    this.needPoints = false,
    this.needsConfirmation = false,
  });
}