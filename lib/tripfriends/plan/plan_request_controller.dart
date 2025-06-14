// plan_request_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PlanRequestController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 리스너 구독 관리
  StreamSubscription<QuerySnapshot>? _planSubscription;

  // 요청 처리 중 상태 관리
  bool _isProcessing = false;

  // 디버깅을 위한 변수
  bool _logEnabled = true;

  // 중복 감지 방지를 위한 변수
  DateTime? _lastUpdateTime;
  final int _debounceMilliseconds = 500;

  // 폼 데이터
  String selectedCountry = '';
  String? selectedCountryFlag;
  Map<String, dynamic>? selectedCity;

  // 플랜 상태 관련 데이터
  bool isPlanning = false;
  String? activePlanId;
  Map<String, dynamic>? activePlanData;

  // UI 상태 관련
  bool submittedOnce = false;

  // 국가 리스트
  final List<Map<String, String>> countries = [
    {'code': 'KR', 'name': '대한민국', 'flag': '🇰🇷'},
    {'code': 'JP', 'name': '일본', 'flag': '🇯🇵'},
    {'code': 'VN', 'name': '베트남', 'flag': '🇻🇳'},
    {'code': 'TH', 'name': '태국', 'flag': '🇹🇭'},
    {'code': 'PH', 'name': '필리핀', 'flag': '🇵🇭'},
  ];

  // 상태 변경 콜백
  Function(VoidCallback fn)? onStateChanged;
  Function()? onPlanningStateChanged;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.uid;
  bool get isProcessing => _isProcessing;

  void init() {
    checkActivePlan();

    if (_logEnabled) {
      print('컨트롤러 초기화 - 로그인 상태: $isLoggedIn');
      if (isLoggedIn) {
        print('현재 로그인 사용자 ID: $userId');
      }
    }
  }

  void dispose() {
    _planSubscription?.cancel();
  }

  // 진행 중인 플랜 요청 확인
  void checkActivePlan() {
    _planSubscription?.cancel();
    _planSubscription = null;

    if (!isLoggedIn) {
      _updatePlanningState(false, null, null);
      return;
    }

    final currentUserId = userId;
    if (currentUserId == null) {
      if (_logEnabled) print('사용자 ID가 없습니다.');
      _updatePlanningState(false, null, null);
      return;
    }

    if (_logEnabled) print('플랜 요청 확인 - 현재 ID: $currentUserId');

    _planSubscription = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('plan_requests')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        try {
          final doc = snapshot.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          final now = DateTime.now();
          if (_lastUpdateTime != null &&
              now.difference(_lastUpdateTime!).inMilliseconds < _debounceMilliseconds) {
            if (_logEnabled) print('짧은 시간 내 중복 업데이트 무시: ${doc.id}');
            return;
          }
          _lastUpdateTime = now;

          if (_logEnabled && activePlanId != doc.id) {
            print('플랜 요청 찾음 (ID 변경): ${doc.id}');
            print('플랜 데이터: $data');
          } else if (_logEnabled && data['createdAt'] != null && activePlanData?['createdAt'] == null) {
            print('플랜 요청 업데이트 (타임스탬프): ${doc.id}');
          }

          _updatePlanningState(true, doc.id, data);

          if (data.containsKey('friendlist')) {
            final friendlist = data['friendlist'] as Map<String, dynamic>?;
            if (_logEnabled) print('friendlist 필드 발견: $friendlist');
          }

        } catch (e) {
          if (_logEnabled) print('플랜 데이터 처리 오류: $e');
          _updatePlanningState(false, null, null);
        }
      } else {
        if (_logEnabled && isPlanning) {
          print('플랜 요청 없음 (플랜 종료)');
        }
        _updatePlanningState(false, null, null);
      }
    }, onError: (error) {
      if (_logEnabled) print('플랜 요청 조회 오류: $error');
      _updatePlanningState(false, null, null);
    });
  }

  void _updatePlanningState(bool planning, String? planId, Map<String, dynamic>? planData) {
    final bool hasStateChanged = isPlanning != planning || activePlanId != planId;

    if (isPlanning == planning && activePlanId == planId && planData == null) {
      return;
    }

    if (isPlanning == planning && activePlanId == planId) {
      if (planData != null) {
        activePlanData = planData;

        final prevCreatedAt = activePlanData?['createdAt'];
        final newCreatedAt = planData['createdAt'];
        if (_logEnabled && prevCreatedAt == null && newCreatedAt != null) {
          print('타임스탬프 업데이트: $planId, $newCreatedAt');
        }
      }
      return;
    }

    isPlanning = planning;
    activePlanId = planId;
    activePlanData = planData;

    _notifyStateChanged();

    if (hasStateChanged && onPlanningStateChanged != null) {
      onPlanningStateChanged!();
    }
  }

  Future<void> cancelPlanRequest() async {
    if (activePlanId == null) {
      if (_logEnabled) print('취소할 플랜 요청 ID가 없습니다.');
      return;
    }

    if (_isProcessing) {
      if (_logEnabled) print('이미 취소 처리 중입니다.');
      return;
    }

    final currentUserId = userId;
    if (currentUserId == null) {
      if (_logEnabled) print('사용자 ID가 없습니다.');
      return;
    }

    _isProcessing = true;
    _notifyStateChanged();

    try {
      if (_logEnabled) print('플랜 요청 취소 시작 - ID: $activePlanId');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('plan_requests')
          .doc(activePlanId)
          .delete();

      if (_logEnabled) print('플랜 요청 삭제 완료 - ID: $activePlanId');

      _updatePlanningState(false, null, null);

      if (_logEnabled) print('플랜 요청이 취소되었습니다.');
    } catch (e) {
      if (_logEnabled) print('플랜 요청 취소 오류: $e');
    } finally {
      _isProcessing = false;
      _notifyStateChanged();
    }
  }

  void resetForm() {
    selectedCountry = '';
    selectedCountryFlag = null;
    selectedCity = null;
    submittedOnce = false;

    _notifyStateChanged();
  }

  void _notifyStateChanged() {
    if (onStateChanged != null) {
      onStateChanged!(() {});
    }
  }

  // 국가 설정
  void setCountry(String? country) {
    if (country != null) {
      selectedCountry = country;

      // 국가 플래그 찾기
      final countryInfo = countries.firstWhere(
            (c) => c['code'] == country,
        orElse: () => {'flag': ''},
      );
      selectedCountryFlag = countryInfo['flag'];

      // 국가가 변경되면 도시 초기화
      selectedCity = null;

      _notifyStateChanged();
    }
  }

  // 도시 설정
  void setCity(Map<String, dynamic> city) {
    selectedCity = city;
    _notifyStateChanged();
  }

  void setSubmittedOnce(bool value) {
    submittedOnce = value;
    _notifyStateChanged();
  }

  Future<Map<String, dynamic>> createPlanRequest() async {
    if (_isProcessing) {
      if (_logEnabled) print('이미 플랜 요청 처리 중입니다.');
      return {
        'success': false,
        'message': '이미 플랜 요청 처리 중입니다.',
      };
    }

    if (isPlanning) {
      if (_logEnabled) print('이미 플랜 중입니다. 새 플랜 요청을 생성하지 않습니다.');
      return {
        'success': false,
        'message': '이미 플랜 중입니다.',
      };
    }

    _isProcessing = true;
    _notifyStateChanged();

    try {
      if (!isLoggedIn) {
        throw Exception('로그인이 필요합니다.');
      }

      final currentUserId = userId;
      if (currentUserId == null) {
        throw Exception('사용자 인증 정보가 없습니다.');
      }

      if (_logEnabled) print('플랜 요청 생성 시작 - ID: $currentUserId');

      // 유저 정보 가져오기
      String userName = '사용자';
      try {
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          if (userData.containsKey('name')) {
            userName = userData['name'];
          }
        }
      } catch (e) {
        if (_logEnabled) print('사용자 정보 조회 오류: $e');
      }

      // 폼 데이터 검증
      if (selectedCountry.isEmpty) {
        throw Exception('국가를 선택해주세요.');
      }

      if (selectedCity == null) {
        throw Exception('도시를 선택해주세요.');
      }

      final timestamp = FieldValue.serverTimestamp();

      // 플랜 요청 데이터 구성 - location 필드 내에 맵 형태로 저장
      final planRequestData = {
        'userId': currentUserId,
        'userEmail': currentUser?.email ?? '',
        'userName': userName,
        // location 필드 내에 nationality와 city를 맵 형태로 저장
        'location': {
          'nationality': selectedCountry,   // 국가 코드
          'city': selectedCity!['code']     // 도시 코드
        },
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      if (_logEnabled) print('플랜 요청 데이터: $planRequestData');

      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('plan_requests')
          .add(planRequestData);

      if (_logEnabled) print('플랜 요청 생성 성공 - ID: ${docRef.id}');

      resetForm();

      return {
        'success': true,
        'message': '플랜 요청이 등록되었습니다.',
        'requestId': docRef.id
      };
    } catch (e) {
      if (_logEnabled) print('플랜 요청 생성 오류: $e');

      return {
        'success': false,
        'message': '플랜 요청 생성 오류: $e',
      };
    } finally {
      _isProcessing = false;
      _notifyStateChanged();
    }
  }

  // 유효성 검증 함수들
  String? validateCountry(String? value) {
    return value == null || value.isEmpty ? '국가를 선택해주세요' : null;
  }

  // 도시 유효성 검증
  String? validateCity(String? value) {
    // 국가 선택되지 않은 경우는 도시 필드를 무시
    if (selectedCountry.isEmpty) {
      return null;
    }

    // 제출 시도 했을 때만 유효성 검사 메시지 표시
    if (submittedOnce && (value == null || value.isEmpty)) {
      return '도시를 선택해주세요';
    }
    return null;
  }
}