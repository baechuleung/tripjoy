// lib/tripfriends/friendslist/core/friends_state_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_model.dart';
import '../utils/data_transformer.dart';
import '../utils/filter_handler.dart';
import '../utils/shuffle_handler.dart';
import '../constants/filter_constants.dart';
import 'friends_repository.dart';
import 'friends_cache.dart';

/// 친구 목록의 모든 상태를 관리하는 통합 매니저
class FriendsStateManager with ChangeNotifier {
  // 싱글톤 인스턴스
  static FriendsStateManager? _instance;
  static FriendsStateManager get instance {
    _instance ??= FriendsStateManager._();
    return _instance!;
  }

  // 싱글톤 인스턴스 리셋 (plan_request 변경 시 사용)
  static void reset() {
    print('🔄 FriendsStateManager 싱글톤 인스턴스 리셋');
    _instance?.dispose();
    _instance = null;
  }

  FriendsStateManager._() {
    _repository = FriendsRepository();
    // 캐시 제거 - 더 이상 사용하지 않음
  }

  // 의존성
  late final FriendsRepository _repository;

  // 상태 변수들
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;

  // 위치 정보
  String? _requestDocId;
  String? _requestCity;
  String? _requestNationality;

  // 필터 상태
  Map<String, Set<String>> _selectedFilters = {};
  String _currentSortType = 'none';
  bool _shuffleEnabled = true;

  // 데이터 - 캐시 없이 매번 새로
  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _displayFriends = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  List<Map<String, dynamic>> get displayFriends => List.from(_displayFriends); // 복사본 반환
  Map<String, Set<String>> get selectedFilters => Map.unmodifiable(_selectedFilters);
  String? get requestCity => _requestCity;
  String? get requestNationality => _requestNationality;

  /// 초기화 - plan_request가 변경되면 모든 상태 리셋
  Future<void> initialize() async {
    try {
      _setLoading(true);

      // 이전 상태 완전히 초기화
      _allFriends.clear();
      _displayFriends.clear();
      _selectedFilters.clear();
      _currentSortType = 'none';
      _shuffleEnabled = true;
      _hasError = false;
      _errorMessage = '';

      await _loadPlanRequest();
      _isInitialized = true;

      print('✅ FriendsStateManager 초기화 완료 - 위치: $_requestCity/$_requestNationality');
    } catch (e) {
      _setError(e.toString());
      _isInitialized = false;
    } finally {
      _setLoading(false);
    }
  }

  /// plan_request 정보 로드
  Future<void> _loadPlanRequest() async {
    final requestInfo = await _repository.loadPlanRequest();

    // 이전 위치 정보 저장
    final previousCity = _requestCity;
    final previousNationality = _requestNationality;

    _requestDocId = requestInfo['docId'];
    _requestCity = requestInfo['city'];
    _requestNationality = requestInfo['nationality'];

    // 위치가 변경되었으면 캐시와 데이터 초기화
    if (previousCity != _requestCity || previousNationality != _requestNationality) {
      print('🔄 위치 변경 감지: $previousCity/$previousNationality → $_requestCity/$_requestNationality');
      _clearAllData();
    }
  }

  /// 모든 데이터 초기화
  void _clearAllData() {
    print('🧹 모든 데이터 초기화');
    _allFriends.clear();
    _displayFriends.clear();
    notifyListeners();
  }

  /// 친구 데이터 로드
  Future<void> loadFriends({List<String>? specificIds, bool forceRefresh = false}) async {
    if (!_isInitialized) await initialize();

    try {
      _setLoading(true);

      List<Map<String, dynamic>> friends;
      if (specificIds != null) {
        friends = await _repository.loadFriendsByIds(
            specificIds,
            _requestCity!,
            _requestNationality!
        );
      } else {
        friends = await _repository.loadAllFriends(
            _requestCity!,
            _requestNationality!
        );
      }

      _allFriends = friends;
      _applyFiltersAndSort();

    } catch (e) {
      _setError('데이터를 불러오는 중 오류가 발생했습니다.');
    } finally {
      _setLoading(false);
    }
  }

