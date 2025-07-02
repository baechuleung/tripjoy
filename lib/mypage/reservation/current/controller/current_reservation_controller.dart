import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/current_reservation_model.dart';

/// 예약 정보를 관리하는 통합 컨트롤러 클래스
class CurrentReservationController {
  // Firebase 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 표시할 예약 상태 정의
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_IN_PROGRESS = 'in_progress';
  static const String STATUS_COMPLETED = 'completed';

  // 컬렉션 경로
  static const String COLLECTION_TRIPFRIENDS_USERS = 'tripfriends_users';
  static const String COLLECTION_RESERVATIONS = 'reservations';

  // 싱글톤 패턴 구현
  static final CurrentReservationController _instance = CurrentReservationController._internal();

  factory CurrentReservationController() {
    return _instance;
  }

  CurrentReservationController._internal();

  /// 현재 로그인한 사용자 가져오기
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 현재 로그인한 사용자의 예약 스트림 가져오기 - 실시간 업데이트 가능
  Stream<List<Reservation>> getReservationsStream() {
    // 현재 로그인한 사용자 확인
    final user = getCurrentUser();
    if (user == null) {
      // 로그인한 사용자가 없는 경우 빈 리스트 반환
      return Stream.value([]);
    }

    final currentUserId = user.uid;
    print('현재 로그인한 사용자 ID: $currentUserId');

    // 모든 사용자 문서의 변화를 감지하는 스트림
    return _firestore
        .collection(COLLECTION_TRIPFRIENDS_USERS)
        .snapshots()
        .asyncMap((userSnapshot) async {
      List<Reservation> allReservations = [];

      // 각 사용자 문서에 대해 예약 컬렉션 조회
      for (var userDoc in userSnapshot.docs) {
        final parentId = userDoc.id;

        // 각 사용자의 예약 컬렉션 조회
        final reservationsSnapshot = await _firestore
            .collection(COLLECTION_TRIPFRIENDS_USERS)
            .doc(parentId)
            .collection(COLLECTION_RESERVATIONS)
            .get();

        // 현재 사용자와 관련된 예약만 필터링
        for (var doc in reservationsSnapshot.docs) {
          final data = doc.data();
          final userId = data['userId'] as String?;
          final status = data['status'] as String? ?? '';

          // 현재 사용자의 예약이고 completed가 아닌 경우만 포함
          if (userId == currentUserId &&
              (status == STATUS_PENDING || status == STATUS_IN_PROGRESS)) {

            // DocumentSnapshot을 Reservation 객체로 변환
            final reservation = Reservation.fromSnapshot(doc, parentId);

            // 예약 상태 자동 업데이트 (이벤트성)
            await checkAndUpdateReservationStatus(
                reservation.originalData,
                reservation.id,
                parentId
            );

            allReservations.add(reservation);
          }
        }
      }

      // 상태 및 날짜 기준으로 정렬
      _sortReservationsByStatusAndDate(allReservations);

      print('스트림에서 가져온 사용자의 예약 수: ${allReservations.length}');
      return allReservations;
    });
  }

