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

  /// 모든 친구 데이터 로드
  Future<List<Map<String, dynamic>>> loadAllFriends(
      String city,
      String nationality
      ) async {
    final query = _firestore
        .collection('tripfriends_users')
        .where('location.city', isEqualTo: city)
        .where('location.nationality', isEqualTo: nationality);

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => DataTransformer.transformDocument(doc))
        .toList();
  }

  /// 특정 ID 목록의 친구 데이터 로드
  Future<List<Map<String, dynamic>>> loadFriendsByIds(
      List<String> ids,
      String city,
      String nationality
      ) async {
    print('FriendsRepository: loadFriendsByIds - ${ids.length}개 ID 로드');
    print('FriendsRepository: 요청 위치 - $city/$nationality');

    if (ids.isEmpty) return [];

    final List<Map<String, dynamic>> friends = [];

    // ID별로 개별 로드 (whereIn은 10개 제한이 있음)
    for (String id in ids) {
      try {
        final doc = await _firestore
            .collection('tripfriends_users')
            .doc(id)
            .get();

        if (doc.exists) {
          final data = DataTransformer.transformDocument(doc);
          print('친구 로드: ${data['name']} - 위치: ${data['location']}');

          // 위치 확인 - 엄격하게 체크
          if (DataTransformer.matchesLocation(data, city, nationality)) {
            friends.add(data);
            print('✅ 위치 일치: ${data['name']}');
          } else {
            // 위치가 일치하지 않으면 추가하지 않음!
            final friendLocation = data['location'] as Map<String, dynamic>?;
            print('❌ 위치 불일치 - 제외: ${data['name']} (친구: ${friendLocation?['city']}/${friendLocation?['nationality']}, 요청: $city/$nationality)');
          }
        }
      } catch (e) {
        print('친구 데이터 로드 오류 (ID: $id): $e');
      }
    }

    print('FriendsRepository: 최종 로드된 친구 수 - ${friends.length}명');
    return friends;
  }

  /// 모든 친구 데이터를 빠르게 스트리밍 (병렬 처리) - specificIds 무시
  Stream<Map<String, dynamic>> loadAllFriendsOneByOne(
      Query baseQuery,
      {List<String>? specificIds}
      ) async* {
    print('FriendsRepository: loadAllFriendsOneByOne 시작');

    // specificIds는 무시하고 쿼리 조건에 맞는 모든 데이터 가져오기
    print('FriendsRepository: 쿼리 조건에 맞는 모든 친구 로드');

    // 첫 번째 쿼리로 전체 개수 파악
    const firstBatchSize = 100; // 첫 배치는 크게
    final firstSnapshot = await baseQuery.limit(firstBatchSize).get();

    if (firstSnapshot.docs.isEmpty) {
      print('FriendsRepository: 데이터 없음');
      return;
    }

    // 첫 배치 즉시 yield
    for (var doc in firstSnapshot.docs) {
      final data = DataTransformer.transformDocument(doc);
      yield data;
    }

    // 나머지 데이터 병렬로 가져오기
    if (firstSnapshot.docs.length == firstBatchSize) {
      DocumentSnapshot lastDoc = firstSnapshot.docs.last;
      const parallelBatchSize = 50;
      const maxParallelRequests = 5; // 동시에 5개 요청

      bool hasMore = true;
      while (hasMore) {
        // 병렬 쿼리 생성
        List<Future<QuerySnapshot>> parallelQueries = [];
        DocumentSnapshot currentLastDoc = lastDoc;

        for (int i = 0; i < maxParallelRequests; i++) {
          final query = baseQuery
              .startAfterDocument(currentLastDoc)
              .limit(parallelBatchSize);
          parallelQueries.add(query.get());

          // 다음 배치를 위한 가상의 마지막 문서 (실제로는 다음 쿼리에서 덮어씌워짐)
          if (i < maxParallelRequests - 1) {
            final tempQuery = baseQuery
                .startAfterDocument(currentLastDoc)
                .limit(parallelBatchSize);
            final tempSnapshot = await tempQuery.get();
            if (tempSnapshot.docs.isNotEmpty) {
              currentLastDoc = tempSnapshot.docs.last;
            } else {
              break;
            }
          }
        }

        // 병렬 실행
        final results = await Future.wait(parallelQueries);

        // 결과 처리
        bool foundData = false;
        for (var snapshot in results) {
          if (snapshot.docs.isNotEmpty) {
            foundData = true;
            lastDoc = snapshot.docs.last;

            for (var doc in snapshot.docs) {
              final data = DataTransformer.transformDocument(doc);
              yield data;
            }
          }
        }

        hasMore = foundData && results.last.docs.length == parallelBatchSize;
      }
    }

    print('FriendsRepository: 전체 로드 완료');
  }
}