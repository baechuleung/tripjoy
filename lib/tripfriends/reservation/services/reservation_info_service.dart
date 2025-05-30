import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../models/custom_map.dart';

class ReservationInfoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 약속 장소 업데이트
  Future<bool> updateMeetingPlace({
    required String userId,
    required String requestId,
    required Map<String, dynamic> meetingPlace,
  }) async {
    try {
      print("=============== 약속장소 DB 저장 시작 ===============");
      print("저장 경로: users/$userId/plan_requests/$requestId");
      print("저장 값: $meetingPlace");

      // Map<dynamic, dynamic>을 Map<String, dynamic>으로 변환
      Map<String, dynamic> convertedMeetingPlace = {};
      meetingPlace.forEach((key, value) {
        convertedMeetingPlace[key.toString()] = value;
      });

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('plan_requests')
          .doc(requestId);

      // 문서 존재 여부 확인
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // 새 문서 생성
        await docRef.set({
          'meetingPlace': convertedMeetingPlace,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("새 문서 생성 완료 (meetingPlace 포함)");
      } else {
        // 기존 문서 업데이트
        await docRef.update({
          'meetingPlace': convertedMeetingPlace,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("기존 문서 업데이트 완료");
      }

      print("=============== 약속장소 DB 저장 완료 ===============");
      return true;
    } catch (e) {
      print("약속장소 DB 저장 오류: $e");
      print("스택 트레이스: ${StackTrace.current}");
      return false;
    }
  }

  // 시작 시간 업데이트
  Future<bool> updateStartTime({
    required String userId,
    required String requestId,
    required String startTime,
  }) async {
    try {
      print("=============== 시작 시간 DB 저장 시작 ===============");
      print("저장 경로: users/$userId/plan_requests/$requestId");
      print("저장 값: $startTime");

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('plan_requests')
          .doc(requestId);

      // 문서 존재 여부 확인
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // 새 문서 생성
        await docRef.set({
          'startTime': startTime,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("새 문서 생성 완료 (startTime 포함)");
      } else {
        // 기존 문서 업데이트
        await docRef.update({
          'startTime': startTime,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("시작 시간 업데이트 완료");
      }

      print("=============== 시작 시간 DB 저장 완료 ===============");
      return true;
    } catch (e) {
      print("시작 시간 DB 저장 오류: $e");
      print("스택 트레이스: ${StackTrace.current}");
      return false;
    }
  }

  // 예약 인원 업데이트
  Future<bool> updatePersonCount({
    required String userId,
    required String requestId,
    required int personCount,
  }) async {
    try {
      print("=============== 예약 인원 DB 저장 시작 ===============");
      print("저장 경로: users/$userId/plan_requests/$requestId");
      print("저장 값: $personCount");

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('plan_requests')
          .doc(requestId);

      // 문서 존재 여부 확인
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // 새 문서 생성
        await docRef.set({
          'personCount': personCount,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("새 문서 생성 완료 (personCount 포함)");
      } else {
        // 기존 문서 업데이트
        await docRef.update({
          'personCount': personCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("예약 인원 업데이트 완료");
      }

      print("=============== 예약 인원 DB 저장 완료 ===============");
      return true;
    } catch (e) {
      print("예약 인원 DB 저장 오류: $e");
      print("스택 트레이스: ${StackTrace.current}");
      return false;
    }
  }

  // 예약 일시 업데이트
  Future<bool> updateScheduledDate({
    required String userId,
    required String requestId,
    required String useDate,
    String? useTime,
  }) async {
    try {
      print("=============== 예약 일시 DB 저장 시작 ===============");
      print("저장 경로: users/$userId/plan_requests/$requestId");
      print("저장 값: 날짜=$useDate, 시간=${useTime ?? '없음'}");

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('plan_requests')
          .doc(requestId);

      Map<String, dynamic> updateData = {
        'useDate': useDate,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // useTime이 있는 경우에만 추가
      if (useTime != null && useTime.isNotEmpty) {
        updateData['useTime'] = useTime;
      }

      // 문서 존재 여부 확인
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // 새 문서 생성
        await docRef.set(updateData, SetOptions(merge: true));
        print("새 문서 생성 완료 (useDate 포함)");
      } else {
        // 기존 문서 업데이트
        await docRef.update(updateData);
        print("예약 일시 업데이트 완료");
      }

      print("=============== 예약 일시 DB 저장 완료 ===============");
      return true;
    } catch (e) {
      print("예약 일시 DB 저장 오류: $e");
      print("스택 트레이스: ${StackTrace.current}");
      return false;
    }
  }

  // 이용목적 업데이트
  Future<bool> updatePurpose({
    required String userId,
    required String requestId,
    required String purpose,
  }) async {
    try {
      print("=============== 이용목적 DB 저장 시작 ===============");
      print("저장 경로: users/$userId/plan_requests/$requestId");
      print("저장 값: 이용목적=$purpose");

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('plan_requests')
          .doc(requestId);

      // 문서 존재 여부 확인
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // 새 문서 생성
        await docRef.set({
          'purpose': purpose,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("새 문서 생성 완료 (purpose 포함)");
      } else {
        // 기존 문서 업데이트
        await docRef.update({
          'purpose': purpose,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("이용목적 업데이트 완료");
      }

      print("=============== 이용목적 DB 저장 완료 ===============");
      return true;
    } catch (e) {
      print("이용목적 DB 저장 오류: $e");
      print("스택 트레이스: ${StackTrace.current}");
      return false;
    }
  }

  // meetingPlace가 비어있는지 확인
  bool isMeetingPlaceEmpty(Map<String, dynamic> reservationData) {
    // 디버깅을 위해 로그 추가
    print("meetingPlace 필드 확인: ${reservationData['meetingPlace']}");

    if (!reservationData.containsKey('meetingPlace')) return true;
    if (reservationData['meetingPlace'] == null) return true;
    if (reservationData['meetingPlace'] is! Map) return true;
    if ((reservationData['meetingPlace'] as Map).isEmpty) return true;

    // 주소가 있는지 확인
    final meetingPlace = reservationData['meetingPlace'] as Map;
    if (!meetingPlace.containsKey('address') ||
        meetingPlace['address'] == null ||
        meetingPlace['address'].toString().isEmpty) {
      return true;
    }

    return false;
  }

  // 예약 일시가 비어있는지 확인
  bool isScheduledDateEmpty(Map<String, dynamic> reservationData) {
    if (!reservationData.containsKey('useDate')) return true;
    if (reservationData['useDate'] == null) return true;
    if (reservationData['useDate'].toString().isEmpty) return true;

    return false;
  }

  // 예약 인원이 비어있는지 확인
  bool isPersonCountEmpty(Map<String, dynamic> reservationData) {
    // personCount 필드 확인
    final bool hasPersonCount = reservationData.containsKey('personCount') &&
        reservationData['personCount'] != null &&
        reservationData['personCount'] > 0;

    // personCount가 없으면 비어있음
    return !hasPersonCount;
  }

  // 이용목적이 비어있는지 확인
  bool isPurposeEmpty(Map<String, dynamic> reservationData) {
    if (!reservationData.containsKey('purpose')) return true;
    if (reservationData['purpose'] == null) return true;

    if (reservationData['purpose'] is String) {
      // 문자열인 경우 비어있는지 확인
      return reservationData['purpose'].toString().isEmpty;
    } else if (reservationData['purpose'] is List) {
      // 리스트인 경우 비어있는지 확인
      return (reservationData['purpose'] as List).isEmpty;
    }

    return true;
  }

  // 만남장소 선택 화면으로 이동 (PaymentController에서 이동)
  Future<bool> navigateToMapSelection(BuildContext context, Map<String, dynamic> reservationData) async {
    // 디버깅 로그 추가
    print("위치 선택 시작 - 현재 데이터: ${reservationData['meetingPlace']}");

    // 현재 meetingPlace 데이터가 있으면 가져오기
    LatLng? initialPosition;
    String? selectedAddress;

    if (reservationData.containsKey('meetingPlace') &&
        reservationData['meetingPlace'] is Map &&
        reservationData['meetingPlace'].isNotEmpty) {

      final locationData = reservationData['meetingPlace'] as Map;

      if (locationData.containsKey('latitude') &&
          locationData.containsKey('longitude')) {
        initialPosition = LatLng(
            locationData['latitude'],
            locationData['longitude']
        );
        selectedAddress = locationData['address'];
      }
    }

    // 결과 저장 변수
    bool success = false;

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomMap(
            initialPosition: initialPosition,
            selectedPosition: initialPosition,
            selectedAddress: selectedAddress,
            onLocationSelected: (position, address) {
              // 선택 후 데이터 저장
              reservationData['meetingPlace'] = {
                'latitude': position.latitude,
                'longitude': position.longitude,
                'address': address,
              };

              // 로그 추가
              print("위치 선택 완료 - 저장된 데이터: ${reservationData['meetingPlace']}");

              Navigator.pop(context, true); // 성공 여부 반환
            },
          ),
        ),
      );

      success = result == true;
    } catch (e) {
      print("위치 선택 중 오류: $e");
      success = false;
    }

    // 데이터가 제대로 저장되었는지 확인
    print("위치 선택 결과: $success, 저장된 데이터: ${reservationData['meetingPlace']}");

    return success;
  }
}