  /// 친구 데이터 스트림으로 로드 - 한 개씩 실시간 처리
  Stream<List<Map<String, dynamic>>> loadFriendsStream({List<String>? specificIds}) async* {
    print('FriendsStateManager: loadFriendsStream 시작 - specificIds: ${specificIds?.length ?? 0}개');
    print('FriendsStateManager: 요청 위치 - $_requestCity, $_requestNationality');

    if (!_isInitialized) {
      print('FriendsStateManager: 초기화 필요');
      await initialize();
    }

    if (_requestCity == null || _requestNationality == null) {
      print('FriendsStateManager: 위치 정보 없음');
      yield [];
      return;
    }

    // 리스트 초기화 - 매번 새로 시작
    _allFriends.clear();
    _displayFriends.clear();

    // 즉시 빈 리스트 전송하여 UI 초기화
    yield [];

    try {
      _setLoading(true);

      // 기본 쿼리 생성 (위치 조건 명확히 지정)
      Query query = FirebaseFirestore.instance
          .collection('tripfriends_users')
          .where('location.city', isEqualTo: _requestCity)
          .where('location.nationality', isEqualTo: _requestNationality);

      print('🔍 쿼리 조건: city=$_requestCity, nationality=$_requestNationality');

      // 한 개씩 스트리밍으로 가져와서 처리
      await for (final friend in _repository.loadAllFriendsOneByOne(query, specificIds: specificIds)) {
        // 위치 재확인 (중요!)
        final friendLocation = friend['location'] as Map<String, dynamic>?;
        if (friendLocation != null) {
          final friendCity = friendLocation['city'] as String?;
          final friendNationality = friendLocation['nationality'] as String?;

          // 위치가 일치하지 않으면 스킵
          if (friendCity != _requestCity || friendNationality != _requestNationality) {
            print('❌ 위치 불일치 스킵: ${friend['name']} - $friendCity/$friendNationality (요청: $_requestCity/$_requestNationality)');
            continue;
          }
        } else {
          print('❌ 위치 정보 없음 스킵: ${friend['name']}');
          continue;
        }

        // 유효성 검사
        if (!DataTransformer.isValidFriend(friend)) {
          print('❌ 유효하지 않은 친구 스킵: ${friend['name']} (isActive=${friend['isActive']}, isApproved=${friend['isApproved']})');
          continue;
        }

        // 원본 데이터 추가
        _allFriends.add(friend);

        // 필터 적용 확인
        bool passedFilter = true;

        // 성별 필터
        final genderFilter = _selectedFilters[FilterConstants.GENDER];
        if (genderFilter != null && genderFilter.isNotEmpty && !genderFilter.contains('전체')) {
          final expectedGender = FilterConstants.getGenderCode(genderFilter.first);
          if ((friend['gender'] as String?)?.toLowerCase() != expectedGender.toLowerCase()) {
            passedFilter = false;
          }
        }

        // 언어 필터
        if (passedFilter) {
          final languageFilter = _selectedFilters[FilterConstants.LANGUAGE];
          if (languageFilter != null && languageFilter.isNotEmpty && !languageFilter.contains('상관없음')) {
            final languageCode = FilterConstants.getLanguageCode(languageFilter.first);
            final languages = friend['languages'] as List<dynamic>? ?? [];
            if (!languages.contains(languageCode)) {
              passedFilter = false;
            }
          }
        }

        // 필터를 통과한 경우만 표시 목록에 추가
        if (passedFilter) {
          _displayFriends.add(friend);

          // 정렬 적용
          _applyCurrentSort();

          print('✅ 친구 추가: ${friend['name']} - ${friendLocation?['city']}/${friendLocation?['nationality']} (총 ${_displayFriends.length}명)');

          // 매번 업데이트된 리스트 전송
          yield List.from(_displayFriends);
        } else {
          print('🔍 필터에 걸림: ${friend['name']}');
        }
      }

      // 최종 정렬/셔플 적용
      _applyCurrentSort();
      yield List.from(_displayFriends);

    } catch (e) {
      print('FriendsStateManager: 오류 발생 - $e');
      _setError('데이터를 불러오는 중 오류가 발생했습니다.');
      yield _displayFriends;
    } finally {
      _setLoading(false);
      print('FriendsStateManager: 로딩 완료 - 총 ${_displayFriends.length}명');
    }
  }

  /// 현재 정렬 방식 적용
  void _applyCurrentSort() {
    if (_currentSortType != 'none') {
      _displayFriends = FilterHandler.sortFriends(_displayFriends, _currentSortType);
    } else if (_shuffleEnabled && _requestDocId != null) {
      // 셔플은 마지막에 한 번만 적용하거나 필요시 적용
      // 매번 셔플하면 순서가 계속 바뀌므로 주의
    }
  }

  /// 필터 적용
  void applyFilters(Map<String, Set<String>> filters) {
    _selectedFilters = Map.from(filters);
    _updateSortType();
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 필터 토글
  void toggleFilter(String category, String option, bool selected) {
    if (!_selectedFilters.containsKey(category)) {
      _selectedFilters[category] = {};
    }

    if (selected) {
      _selectedFilters[category]!.clear();
      _selectedFilters[category]!.add(option);
    } else {
      _selectedFilters[category]!.remove(option);
    }

    _updateSortType();
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 필터 제거
  void removeFilter(String category, String option) {
    _selectedFilters[category]?.remove(option);
    _updateSortType();
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 필터 초기화
  void resetFilters() {
    _selectedFilters.clear();
    _currentSortType = 'none';
    _shuffleEnabled = true;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 필터 및 정렬 적용
  void _applyFiltersAndSort() {
    if (_allFriends.isEmpty) {
      _displayFriends = [];
      return;
    }

    // 1. 유효한 친구만 필터링
    var filtered = _allFriends.where((friend) =>
        DataTransformer.isValidFriend(friend)
    ).toList();

    // 2. 선택된 필터 적용
    filtered = FilterHandler.applyFilters(filtered, _selectedFilters);

    // 3. 정렬 적용
    filtered = FilterHandler.sortFriends(filtered, _currentSortType);

    // 4. 셔플 적용 (정렬이 없을 때만)
    if (_shuffleEnabled && _currentSortType == 'none' && _requestDocId != null) {
      filtered = ShuffleHandler.shuffleList(filtered, _requestDocId!);
    }

    _displayFriends = filtered;

    // 에러 상태 업데이트
    if (_displayFriends.isEmpty && _allFriends.isNotEmpty) {
      _setError('필터 조건에 맞는 프렌즈가 없습니다.');
    } else if (_displayFriends.isEmpty) {
      _setError('현재 추천할 프렌즈가 없습니다.');
    } else {
      _clearError();
    }
  }

  /// 정렬 타입 업데이트
  void _updateSortType() {
    _currentSortType = FilterHandler.getSortTypeFromFilters(_selectedFilters);
    _shuffleEnabled = _currentSortType == 'none';
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 에러 설정
  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  /// 에러 클리어
  void _clearError() {
    _hasError = false;
    _errorMessage = '';
  }

  /// 캐시 클리어 - 더 이상 캐시를 사용하지 않음
  void clearCache() {
    print('🧹 데이터 클리어');
    _allFriends.clear();
    _displayFriends.clear();
    notifyListeners();
  }

  /// 리소스 정리
  void dispose() {
    super.dispose();
  }
}