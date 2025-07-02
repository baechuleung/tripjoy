import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/past_reservation_model.dart';

/// 지난 예약 정보를 관리하는 컨트롤러 클래스
class PastReservationController {
  // Firebase 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 표시할 예약 상태 정의 - completed 상태만 처리
  static const String STATUS_COMPLETED = 'completed';

  // 컬렉션 경로
  static const String COLLECTION_TRIPFRIENDS_USERS = 'tripfriends_users';
  static const String COLLECTION_RESERVATIONS = 'reservations';

  /// 현재 로그인한 사용자 가져오기
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 현재 로그인한 사용자의 완료된 예약만 가져오기
  Future<List<DocumentSnapshot>> getUserCompletedReservations() async {
    try {
      // 현재 로그인한 사용자 확인
      final user = getCurrentUser();
      if (user == null) {
        print('로그인된 사용자가 없습니다.');
        return [];
      }

      final currentUserId = user.uid;
      print('현재 로그인한 사용자 ID: $currentUserId');

      // collectionGroup을 사용하여 모든 reservations 컬렉션 조회
      final allReservationsSnapshot = await _firestore
          .collectionGroup(COLLECTION_RESERVATIONS)
          .get();

      print('전체 예약 수: ${allReservationsSnapshot.docs.length}');

      // 현재 사용자의 completed 상태 예약만 필터링
      final userCompletedReservations = allReservationsSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // userId 필드 확인 (users 문서 ID와 일치하는지)
        final String docUserId = data['userId'] as String? ?? '';
        if (docUserId != currentUserId) return false;

        // status가 completed인지 확인
        final String status = data['status'] as String? ?? '';
        return status == STATUS_COMPLETED;
      }).toList();

      print('현재 사용자의 완료된 예약 수: ${userCompletedReservations.length}');

      // statusHistory에서 completed 상태의 timestamp로 정렬
      userCompletedReservations.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;

        // statusHistory에서 completed 상태의 timestamp 찾기
        DateTime? getCompletedTimestamp(Map<String, dynamic> data) {
          final statusHistory = data['statusHistory'] as List<dynamic>?;
          if (statusHistory == null) return null;

          // statusHistory 배열을 순회하며 completed 상태 찾기
          for (final item in statusHistory) {
            if (item is Map<String, dynamic> && item['status'] == 'completed') {
              final timestamp = item['timestamp'];
              if (timestamp is Timestamp) {
                return timestamp.toDate();
              }
            }
          }
          return null;
        }

        final aCompletedTime = getCompletedTimestamp(aData);
        final bCompletedTime = getCompletedTimestamp(bData);

        // null 처리 - completed timestamp가 없으면 가장 오래된 것으로 처리
        final aTime = aCompletedTime ?? DateTime(1970);
        final bTime = bCompletedTime ?? DateTime(1970);

        // 내림차순 정렬 (최신이 위로)
        return bTime.compareTo(aTime);
      });

      print('정렬 완료');

      // 정렬 후 결과 출력
      print('========== 정렬된 예약 목록 ==========');
      for (final doc in userCompletedReservations) {
        final data = doc.data() as Map<String, dynamic>;
        final reservationNumber = data['reservationNumber'] ?? 'unknown';

        // completed timestamp 찾기
        DateTime? completedTime;
        final statusHistory = data['statusHistory'] as List<dynamic>?;
        if (statusHistory != null) {
          for (final item in statusHistory) {
            if (item is Map<String, dynamic> && item['status'] == 'completed') {
              final timestamp = item['timestamp'];
              if (timestamp is Timestamp) {
                completedTime = timestamp.toDate();
                break;
              }
            }
          }
        }

        print('예약번호: $reservationNumber - 완료시간: $completedTime');
      }
      print('=====================================');
      return userCompletedReservations;
    } catch (e) {
      print('완료된 예약 정보 가져오기 오류: $e');
      return [];
    }
  }

  /// 자동으로 이용완료 상태로 업데이트 검사 및 처리
  Future<void> checkAndUpdateCompletionStatus() async {
    try {
      final user = getCurrentUser();
      if (user == null) return;

      // 현재 사용자의 예약만 조회
      final querySnapshot = await _firestore
          .collectionGroup(COLLECTION_RESERVATIONS)
          .get();

      final now = DateTime.now();
      int updatedCount = 0;

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // 현재 사용자의 예약인지 확인
          final String docUserId = data['userId'] as String? ?? '';
          if (docUserId != user.uid) continue;

          // 이미 completed 상태인지 확인
          final String status = data['status'] as String? ?? '';
          if (status == STATUS_COMPLETED) {
            continue;
          }

          // 결제가 완료된 상태인지 확인
          if (status != 'payment_completed' && status != 'in_progress') continue;

          // 예약 날짜 확인
          final scheduledDateTime = PastReservationModel.getDateFromReservation(data);

          // 예약 시간 가져오기
          final String useTime = data['useTime'] as String? ?? '';

          if (useTime.isEmpty) {
            continue;
          }

          // 예약 기간 가져오기
          final useDuration = data['useDuration'] as int? ?? 1;

          // 시작 시간을 DateTime으로 변환
          final timeParts = useTime.split(':');
          if (timeParts.length != 2) continue;

          try {
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);

            final reservationStart = DateTime(
              scheduledDateTime.year,
              scheduledDateTime.month,
              scheduledDateTime.day,
              hour,
              minute,
            );

            // 예약 종료 시간 = 시작 시간 + 이용 시간
            final reservationEnd = reservationStart.add(Duration(hours: useDuration));

            // 현재 시간이 예약 종료 시간 이후라면 자동으로 완료 처리
            if (now.isAfter(reservationEnd)) {
              // 현재 시간을 Timestamp로 변환하여 사용
              final completedAt = Timestamp.fromDate(now);

              // 자동 완료 처리를 위한 새 상태 기록 항목
              final newStatusItem = {
                'status': STATUS_COMPLETED,
                'message': '이용 시간이 종료되어 자동으로 완료 처리되었습니다.',
                'timestamp': completedAt,
              };

              // 기존 상태 기록 배열 가져오기
              final List<dynamic> statusHistory =
                  (data['statusHistory'] as List<dynamic>?) ?? [];

              // 새 상태 항목 추가
              statusHistory.add(newStatusItem);

              // Firestore 업데이트
              await doc.reference.update({
                'status': STATUS_COMPLETED,
                'statusHistory': statusHistory,
                'completedAt': completedAt,
              });

              updatedCount++;
              print('예약번호 ${data['reservationNumber']}가 자동 완료 처리됨');
            }
          } catch (e) {
            print('시간 처리 중 오류: $e');
            continue;
          }
        } catch (e) {
          print('문서 처리 중 오류 (무시됨): $e');
          continue;
        }
      }

      print('자동 완료 상태 검사 완료. 업데이트된 예약: $updatedCount');
    } catch (e) {
      print('자동 완료 상태 검사 중 오류: $e');
    }
  }

  /// 리뷰 작성 여부 확인
  Future<bool> hasUserLeftReview(String friendsId, String reservationNumber) async {
    try {
      final reviewQuery = await _firestore
          .collection(COLLECTION_TRIPFRIENDS_USERS)
          .doc(friendsId)
          .collection('reviews')
          .where('reservationNumber', isEqualTo: reservationNumber)
          .get();

      return reviewQuery.docs.isNotEmpty;
    } catch (e) {
      print('리뷰 확인 중 오류 발생: $e');
      return false;
    }
  }
}