  /// 개선된 예약 스트림 - 모든 사용자의 모든 예약에 변화가 있을 때 작동
  Stream<List<Reservation>> getReservationsRealTimeStream() {
    // 현재 로그인한 사용자 확인
    final user = getCurrentUser();
    if (user == null) {
      // 로그인한 사용자가 없는 경우 빈 리스트 반환
      return Stream.value([]);
    }

    final currentUserId = user.uid;
    print('현재 로그인한 사용자 ID (실시간 스트림): $currentUserId');

    // 사용자 컬렉션과 그 하위의 모든 예약 컬렉션의 변화를 감지하는 복합 스트림
    return _firestore
        .collectionGroup(COLLECTION_RESERVATIONS)  // 모든 예약 컬렉션을 한번에 감시
        .snapshots()
        .map((reservationsSnapshot) {
      List<Reservation> userReservations = [];

      for (var doc in reservationsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final status = data['status'] as String? ?? '';

        // 현재 사용자의 예약이고 completed가 아닌 경우만 포함
        if (userId == currentUserId &&
            (status == STATUS_PENDING || status == STATUS_IN_PROGRESS)) {

          // 문서 경로에서 부모 ID 추출
          final parentId = _extractParentIdFromPath(doc.reference.path);

          // DocumentSnapshot을 Reservation 객체로 변환
          final reservation = Reservation.fromSnapshot(doc, parentId);
          userReservations.add(reservation);
        }
      }

      // 상태 및 날짜 기준으로 정렬
      _sortReservationsByStatusAndDate(userReservations);

      print('실시간 스트림에서 가져온 사용자의 예약 수: ${userReservations.length}');
      return userReservations;
    });
  }

  /// 예약 목록을 상태 및 날짜 기준으로 정렬
  void _sortReservationsByStatusAndDate(List<Reservation> reservations) {
    // 현재 시간 가져오기
    final now = DateTime.now();

    reservations.sort((a, b) {
      // 1. in_progress 상태인 항목을 맨 위로
      if (a.status == STATUS_IN_PROGRESS && b.status != STATUS_IN_PROGRESS) {
        return -1;
      }
      if (a.status != STATUS_IN_PROGRESS && b.status == STATUS_IN_PROGRESS) {
        return 1;
      }

      // 2. 둘 다 in_progress인 경우: 시작 시간이 오래된 순서대로 (이용 시간이 긴 순서)
      if (a.status == STATUS_IN_PROGRESS && b.status == STATUS_IN_PROGRESS) {
        try {
          // a의 날짜 시간 정보 가져오기
          final String aDateStr = a.originalData['useDate'] as String? ?? '';
          final String aTimeStr = a.originalData['startTime'] as String? ?? '';

          // b의 날짜 시간 정보 가져오기
          final String bDateStr = b.originalData['useDate'] as String? ?? '';
          final String bTimeStr = b.originalData['startTime'] as String? ?? '';

          // 날짜나 시간 정보가 없는 경우 처리
          if (aDateStr.isEmpty || aTimeStr.isEmpty) return 1;
          if (bDateStr.isEmpty || bTimeStr.isEmpty) return -1;

          // 날짜 및 시간 파싱
          final DateTime? aDateTime = _parseReservationDateTime(aDateStr, aTimeStr);
          final DateTime? bDateTime = _parseReservationDateTime(bDateStr, bTimeStr);

          // 파싱에 실패한 경우 뒤로 밀기
          if (aDateTime == null && bDateTime == null) return 0;
          if (aDateTime == null) return 1;
          if (bDateTime == null) return -1;

          // 시작 시간이 더 이른 것(이용 시간이 긴 것)을 앞으로
          return aDateTime.compareTo(bDateTime);
        } catch (e) {
          print('진행중 예약 정렬 중 오류: $e');
          return 0;
        }
      }

      // 3. 둘 다 pending인 경우: 예약 시간이 가까운 순서대로 정렬
      try {
        // a의 날짜 시간 정보 가져오기
        final String aDateStr = a.originalData['useDate'] as String? ?? '';
        final String aTimeStr = a.originalData['startTime'] as String? ?? '';

        // b의 날짜 시간 정보 가져오기
        final String bDateStr = b.originalData['useDate'] as String? ?? '';
        final String bTimeStr = b.originalData['startTime'] as String? ?? '';

        // 날짜나 시간 정보가 없는 경우 처리
        if (aDateStr.isEmpty || aTimeStr.isEmpty) return 1;
        if (bDateStr.isEmpty || bTimeStr.isEmpty) return -1;

        // 날짜 및 시간 파싱
        final DateTime? aDateTime = _parseReservationDateTime(aDateStr, aTimeStr);
        final DateTime? bDateTime = _parseReservationDateTime(bDateStr, bTimeStr);

        // 파싱에 실패한 경우 뒤로 밀기
        if (aDateTime == null && bDateTime == null) return 0;
        if (aDateTime == null) return 1;
        if (bDateTime == null) return -1;

        // 시간 순서대로 정렬 (가까운 시간이 먼저)
        return aDateTime.compareTo(bDateTime);
      } catch (e) {
        print('날짜 정렬 중 오류: $e');
        return 0;
      }
    });
  }

