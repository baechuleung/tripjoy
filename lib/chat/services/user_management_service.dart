// lib/services/user_management_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // 프렌즈 신고하기 (고객 -> 프렌즈)
  Future<void> reportUser({
    required String reporterId, // 신고자 ID (고객 ID)
    required String reportedUserId, // 신고 대상 프렌즈 ID
    required String reason, // 신고 이유
    String? customReason, // 기타 이유의 경우 상세 설명
  }) async {
    try {
      // 신고 정보 생성
      final reportData = {
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'customReason': customReason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // 처리 상태 (pending, reviewed, resolved 등)
        'reportType': 'customer_to_friends', // 신고 유형 추가 (고객 -> 프렌즈)
      };

      // Firestore에 신고 정보 저장
      await _firestore.collection('reports').add(reportData);

      print('프렌즈 신고 성공: $reportedUserId');
    } catch (e) {
      print('프렌즈 신고 오류: $e');
      throw e;
    }
  }

  // 프렌즈 차단하기 (고객 -> 프렌즈)
  Future<void> blockUser({
    required String blockerId, // 차단자 ID (고객 ID)
    required String blockedUserId, // 차단 대상 프렌즈 ID
    required String chatId, // 채팅방 ID
  }) async {
    try {
      // 1. 고객의 차단 목록에 프렌즈 추가
      await _firestore.collection('users').doc(blockerId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId])
      });

      // 2. 채팅방 정보 업데이트 - 차단 상태로 변경
      await _database.ref().child('chat/$chatId/info').update({
        'blocked': true,
        'blockedBy': blockerId,
        'blockedAt': ServerValue.timestamp,
        'blockType': 'customer_to_friends', // 차단 유형 추가 (고객 -> 프렌즈)
      });

      // 3. 고객 채팅 목록에서 채팅방 상태 업데이트
      await _database.ref().child('users/$blockerId/chats/$chatId').update({
        'blocked': true,
      });

      // 4. 프렌즈 채팅 목록에서 채팅방 상태 업데이트
      await _database.ref().child('users/$blockedUserId/chats/$chatId').update({
        'blocked': true,
        'blockedByCustomer': true, // 고객에 의해 차단됨을 명시
      });

      print('프렌즈 차단 성공: $blockedUserId');
    } catch (e) {
      print('프렌즈 차단 오류: $e');
      throw e;
    }
  }

  // 차단된 프렌즈인지 확인
  Future<bool> isUserBlocked(String userId, String friendsId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final List<dynamic> blockedUsers = userData['blockedUsers'] ?? [];
        return blockedUsers.contains(friendsId);
      }
      return false;
    } catch (e) {
      print('차단 프렌즈 확인 오류: $e');
      return false;
    }
  }

  // 차단된 프렌즈 목록 가져오기 (마이페이지용)
  Future<List<Map<String, dynamic>>> getBlockedUsersList(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data() == null) {
        return [];
      }

      final userData = userDoc.data()!;
      final List<dynamic> blockedUsers = userData['blockedUsers'] ?? [];

      // 차단된 프렌즈 정보 가져오기
      List<Map<String, dynamic>> blockedFriendsList = [];

      for (String friendsId in blockedUsers) {
        try {
          final friendsDoc = await _firestore.collection('tripfriends_users').doc(friendsId).get();
          if (friendsDoc.exists && friendsDoc.data() != null) {
            final friendsData = friendsDoc.data()!;
            blockedFriendsList.add({
              'id': friendsId,
              'name': friendsData['name'] ?? '알 수 없음',
              'profileImageUrl': friendsData['profileImageUrl'],
              'blockedAt': friendsData['blockedAt'] ?? DateTime.now().millisecondsSinceEpoch,
            });
          }
        } catch (e) {
          print('프렌즈 정보 가져오기 오류: $e');
        }
      }

      // 차단 시간 기준 내림차순 정렬
      blockedFriendsList.sort((a, b) => (b['blockedAt'] as int).compareTo(a['blockedAt'] as int));

      return blockedFriendsList;
    } catch (e) {
      print('차단 프렌즈 목록 가져오기 오류: $e');
      return [];
    }
  }

  // 프렌즈 차단 해제하기 (수정됨 - 차단 관련 필드 모두 삭제)
  Future<void> unblockUser(String userId, String friendsId) async {
    try {
      // 1. 차단 목록에서 제거
      await _firestore.collection('users').doc(userId).update({
        'blockedUsers': FieldValue.arrayRemove([friendsId])
      });

      // 2. 해당 프렌즈와의 채팅방 ID 찾기
      final chatId = getChatId(userId, friendsId);

      // 3. 채팅방 차단 관련 필드 삭제
      final chatInfoRef = _database.ref().child('chat/$chatId/info');
      await chatInfoRef.update({
        'blocked': null,
        'blockedBy': null,
        'blockedAt': null,
        'blockType': null,
        'unblockedAt': ServerValue.timestamp, // 해제 시간만 기록
      });

      // 4. 사용자 채팅 목록에서 차단 관련 필드 삭제
      await _database.ref().child('users/$userId/chats/$chatId').update({
        'blocked': null,
      });

      // 5. 프렌즈 채팅 목록에서 차단 관련 필드 삭제
      await _database.ref().child('users/$friendsId/chats/$chatId').update({
        'blocked': null,
        'blockedByCustomer': null,
      });

      print('프렌즈 차단 해제 성공: $friendsId');
    } catch (e) {
      print('프렌즈 차단 해제 오류: $e');
      throw e;
    }
  }

  // 채팅 ID 생성 (정렬하여 일관된 ID 생성)
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // 항상 동일한 채팅 ID를 얻기 위해 정렬
    return ids.join('_');
  }
}