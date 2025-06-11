// plan_request_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'plan_request_controller.dart';
import 'plan_nationality_selector.dart';
import 'plan_city_selector.dart';
import 'plan_status_section.dart';
import '../friendslist/views/friends_list_view.dart';
import 'login_required_dialog.dart';

class PlanRequestView extends StatefulWidget {
  const PlanRequestView({Key? key}) : super(key: key);

  @override
  _PlanRequestViewState createState() => _PlanRequestViewState();
}

class _PlanRequestViewState extends State<PlanRequestView> {
  final _formKey = GlobalKey<FormState>();
  late PlanRequestController _controller;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoadingFriends = false;
  List<String> _matchingFriendUserIds = [];
  StreamSubscription<DocumentSnapshot>? _planSubscription;

  @override
  void initState() {
    super.initState();
    _controller = PlanRequestController();
    _controller.onStateChanged = setState;
    _controller.init();
    _controller.onPlanningStateChanged = _handlePlanningStateChanged;
  }

  @override
  void dispose() {
    _cancelPlanSubscription();
    _controller.dispose();
    super.dispose();
  }

  void _handlePlanningStateChanged() {
    // 플랜 상태가 변경되면 구독 갱신
    if (_controller.isPlanning && _controller.activePlanData != null) {
      _setupPlanSubscription();
      _findMatchingFriends();
    } else {
      _cancelPlanSubscription();
      setState(() {
        _matchingFriendUserIds = [];
      });
    }
  }

  void _setupPlanSubscription() {
    _cancelPlanSubscription();

    if (!_controller.isPlanning || _controller.activePlanId == null) {
      return;
    }

    final currentUid = _controller.userId;
    if (currentUid == null) return;

    _planSubscription = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('plan_requests')
        .doc(_controller.activePlanId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final updatedPlanData = snapshot.data()!;
        // 플랜 데이터가 변경되면 매칭 친구 목록 다시 검색
        _findMatchingFriends();
      }
    }, onError: (error) {
      debugPrint('플랜 구독 오류: $error');
    });
  }

  void _cancelPlanSubscription() {
    _planSubscription?.cancel();
    _planSubscription = null;
  }

  Future<void> _findMatchingFriends() async {
    if (!_controller.isPlanning || _controller.activePlanData == null) {
      setState(() {
        _matchingFriendUserIds = [];
        _isLoadingFriends = false;
      });
      return;
    }

    setState(() {
      _isLoadingFriends = true;
    });

    try {
      final planData = _controller.activePlanData!;

      // location 필드에서 국가와 도시 정보 추출
      String nationality = '';
      String city = '';

      if (planData.containsKey('location') && planData['location'] is Map) {
        final locationData = planData['location'] as Map<String, dynamic>;
        nationality = locationData['nationality'] ?? '';
        city = locationData['city'] ?? '';
      }

      debugPrint('🔍 매칭할 국가/도시 검색: $nationality/$city');

      if (nationality.isEmpty || city.isEmpty) {
        debugPrint('⚠️ 국가 또는 도시 정보가 없습니다');
        setState(() {
          _matchingFriendUserIds = [];
          _isLoadingFriends = false;
        });
        return;
      }

      // tripfriends_users 컬렉션에서 location.nationality와 location.city가 일치하는 문서 검색
      final querySnapshot = await _firestore
          .collection('tripfriends_users')
          .where('location.nationality', isEqualTo: nationality)
          .where('location.city', isEqualTo: city)
          .get();

      debugPrint('✅ 매칭된 친구 수: ${querySnapshot.docs.length}');

      List<String> friendIds = [];
      for (var doc in querySnapshot.docs) {
        friendIds.add(doc.id);

        // 디버깅용 - 매칭된 친구 정보 출력
        final friendData = doc.data();
        debugPrint('👤 매칭된 친구: ${doc.id}, 이름: ${friendData['name']}, 성별: ${friendData['gender']}');
      }

      setState(() {
        _matchingFriendUserIds = friendIds;
        _isLoadingFriends = false;
      });
    } catch (e) {
      debugPrint('❌ 매칭 친구 검색 오류: $e');
      setState(() {
        _matchingFriendUserIds = [];
        _isLoadingFriends = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_controller.isLoggedIn) {
      LoginRequiredDialog.show(context);
      return;
    }

    _controller.setSubmittedOnce(true);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await _controller.createPlanRequest();
    if (result['success']) {
      // 요청 성공 후 자동으로 친구 매칭 시작
      _handlePlanningStateChanged();
    }
  }

  Widget _buildPlanButton() {
    return GestureDetector(
      onTap: _submitForm,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: ShapeDecoration(
          color: Color(0xFF5963D0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Center(
          child: Text(
            '저장하기',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_controller.isPlanning)
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Color(0xFFE4E4E4)),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 어디로 떠나시나요? 텍스트와 이미지를 Row로 배치
                      Row(
                        children: [
                          // 이미지를 텍스트 앞에 배치하고 사이즈 30으로 변경
                          Image.asset(
                            'assets/main/main_fly.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '어디로 떠나시나요?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      PlanNationalitySelector(
                        selectedNationality: _controller.selectedCountry,
                        nationalities: _controller.countries,
                        onChanged: _controller.setCountry,
                        validateNationality: _controller.validateCountry,
                      ),
                      const SizedBox(height: 10),

                      // 도시 선택 (국가와 관계없이 항상 표시)
                      PlanCitySelector(
                        selectedCityId: _controller.selectedCity?['code'],
                        selectedCountry: _controller.selectedCountry,
                        countryFlag: _controller.selectedCountryFlag ?? '🏳️',
                        onCitySelected: (city) {
                          _controller.setCity(city);
                          // 디버깅용 로그
                          print('선택된 도시: ${city['name']} (${city['code']})');
                        },
                        validateCity: _controller.validateCity,
                      ),
                      const SizedBox(height: 16),

                      // 플랜 버튼
                      _buildPlanButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 플랜 중인 경우, 상태 섹션 표시
        if (_controller.isPlanning && _controller.activePlanData != null)
          PlanStatusSection(
            planData: _controller.activePlanData!,
            onCancelPlan: _controller.cancelPlanRequest,
          ),

        // 플랜 중인 경우 프렌즈 리스트 표시
        if (_controller.isPlanning)
          FriendsListView(friendUserIds: _matchingFriendUserIds),
      ],
    );
  }
}