  /// 날짜 및 시간 문자열을 DateTime 객체로 변환
  DateTime? _parseReservationDateTime(String useDate, String startTime) {
    try {
      // useDate: "2025년 5월 20일" 형식을 파싱
      final dateRegex = RegExp(r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일');
      final dateMatch = dateRegex.firstMatch(useDate);

      if (dateMatch == null) {
        // 대체 형식 시도: "2025-05-20"
        final List<String> dateParts = useDate.split('-');
        if (dateParts.length != 3) return null;

        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);

        // startTime: "8:10 AM" 또는 "20:10" 형식을 파싱
        return _parseTimeWithDate(year, month, day, startTime);
      }

      final year = int.parse(dateMatch.group(1)!);
      final month = int.parse(dateMatch.group(2)!);
      final day = int.parse(dateMatch.group(3)!);

      // startTime 파싱
      return _parseTimeWithDate(year, month, day, startTime);
    } catch (e) {
      print('날짜/시간 파싱 오류: $e');
      return null;
    }
  }

  /// 시간 문자열을 파싱하여 DateTime 객체 생성
  DateTime? _parseTimeWithDate(int year, int month, int day, String startTime) {
    try {
      // "8:10 AM" 또는 "오후 8:10" 형식을 파싱
      final timeRegex = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
      final timeMatch = timeRegex.firstMatch(startTime);

      if (timeMatch != null) {
        int hour = int.parse(timeMatch.group(1)!);
        final minute = int.parse(timeMatch.group(2)!);
        final ampm = timeMatch.group(3)!.toUpperCase();

        // 12시간 형식을 24시간 형식으로 변환
        if (ampm == 'PM' && hour != 12) {
          hour += 12;
        } else if (ampm == 'AM' && hour == 12) {
          hour = 0;
        }

        return DateTime(year, month, day, hour, minute);
      }

      // 오전/오후 형식 처리
      bool isPM = startTime.contains('오후');
      bool isAM = startTime.contains('오전');

      if (isPM || isAM) {
        // 오전/오후 제거하고 시간 추출
        String cleanTime = startTime
            .replaceAll('오전', '')
            .replaceAll('오후', '')
            .trim();

        final List<String> timeParts = cleanTime.split(':');
        if (timeParts.length != 2) return null;

        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        if (isPM && hour < 12) {
          hour += 12;
        } else if (isAM && hour == 12) {
          hour = 0;
        }

        return DateTime(year, month, day, hour, minute);
      }

      // 24시간 형식 "20:10"
      final List<String> timeParts = startTime.split(':');
      if (timeParts.length != 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print('시간 파싱 오류: $e');
      return null;
    }
  }

  /// 현재 로그인한 사용자의 UID와 일치하는 예약만 가져오기
  Future<List<Reservation>> getUserReservations() async {
    try {
      // 현재 로그인한 사용자 확인
      final user = getCurrentUser();
      if (user == null) {
        print('로그인된 사용자가 없습니다.');
        return [];
      }

      final currentUserId = user.uid;
      print('현재 로그인한 사용자 ID: $currentUserId');

      // 데이터 컨트롤러를 통해 예약 목록 가져오기
      final reservations = await fetchUserReservations(currentUserId);

      // 상태 컨트롤러를 통해 각 예약 상태 업데이트 체크
      for (var reservation in reservations) {
        await checkAndUpdateReservationStatus(
            reservation.originalData,
            reservation.id,
            reservation.parentId
        );
      }

      // 상태 및 날짜 기준으로 정렬
      _sortReservationsByStatusAndDate(reservations);

      return reservations;
    } catch (e) {
      print('예약 정보 가져오기 오류: $e');
      return [];
    }
  }

  /// 사용자의 예약 목록 가져오기
  Future<List<Reservation>> fetchUserReservations(String currentUserId) async {
    try {
      // 1. 모든 사용자 가져오기
      final userDocsSnapshot = await _firestore
          .collection(COLLECTION_TRIPFRIENDS_USERS)
          .get();
      final userDocs = userDocsSnapshot.docs;

      if (userDocs.isEmpty) {
        print('사용자 정보가 없습니다.');
        return [];
      }

      // 2. 각 사용자의 예약 가져오기
      List<Future<QuerySnapshot>> reservationFutures = [];
      for (var userDoc in userDocs) {
        reservationFutures.add(
            _firestore
                .collection(COLLECTION_TRIPFRIENDS_USERS)
                .doc(userDoc.id)
                .collection(COLLECTION_RESERVATIONS)
                .get()
        );
      }

      // 3. 모든 예약 병합 및 필터링
      final reservationSnapshots = await Future.wait(reservationFutures);

      List<Reservation> userReservations = [];

      for (var snapshot in reservationSnapshots) {
        // userId 필드가 현재 사용자 ID와 일치하고 특정 조건에 맞는 문서만 필터링
        final filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // userId 필드를 사용하도록 변경 (uid 대신)
          final userId = data['userId'] as String?;
          final status = data['status'] as String? ?? '';

          // userId 필드가 현재 사용자 ID와 일치하는지 확인
          final isUserReservation = userId == currentUserId;

          // status가 'completed'가 아닌 경우만 표시 (pending, in_progress만 표시)
          final isAllowedStatus =
              status == STATUS_PENDING ||
                  status == STATUS_IN_PROGRESS;

          return isUserReservation && isAllowedStatus;
        }).toList();

        // DocumentSnapshot을 Reservation 객체로 변환
        for (var doc in filteredDocs) {
          // 현재 snapshot이 속한 사용자 문서의 ID를 가져옴
          final parentId = userDocs[reservationSnapshots.indexOf(snapshot)].id;
          userReservations.add(Reservation.fromSnapshot(doc, parentId));
        }
      }

      print('사용자의 예약 수: ${userReservations.length}');
      return userReservations;
    } catch (e) {
      print('예약 정보 가져오기 오류: $e');
      return [];
    }
  }

  /// 문서 경로에서 사용자 ID 추출
  String _extractParentIdFromPath(String path) {
    final pathParts = path.split('/');
    return pathParts.length >= 3 ? pathParts[1] : 'unknown';
  }

  /// 예약 시간이 지났을 경우 자동으로 상태 업데이트
  Future<void> checkAndUpdateReservationStatus(
      Map<String, dynamic> data,
      String docId,
      String parentId
      ) async {
    try {
      final status = data['status'] as String? ?? '';

      // 대기 상태이면서 서비스 진행 중이 아닌 경우
      if (status == STATUS_PENDING) {
        final useDate = data['useDate'] as String? ?? '';
        final useTime = data['useTime'] as String? ?? '';

        if (useDate.isNotEmpty && useTime.isNotEmpty) {
          try {
            final dateParts = useDate.split('-');
            final timeParts = useTime.split(':');

            if (dateParts.length == 3 && timeParts.length == 2) {
              final year = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[2]);
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);

              final startTime = DateTime(year, month, day, hour, minute);
              final now = DateTime.now();

              // 시작 시간이 현재보다 이전이면 자동으로 진행 중 상태로 변경
              if (now.isAfter(startTime)) {
                await _firestore
                    .collection(COLLECTION_TRIPFRIENDS_USERS)
                    .doc(parentId)
                    .collection(COLLECTION_RESERVATIONS)
                    .doc(docId)
                    .update({
                  'status': STATUS_IN_PROGRESS,
                  'statusHistory': FieldValue.arrayUnion([
                    {
                      'status': STATUS_IN_PROGRESS,
                      'message': '예약 시간이 시작되어 자동으로 진행 중 상태로 변경되었습니다.',
                      'timestamp': Timestamp.now(),
                    }
                  ]),
                });
                print('자동으로 진행 중 상태로 변경됨: $docId');
              }
            }
          } catch (e) {
            print('시간 변환 오류: $e');
          }
        }
      }
    } catch (e) {
      print('상태 업데이트 중 오류: $e');
    }
  }

  /// 프렌즈 정보 로드
  Future<Map<String, dynamic>> loadFriendsInfo(Map<String, dynamic> reservation) async {
    try {
      // Get the friends_uid from the reservation data
      final String friendsUid = reservation['friends_uid'] as String? ?? '';

      print('프렌즈 정보 로드 중: $friendsUid');

      // Check if friendsUid is empty
      if (friendsUid.isEmpty) {
        throw Exception('프렌즈 ID 정보가 없습니다.');
      }

      final guideDoc = await _firestore
          .collection(COLLECTION_TRIPFRIENDS_USERS)
          .doc(friendsUid)  // Use friends_uid instead of uid
          .get();

      if (!guideDoc.exists) {
        throw Exception('프렌즈 정보를 찾을 수 없습니다.');
      }

      return guideDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print('프렌즈 정보 로드 오류: $e');
      rethrow;
    }
  }

  /// 예약 취소 처리
  /// 예약 취소 처리 - 리턴 값은 취소 성공 여부
  Future<bool> cancelReservation(
      BuildContext context,
      Map<String, dynamic> reservation,
      String uid,
      ) async {
    try {
      print('예약 취소 시도 중...');
      print('예약 데이터: ${reservation.toString()}');

      // 문서 경로가 잘못되었을 수 있으므로 다양한 컬렉션 경로 시도
      String? docId;
      bool isDeleted = false;

      // 프렌즈 ID 가져오기 (friends_uid 필드)
      final String friendsId = reservation['friends_uid'] ?? '';
      if (friendsId.isEmpty) {
        print('프렌즈 ID를 찾을 수 없습니다.');
        return false;
      }

      // 컬렉션 경로 후보들
      final possibleCollectionPaths = [
        // 일반적인 경로
        _firestore.collection(COLLECTION_TRIPFRIENDS_USERS).doc(uid).collection(COLLECTION_RESERVATIONS),
        // 루트 레벨에 있을 수 있는 경로
        _firestore.collection(COLLECTION_RESERVATIONS),
        // 사용자 ID가 다를 수 있음 (friends_uid로 시도)
        _firestore.collection(COLLECTION_TRIPFRIENDS_USERS).doc(friendsId).collection(COLLECTION_RESERVATIONS),
        // 사용자 ID가 다를 수 있음 (userId 필드로 시도) - uid에서 userId로 변경
        _firestore.collection(COLLECTION_TRIPFRIENDS_USERS).doc(reservation['userId']).collection(COLLECTION_RESERVATIONS),
      ];

      for (final collectionPath in possibleCollectionPaths) {
        print('컬렉션 경로 시도 중: ${collectionPath.path}');

        // 1. reservationNumber로 시도
        if (reservation['reservationNumber'] != null) {
          final querySnapshot = await collectionPath
              .where('reservationNumber', isEqualTo: reservation['reservationNumber'])
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            docId = querySnapshot.docs.first.id;
            print('예약번호로 문서 찾음: $docId');

            await collectionPath.doc(docId).delete();
            print('문서 삭제 성공');
            isDeleted = true;
            break;
          }
        }

        // 2. useDate + useTime + friends_uid 조합으로 시도
        if (!isDeleted && reservation['useDate'] != null && reservation['useTime'] != null && reservation['friends_uid'] != null) {
          final querySnapshot = await collectionPath
              .where('useDate', isEqualTo: reservation['useDate'])
              .where('useTime', isEqualTo: reservation['useTime'])
              .where('friends_uid', isEqualTo: reservation['friends_uid'])
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            docId = querySnapshot.docs.first.id;
            print('날짜+시간+프렌즈ID 조합으로 문서 찾음: $docId');

            await collectionPath.doc(docId).delete();
            print('문서 삭제 성공');
            isDeleted = true;
            break;
          }
        }

        // 3. 모든 예약 데이터를 불러와서 여러 필드 비교
        if (!isDeleted) {
          final querySnapshot = await collectionPath.get();
          print('컬렉션에서 ${querySnapshot.docs.length}개 문서 가져옴');

          for (final doc in querySnapshot.docs) {
            final data = doc.data();

            // 필드 출력하여 디버깅
            print('문서 ID: ${doc.id}, 데이터: ${data.toString()}');

            // 주요 필드들이 일치하는지 확인 (최소 3개 이상 일치하면 동일한 예약으로 간주)
            int matchCount = 0;

            // 일치하는 필드 수 계산 - uid를 userId로 변경
            if (data['reservationNumber'] == reservation['reservationNumber']) matchCount++;
            if (data['useDate'] == reservation['useDate']) matchCount++;
            if (data['useTime'] == reservation['useTime']) matchCount++;
            if (data['friends_uid'] == reservation['friends_uid']) matchCount++;
            if (data['userId'] == reservation['userId']) matchCount++;

            print('문서 ${doc.id}의 일치 필드 수: $matchCount');

            if (matchCount >= 3) {
              docId = doc.id;
              print('다중 필드 일치로 문서 찾음: $docId');

              await collectionPath.doc(docId).delete();
              print('문서 삭제 성공');
              isDeleted = true;
              break;
            }
          }

          if (isDeleted) break;
        }
      }

      // 성공 여부 반환
      if (isDeleted) {
        print('예약이 성공적으로 취소되었습니다.');
      } else {
        print('예약을 찾을 수 없거나 취소할 수 없습니다.');
      }

      return isDeleted;
    } catch (e) {
      print('예약 취소 중 오류: $e');
      return false;
    }
  }

  /// 채팅 섹션 표시 여부를 결정하는 메서드
  bool shouldShowChatSection(Map<String, dynamic> reservation) {
    // status 상태 확인 - in_progress일 경우에만 채팅 표시
    final String status = reservation['status'] as String? ?? STATUS_PENDING;
    if (status != STATUS_IN_PROGRESS) {
      return false;
    }

    // 예약 날짜 및 시간 확인
    final String useDate = reservation['useDate'] as String? ?? '';
    final String useTime = reservation['useTime'] as String? ?? '';

    if (useDate.isEmpty || useTime.isEmpty) {
      return false;
    }

    // 예약 날짜와 시간을 DateTime 객체로 변환
    try {
      final List<String> dateParts = useDate.split('-');
      final List<String> timeParts = useTime.split(':');

      if (dateParts.length != 3 || timeParts.length != 2) {
        return false;
      }

      final int year = int.parse(dateParts[0]);
      final int month = int.parse(dateParts[1]);
      final int day = int.parse(dateParts[2]);
      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      final DateTime reservationDateTime = DateTime(year, month, day, hour, minute);
      final DateTime now = DateTime.now();

      // 예약 시간으로부터 48시간(2일)이 지났는지 확인
      final Duration difference = now.difference(reservationDateTime);

      // 48시간 이내면 채팅 표시
      return difference.inHours < 48;
    } catch (e) {
      print('날짜/시간 변환 오류: $e');
      return false;
    }
  }
}