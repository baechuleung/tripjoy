// lib/tripfriends/friendslist/core/friends_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/data_transformer.dart';

/// Firestore 데이터 접근을 담당하는 Repository
class FriendsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// plan_request 정보 로드
  Future<Map<String, dynamic>> loadPlanRequest() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final requestSnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('plan_requests')
        .limit(1)
        .get();

    if (requestSnapshot.docs.isEmpty) {
      throw Exception('여행 요청 정보가 없습니다.');
    }

    final requestDoc = requestSnapshot.docs.first;
    final requestData = requestDoc.data();

    if (requestData['location'] is! Map) {
      throw Exception('여행 요청의 위치 정보가 없습니다.');
    }

    final location = Map<String, dynamic>.from(requestData['location'] as Map);
    final city = location['city'] as String?;
    final nationality = location['nationality'] as String?;

    if (city == null || nationality == null) {
      throw Exception('여행 요청의 위치 정보가 불완전합니다.');
    }

    return {
      'docId': requestDoc.id,
      'city': city,
      'nationality': nationality,
    };
  }

  /// 모든 친구 데이터를 스트리밍 - 단순하게!
  Stream<Map<String, dynamic>> loadAllFriendsOneByOne(Query baseQuery) async* {
    const batchSize = 50;
    DocumentSnapshot? lastDoc;
    bool hasMore = true;

    while (hasMore) {
      Query query = baseQuery.limit(batchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        break;
      }

      // 데이터 yield
      for (var doc in snapshot.docs) {
        final data = await DataTransformer.transformDocument(doc);
        yield data;
      }

      // 다음 배치 준비
      lastDoc = snapshot.docs.last;
      hasMore = snapshot.docs.length == batchSize;
    }
  }
}