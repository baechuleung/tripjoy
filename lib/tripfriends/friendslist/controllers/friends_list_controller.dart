// lib/tripfriends/friendslist/controllers/friends_list_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:tripjoy/services/translation_service.dart';
import '../filter/friends_filter_service.dart';
import '../services/friends_data_service.dart';

// 전역 컨트롤러 (앱 전체에서 공유)
FriendsListController? globalFriendsListController;

class FriendsListController with ChangeNotifier {
  final TranslationService _translationService = TranslationService();
  final FriendsFilterService _filterService = FriendsFilterService();
  final FriendsDataService _cacheService = FriendsDataService();

  // 이미 불러온 요청 추적
  final Set<String> _loadedRequests = {};
  final Map<String, DateTime> _lastLoadTimes = {};

  bool _isTranslationsLoaded = false;
  bool _isDisposed = false;
  bool _isDistancesLoaded = false;
  String? _requestCity;
  String? _requestNationality;
  bool _isLoading = false;

  // 탭 이동 시 상태 보존을 위한 플래그
  bool _preserveStateOnReset = true;

  // Getters
  bool get isTranslationsLoaded => _isTranslationsLoaded;
  bool get isDisposed => _isDisposed;
  Query? get filteredQuery => _filterService.filteredQuery;
  bool get isDistancesLoaded => _isDistancesLoaded;
  Map<String, Set<String>> get selectedFilters => _filterService.selectedFilters;
  TranslationService get translationService => _translationService;
  bool get isFilterRefreshing => _filterService.isFilterRefreshing;
  bool get isLoading => _isLoading;

  // 탭 이동 시 상태 보존 설정
  set preserveStateOnReset(bool value) {
    _preserveStateOnReset = value;
  }

  bool get preserveStateOnReset => _preserveStateOnReset;

  // 이미 로드된 요청인지 확인
  bool isAlreadyLoaded(String requestId) {
    // 10초 내에 같은 요청을 다시 시도하는지 확인 (3초에서 10초로 증가)
    if (_lastLoadTimes.containsKey(requestId)) {
      final timeDiff = DateTime.now().difference(_lastLoadTimes[requestId]!).inSeconds;
      if (timeDiff < 10) {
        debugPrint('⚠️ 중복 로드 방지: $requestId (${timeDiff}초 전 로드됨)');
        return true;
      }
    }
    return false;
  }

  // 요청 로드 시작 추적
  void markRequestLoading(String requestId) {
    _loadedRequests.add(requestId);
    _lastLoadTimes[requestId] = DateTime.now();
    _isLoading = true;
    notifyListeners();
  }

  // 요청 로드 완료 추적
  void markRequestLoaded(String requestId) {
    _lastLoadTimes[requestId] = DateTime.now();
    _isLoading = false;
    notifyListeners();
  }

  // 초기화
  void initialize() {
    // 전역 컨트롤러에 저장
    globalFriendsListController ??= this;
    _loadTranslations();
    _isDistancesLoaded = true;
  }

  // 여행 위치 정보 설정
  void setLocationInfo(String? city, String? nationality) {
    _requestCity = city;
    _requestNationality = nationality;
    // 필터 서비스에 위치 정보 설정
    _filterService.setLocationFilter(city, nationality);
  }

  // 번역 로드
  Future<void> _loadTranslations() async {
    if (_isDisposed) return;
    await _translationService.loadTranslations();
    if (!_isDisposed) {
      _isTranslationsLoaded = true;
      notifyListeners();
    }
  }

  // 모든 캐시 및 상태 초기화
  void resetAllState() {
    // 탭 이동 시 상태 보존 설정이 활성화되어 있으면 데이터를 유지
    if (_preserveStateOnReset) {
      debugPrint('🔄 탭 이동: 상태 보존 모드 활성화됨 (데이터 유지)');
      return;
    }

    // 로드된 요청 추적 초기화
    _loadedRequests.clear();
    _lastLoadTimes.clear();
    _isLoading = false;

    // 캐시 초기화
    _cacheService.clearCache('', '');

    notifyListeners();
  }

  // 특정 요청 초기화
  void resetRequest(String requestId) {
    // 탭 이동 시 상태 보존 설정이 활성화되어 있으면 데이터를 유지
    if (_preserveStateOnReset) {
      debugPrint('🔄 탭 이동: 상태 보존 모드 활성화됨 (요청 데이터 유지)');
      return;
    }

    _loadedRequests.remove(requestId);
    _lastLoadTimes.remove(requestId);
    notifyListeners();
  }

  // 필터 적용
  Future<void> applyFilters(Query? query, Map<String, Set<String>> selectedFilters) async {
    if (_isDisposed) return;

    _isDistancesLoaded = false;
    notifyListeners();

    // 위치 정보가 있으면 필터 서비스에 설정
    if (_requestCity != null && _requestNationality != null) {
      _filterService.setLocationFilter(_requestCity, _requestNationality);
    }

    // 필터 서비스에 필터 상태 설정
    _filterService.setFilters(selectedFilters);

    // 필터가 변경되면 캐시 서비스에도 알림
    _cacheService.currentFilters = Map.from(selectedFilters);

    // 필터 변경 시 캐시는 유지하고 필터만 다시 적용
    debugPrint('🔍 필터 변경: 캐시는 유지하고 필터만 재적용');

    // 로드 상태 초기화
    _loadedRequests.clear();
    _lastLoadTimes.clear();

    // 필터 적용
    _filterService.applyFilters();

    _isDistancesLoaded = true;
    notifyListeners();
  }

  // 필터 제거
  Future<void> removeFilter(String category, String option) async {
    if (_isDisposed) return;

    _isDistancesLoaded = false;
    notifyListeners();

    // 필터 서비스에 필터 제거 요청
    _filterService.removeFilter(category, option);

    // 캐시 서비스에 필터 변경 알림
    _cacheService.currentFilters = Map.from(_filterService.selectedFilters);

    // 필터 변경 시 캐시는 유지하고 필터만 다시 적용
    debugPrint('🔍 필터 제거: 캐시는 유지하고 필터만 재적용');

    // 로드 상태 초기화
    _loadedRequests.clear();
    _lastLoadTimes.clear();

    _isDistancesLoaded = true;
    notifyListeners();
  }

  // 정렬된 친구 목록 가져오기
  List<Map<String, dynamic>> getSortedFriendsList(List<QueryDocumentSnapshot> docs) {
    // 각 친구 항목을 맵으로 변환
    List<Map<String, dynamic>> friendsList = [];
    for (var doc in docs) {
      final friendData = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      friendsList.add(friendData);
    }

    // 필터 서비스에서 정렬 및 필터링 실행
    return _filterService.getSortedFriendsList(friendsList);
  }

  // 컨트롤러 해제
  @override
  void dispose() {
    // 전역 컨트롤러인 경우 dispose하지 않음
    if (this == globalFriendsListController) {
      return;
    }

    _isDisposed = true;
    super.dispose();
  }
}