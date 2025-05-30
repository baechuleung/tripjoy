import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_result.dart';
import 'package:flutter/material.dart';
import '../utils/formatter_utils.dart';
import '../services/reservation_info_service.dart';
import '../widgets/confirmation_dialog.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReservationInfoService reservationInfoService = ReservationInfoService();

  // 날짜 형식 변환
  String formatDateTime(dynamic timestamp) {
    return FormatterUtils.formatDateTime(timestamp);
  }

  // 숫자에 천 단위 쉼표 추가
  String formatCurrency(int value) {
    return FormatterUtils.formatCurrency(value);
  }

  // 위치정보 입력 여부 확인
  bool isMeetingPlaceEmpty(Map<String, dynamic> data) {
    return reservationInfoService.isMeetingPlaceEmpty(data);
  }

  // 예약 일시 입력 여부 확인
  bool isScheduledDateEmpty(Map<String, dynamic> data) {
    return reservationInfoService.isScheduledDateEmpty(data);
  }

  // 예약 인원 입력 여부 확인
  bool isPersonCountEmpty(Map<String, dynamic> data) {
    return reservationInfoService.isPersonCountEmpty(data);
  }

  // 이용목적 입력 여부 확인
  bool isPurposeEmpty(Map<String, dynamic> data) {
    return reservationInfoService.isPurposeEmpty(data);
  }

  // plan_requests에서 예약 데이터 로드
  Future<Map<String, dynamic>> loadRequestData(String userId, String requestId) async {
    try {
      print("DB에서 request 데이터 로드 시작");
      print("조회 경로: users/$userId/plan_requests/$requestId");

      final DocumentSnapshot requestDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plan_requests')
          .doc(requestId)
          .get();

      Map<String, dynamic> requestData = {};

      if (requestDoc.exists && requestDoc.data() != null) {
        print("문서 존재: ${requestDoc.id}");
        requestData = requestDoc.data() as Map<String, dynamic>;
        print("로드된 데이터: $requestData");
      } else {
        print("문서가 존재하지 않음");
      }

      return requestData;
    } catch (e) {
      print('plan_requests 데이터 로드 중 오류: $e');
      throw e;
    }
  }

  // 예약 데이터 준비
  Map<String, dynamic> prepareReservationData({
    required Map<String, dynamic> reservationData,
    required Map<String, dynamic> requestData,
    required String userId,
    required String requestId,
  }) {
    // 복사본 생성
    final Map<String, dynamic> preparedData = Map<String, dynamic>.from(reservationData);

    // 중요: userId와 requestId를 예약 데이터에 추가
    preparedData['userId'] = userId;
    preparedData['requestId'] = requestId;

    // 로드한 데이터를 예약 데이터에 병합
    final updateData = {
      'useDate': requestData['useDate'] ?? '',
    };

    // personCount가 있는 경우에만 추가 (기본값 없음)
    if (requestData.containsKey('personCount') && requestData['personCount'] != null) {
      updateData['personCount'] = requestData['personCount'];
    }

    // purpose(이용목적)가 있는 경우에만 추가
    if (requestData.containsKey('purpose') && requestData['purpose'] != null) {
      updateData['purpose'] = requestData['purpose'];
      print("기존 purpose 데이터 로드: ${requestData['purpose']}");
    } else {
      print("purpose 데이터 없음");
    }

    // meetingPlace가 있는 경우에만 추가
    if (requestData.containsKey('meetingPlace') && requestData['meetingPlace'] != null) {
      updateData['meetingPlace'] = requestData['meetingPlace'];
      print("기존 meetingPlace 데이터 로드: ${requestData['meetingPlace']}");
    } else {
      print("meetingPlace 데이터 없음");
    }

    preparedData.addAll(updateData);
    print("예약 데이터: $preparedData");

    return preparedData;
  }

  // plan_requests 컬렉션에 meetingPlace 업데이트
  Future<void> updateMeetingPlace({
    required String userId,
    required String requestId,
    required Map<String, dynamic> meetingPlace,
  }) async {
    try {
      print("== plan_requests 컬렉션에 meetingPlace 업데이트 시작 ==");
      print("업데이트 대상 문서 경로: users/$userId/plan_requests/$requestId");
      print("meetingPlace 데이터: $meetingPlace");

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('plan_requests')
          .doc(requestId)
          .update({'meetingPlace': meetingPlace});

      print("meetingPlace 업데이트 완료");
    } catch (e) {
      print("meetingPlace 업데이트 중 오류: $e");
      throw e;
    }
  }

  // 예약 생성 및 저장 - 디버깅 로그 추가
  Future<ReservationResult> createReservation({
    required String friendsId,
    required Map<String, dynamic> reservationData,
    required bool isPaymentAgreed,
    required bool isProhibitionAgreed,
    required bool isReviewPromised,
  }) async {
    try {
      print("=============== 예약 생성 시작 ===============");
      print("DB 저장 위치: tripfriends_users/$friendsId/reservations/");
      print("원본 데이터: $reservationData");
      print("동의 상태 - 현장결제: $isPaymentAgreed, 금지행위: $isProhibitionAgreed, 리뷰약속: $isReviewPromised");

      // 필수 동의 항목 확인
      if (!isPaymentAgreed || !isProhibitionAgreed) {
        print("필수 동의 항목 누락");
        return ReservationResult('', '필수 동의 항목을 확인해주세요.');
      }

      // 필수 데이터 확인 (meetingPlace, useDate, personCount)
      if (isMeetingPlaceEmpty(reservationData)) {
        print("약속 장소 정보 누락");
        return ReservationResult('', '약속 장소 정보가 누락되었습니다.');
      }

      if (isScheduledDateEmpty(reservationData)) {
        print("예약 일시 정보 누락");
        return ReservationResult('', '예약 일시 정보가 누락되었습니다.');
      }

      if (isPersonCountEmpty(reservationData)) {
        print("예약 인원 정보 누락");
        return ReservationResult('', '예약 인원 정보가 누락되었습니다.');
      }

      if (isPurposeEmpty(reservationData)) {
        print("이용목적 정보 누락");
        return ReservationResult('', '이용목적 정보가 누락되었습니다.');
      }

      // meetingPlace 중점 확인
      print("\n== 중요 필드 상세 확인 ==");

      if (reservationData.containsKey('meetingPlace')) {
        print("meetingPlace 타입: ${reservationData['meetingPlace'].runtimeType}");
        print("meetingPlace 구조: ${reservationData['meetingPlace']}");

        if (reservationData['meetingPlace'] is Map) {
          final meetingPlace = reservationData['meetingPlace'] as Map;
          print("meetingPlace 주소: ${meetingPlace['address']}");
          print("meetingPlace 위도: ${meetingPlace['latitude']}");
          print("meetingPlace 경도: ${meetingPlace['longitude']}");
        }
      } else {
        print("meetingPlace 필드가 없음");
        return ReservationResult('', '약속 장소 정보가 누락되었습니다.');
      }

      // 가격 관련 정보 확인
      print("\n== 가격 정보 확인 ==");
      final int pricePerHour = reservationData['pricePerHour'] ?? 0;
      final String currencyCode = reservationData['currencyCode'] ?? 'KRW';
      final String currencySymbol = reservationData['currencySymbol'] ?? '₩';

      print("시간당 요금: $pricePerHour");
      print("통화 코드: $currencyCode");
      print("통화 기호: $currencySymbol");

      final now = FieldValue.serverTimestamp();

      // 예약 데이터 준비 (원본 데이터의 복사본을 만듦)
      Map<String, dynamic> updatedReservationData = Map<String, dynamic>.from(reservationData);

      // matchRequestId가 있다면 제거 (requestId만 사용)
      if (updatedReservationData.containsKey('matchRequestId')) {
        updatedReservationData.remove('matchRequestId');
      }

      // friends_uid 필드 확인 및 유지 (이 필드는 필요함)
      if (!updatedReservationData.containsKey('friends_uid')) {
        print("friends_uid 필드가 없습니다. 추가합니다.");
        updatedReservationData['friends_uid'] = friendsId;
      }

      // userId 필드 확인
      if (!updatedReservationData.containsKey('userId')) {
        print("경고: userId 필드가 없습니다. 예약에 필요한 사용자 식별자가 누락되었습니다.");
        return ReservationResult('', '사용자 정보가 누락되었습니다.');
      }

      // 동의 항목 추가 (명확하게 동의 상태를 저장)
      updatedReservationData['isPaymentAgreed'] = isPaymentAgreed;
      updatedReservationData['isProhibitionAgreed'] = isProhibitionAgreed;
      updatedReservationData['isReviewPromised'] = isReviewPromised;

      // 동의 일시 추가
      updatedReservationData['agreementTimestamp'] = Timestamp.now();

      // 동의 상세 내용 추가
      updatedReservationData['agreements'] = {
        'payment': {
          'agreed': isPaymentAgreed,
          'title': '[필수] 현장결제 안내 동의',
          'timestamp': Timestamp.now(),
        },
        'prohibition': {
          'agreed': isProhibitionAgreed,
          'title': '[필수] 금지 행위 안내 동의',
          'timestamp': Timestamp.now(),
        },
        'review': {
          'agreed': isReviewPromised,
          'title': '[선택] 프렌즈 이용 후 리뷰약속 동의',
          'timestamp': Timestamp.now(),
        }
      };

      // 중요: isReviewPromised, meetingPlace가 보존되는지 확인
      print("\n== 데이터 변환 전 필수 필드 확인 ==");
      print("friends_uid 값: ${updatedReservationData['friends_uid']}");
      print("userId 값: ${updatedReservationData['userId']}");
      print("isReviewPromised 값: ${updatedReservationData['isReviewPromised']}");
      print("meetingPlace 값: ${updatedReservationData['meetingPlace']}");
      print("agreements 값: ${updatedReservationData['agreements']}");
      print("pricePerHour 값: ${updatedReservationData['pricePerHour']}");
      print("currencyCode 값: ${updatedReservationData['currencyCode']}");
      print("currencySymbol 값: ${updatedReservationData['currencySymbol']}");

      // reservation 데이터에 필요한 상태 정보 추가
      updatedReservationData['status'] = 'pending'; // 대기 상태로 설정
      updatedReservationData['createdAt'] = now;

      // 상태 이력 업데이트
      if (updatedReservationData.containsKey('statusHistory') &&
          updatedReservationData['statusHistory'] is List) {

        List<dynamic> history = List<dynamic>.from(updatedReservationData['statusHistory']);
        history.add({
          'status': 'pending',
          'message': '예약이 신청되었습니다.',
          'timestamp': Timestamp.now(),
        });

        updatedReservationData['statusHistory'] = history;
      } else {
        // 상태 이력이 없으면 새로 생성
        updatedReservationData['statusHistory'] = [
          {
            'status': 'pending',
            'message': '예약이 신청되었습니다.',
            'timestamp': Timestamp.now(),
          }
        ];
      }

      // 만약 scheduledDate 필드가 있다면 제거
      if (updatedReservationData.containsKey('scheduledDate')) {
        updatedReservationData.remove('scheduledDate');
        print("scheduledDate 필드를 제거했습니다.");
      }

      print("\n== 예약 데이터 준비 완료 ==");
      print("최종 저장 데이터의 필드들: ${updatedReservationData.keys.toList()}");
      print("최종 데이터 meetingPlace: ${updatedReservationData['meetingPlace']}");
      print("최종 데이터 useDate: ${updatedReservationData['useDate']}");
      print("최종 데이터 personCount: ${updatedReservationData['personCount']}");
      print("최종 동의 상태 - 현장결제: ${updatedReservationData['isPaymentAgreed']}, 금지행위: ${updatedReservationData['isProhibitionAgreed']}, 리뷰약속: ${updatedReservationData['isReviewPromised']}");
      print("최종 agreements 데이터: ${updatedReservationData['agreements']}");
      print("최종 pricePerHour 값: ${updatedReservationData['pricePerHour']}");
      print("최종 currencyCode 값: ${updatedReservationData['currencyCode']}");
      print("최종 currencySymbol 값: ${updatedReservationData['currencySymbol']}");

      // 최종 데이터 확인 및 추가 디버깅 로그
      print("\n== 데이터 최종 검증 ==");
      print("userId 필드 값: ${updatedReservationData['userId']}");
      print("friends_uid 필드 값: ${updatedReservationData['friends_uid']}");

      // 선택한 프렌즈의 reservations 컬렉션에만 저장
      print("\n== Firestore 저장 시작 ==");
      print("저장 경로: tripfriends_users/$friendsId/reservations");

      final reservationRef = await _firestore
          .collection('tripfriends_users')
          .doc(friendsId)
          .collection('reservations')
          .add(updatedReservationData);

      final String reservationId = reservationRef.id;
      print("== 예약 저장 완료 ==");
      print("생성된 문서 ID: $reservationId");
      print("데이터베이스 문서 경로: tripfriends_users/$friendsId/reservations/$reservationId");

      // plan_requests 컬렉션에서 해당 문서 삭제
      if (reservationData.containsKey('requestId')) {
        final String requestId = reservationData['requestId'];
        final String userId = updatedReservationData['userId'];

        print("\n== plan_requests 문서 삭제 시작 ==");
        print("삭제할 문서 경로: users/$userId/plan_requests/$requestId");

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('plan_requests')
            .doc(requestId)
            .delete();

        print("plan_requests 문서 삭제 완료");
      }

      print("=============== 예약 생성 완료 ===============");
      return ReservationResult(reservationId, '');
    } catch (e) {
      print("\n=============== 예약 생성 중 오류 발생 ===============");
      print("오류 내용: $e");
      print("스택 트레이스: ${StackTrace.current}");
      throw e; // 오류 전파
    }
  }

  // 상태 확인 메소드
  Future<bool> isReservationPending(String reservationId, String friendsId) async {
    try {
      if (reservationId.isEmpty || friendsId.isEmpty) {
        return false;
      }

      final snapshot = await _firestore
          .collection('tripfriends_users')
          .doc(friendsId)
          .collection('reservations')
          .doc(reservationId)
          .get();

      if (!snapshot.exists) {
        return false;
      }

      final data = snapshot.data();
      return data != null && data['status'] == 'pending';
    } catch (e) {
      print('예약 상태 확인 중 오류: $e');
      return false;
    }
  }

  // 동의 상태 확인 함수
  bool validateAgreements(bool isPaymentAgreed, bool isProhibitionAgreed) {
    // 필수 동의 항목 확인
    return isPaymentAgreed && isProhibitionAgreed;
  }

  // 예약 확인 다이얼로그
  void showConfirmationDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ConfirmationDialog(
          title: '예약 신청 확인',
          content: '예약을 신청하시겠습니까?',
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            onConfirm();
          },
        );
      },
    );
  }

  // 간단한 로딩 다이얼로그 표시 함수
  void showLoadingDialog(BuildContext context, {required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(dialogContext).primaryColor),
                ),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  // 오류 다이얼로그
  void showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext errorContext) {
        return ConfirmationDialog(
          title: '오류',
          content: '예약 처리 중 오류가 발생했습니다.',
          cancelText: '',
          confirmText: '확인',
          onCancel: () {},
          onConfirm: () {
            Navigator.of(errorContext).pop();
          },
        );
      },
    );
  }

  // 필수 정보 확인 다이얼로그
  void showMissingInfoDialog(BuildContext context, bool needLocationInput) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ConfirmationDialog(
          title: '필수 정보 누락',
          content: '예약을 신청하기 전에 약속 장소를 선택해주세요.',
          cancelText: '',
          confirmText: '확인',
          onCancel: () {},
          onConfirm: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
}