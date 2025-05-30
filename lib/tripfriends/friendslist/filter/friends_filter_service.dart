// lib/tripfriends/friendslist/filter/friends_filter_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'filter_constants.dart';

/// 필터 로직을 중앙 집중화한 서비스 클래스
class FriendsFilterService with ChangeNotifier {
  // 싱글톤 패턴 구현
  static final FriendsFilterService _instance = FriendsFilterService._internal();
  factory FriendsFilterService() => _instance;
  FriendsFilterService._internal() {
    _initFilters();
  }

  // 필터 선택 상태를 관리하는 맵
  final Map<String, Set<String>> _selectedFilters = {};
  Map<String, Set<String>> get selectedFilters => _selectedFilters;

  // 쿼리 결과
  Query? _filteredQuery;
  Query? get filteredQuery => _filteredQuery;

  // 여행 위치 정보
  String? _requestCity;
  String? _requestNationality;

  // 상태 관리
  bool _isFilterRefreshing = false;
  bool _isDisposed = false;
  String _currentSortType = 'rating_high';

  bool get isFilterRefreshing => _isFilterRefreshing;
  bool get isDisposed => _isDisposed;
  String get currentSortType => _currentSortType;
  Map<String, List<String>> get filterOptions => FilterConstants.filterOptions;

  // 초기화
  void _initFilters() {
    final initialState = FilterConstants.getInitialFilterState();
    initialState.forEach((key, value) {
      _selectedFilters[key] = value;
    });
  }

  // 위치 정보 설정
  void setLocationFilter(String? city, String? nationality) {
    _requestCity = city;
    _requestNationality = nationality;
  }

  // 필터 적용 함수 - 데이터베이스 쿼리 생성
  Query applyFilters() {
    _isFilterRefreshing = true;
    notifyListeners();

    // 기본 쿼리 설정 - isActive와 isApproved 조건 제거
    Query query = FirebaseFirestore.instance
        .collection('tripfriends_users');

    // 위치 필터가 설정되어 있으면 적용
    if (_requestCity != null && _requestNationality != null) {
      query = query.where('location.city', isEqualTo: _requestCity)
          .where('location.nationality', isEqualTo: _requestNationality);
    }

    // 성별 필터 적용
    final genderFilters = _selectedFilters[FilterConstants.GENDER];
    if (genderFilters != null && genderFilters.isNotEmpty && genderFilters.first != '전체') {
      String gender = FilterConstants.getGenderCode(genderFilters.first);
      query = query.where('gender', isEqualTo: gender);
    }

    // 언어 필터 적용
    final languageFilters = _selectedFilters[FilterConstants.LANGUAGE];
    if (languageFilters != null && languageFilters.isNotEmpty &&
        !languageFilters.contains('상관없음')) {
      // 단일 언어만 적용
      String languageCode = FilterConstants.getLanguageCode(languageFilters.first);
      if (languageCode.isNotEmpty) {
        query = query.where('languages', arrayContains: languageCode);
      }
    }

    // 별점 필터 적용 - orderBy는 마지막에 한번만 적용 (인덱스 문제 방지)
    final ratingFilters = _selectedFilters[FilterConstants.RATING];

    // 기본적으로 내림차순 (별점 높은 순)으로 설정하고 필터에 따라 변경
    bool descendingOrder = true;
    bool hasExplicitSorting = false; // 명시적 정렬이 있는지 확인

    if (ratingFilters != null && ratingFilters.isNotEmpty && ratingFilters.first != '상관없음') {
      hasExplicitSorting = true;
      if (ratingFilters.first == '별점 높은 순') {
        _currentSortType = 'rating_high';
        descendingOrder = true;
      } else if (ratingFilters.first == '별점 낮은 순') {
        _currentSortType = 'rating_low';
        descendingOrder = false;
      } else {
        _currentSortType = 'none';
        hasExplicitSorting = false;
      }
    } else {
      // 별점 필터가 없으면 정렬 타입을 none으로 설정
      _currentSortType = 'none';
    }

    // 명시적 정렬이 있을 때만 orderBy 적용
    if (hasExplicitSorting) {
      query = query.orderBy('average_rating', descending: descendingOrder);
    }

    // 매칭 횟수 필터는 클라이언트 측에서 정렬
    final matchCountFilters = _selectedFilters[FilterConstants.MATCH_COUNT];
    if (matchCountFilters != null && matchCountFilters.isNotEmpty &&
        matchCountFilters.first != '상관없음') {
      if (matchCountFilters.first == '매칭 횟수 많은 순') {
        _currentSortType = 'match_high';
      } else if (matchCountFilters.first == '매칭 횟수 적은 순') {
        _currentSortType = 'match_low';
      }
    }

    _filteredQuery = query;
    _isFilterRefreshing = false;
    notifyListeners();

    return query;
  }

  // 필터 옵션 추가/제거
  void toggleFilter(String category, String option, bool selected) {
    // category가 없으면 초기화
    if (!_selectedFilters.containsKey(category)) {
      _selectedFilters[category] = <String>{};
    }

    if (selected) {
      // 같은 카테고리의 이전 선택 지우기 (라디오 버튼처럼 동작)
      _selectedFilters[category]!.clear();
      _selectedFilters[category]!.add(option);

      // 정렬 관련 필터인 경우 현재 정렬 타입 업데이트
      if (category == FilterConstants.RATING) {
        if (option == '별점 높은 순') {
          _currentSortType = 'rating_high';
        } else if (option == '별점 낮은 순') {
          _currentSortType = 'rating_low';
        } else {
          _currentSortType = 'none';
        }
      } else if (category == FilterConstants.MATCH_COUNT) {
        if (option == '매칭 횟수 많은 순') {
          _currentSortType = 'match_high';
        } else if (option == '매칭 횟수 적은 순') {
          _currentSortType = 'match_low';
        } else {
          _currentSortType = 'none';
        }
      }
    } else {
      _selectedFilters[category]!.remove(option);

      // 정렬 관련 필터 제거시 기본값으로 설정
      if ((category == FilterConstants.RATING || category == FilterConstants.MATCH_COUNT) &&
          _selectedFilters[category]!.isEmpty) {
        _currentSortType = 'rating_high'; // 기본 정렬은 별점 높은 순
      }
    }

    notifyListeners();
  }

  // 특정 필터 제거
  void removeFilter(String category, String option) {
    _isFilterRefreshing = true;
    notifyListeners();

    // category가 있는지 확인
    if (_selectedFilters.containsKey(category)) {
      _selectedFilters[category]!.remove(option);

      // 정렬 관련 필터 제거시 none으로 설정
      if (category == FilterConstants.RATING) {
        _currentSortType = 'none'; // 필터 제거 시 정렬 없음
      } else if (category == FilterConstants.MATCH_COUNT) {
        _currentSortType = 'none'; // 필터 제거 시 정렬 없음
      }
    }

    // 쿼리 갱신
    applyFilters();

    _isFilterRefreshing = false;
    notifyListeners();
  }

  // 필터 초기화
  void resetFilters() {
    _isFilterRefreshing = true;
    notifyListeners();

    // 모든 필터 완전히 초기화
    _selectedFilters.clear();

    // 각 카테고리별로 빈 Set 재설정
    _selectedFilters[FilterConstants.RATING] = <String>{};
    _selectedFilters[FilterConstants.LANGUAGE] = <String>{};
    _selectedFilters[FilterConstants.GENDER] = <String>{};
    _selectedFilters[FilterConstants.MATCH_COUNT] = <String>{};

    _currentSortType = 'none'; // 기본 정렬을 none으로 설정

    // 쿼리 갱신
    applyFilters();

    _isFilterRefreshing = false;
    notifyListeners();

    debugPrint('🧹 필터 초기화 완료 - 모든 필터 제거됨');
  }

  // 클라이언트 측 필터링 로직
  List<Map<String, dynamic>> applyClientSideFilters(
      List<Map<String, dynamic>> friends) {

    // 입력 데이터가 비어있으면 바로 반환
    if (friends.isEmpty) {
      return friends;
    }

    // 필터가 없으면 모든 친구 반환
    if (_selectedFilters.isEmpty ||
        _selectedFilters.values.every((options) => options.isEmpty)) {
      debugPrint('🔍 필터 없음 - 모든 친구 반환');
      return friends;
    }

    // 현재 선택된 필터 로깅
    debugPrint('🔍 현재 선택된 필터:');
    _selectedFilters.forEach((category, options) {
      if (options.isNotEmpty) {
        debugPrint('  - $category: ${options.join(', ')}');
      }
    });

    // isActive와 isApproved 상태 검증 - 필드가 없으면 기본값 적용
    List<Map<String, dynamic>> preFiltered = friends.where((friend) {
      // isActive가 없으면 true로 간주
      final bool isActive = friend.containsKey('isActive') ? friend['isActive'] == true : true;
      // isApproved가 없으면 true로 간주
      final bool isApproved = friend.containsKey('isApproved') ? friend['isApproved'] == true : true;

      if (!isActive || !isApproved) {
        final uid = friend['uid'] ?? friend['id'] ?? 'unknown';
        debugPrint('❌ 필터링됨: $uid (isActive=$isActive, isApproved=$isApproved)');
      }

      return isActive && isApproved;
    }).toList();

    debugPrint('🔍 사전 필터링 후: ${preFiltered.length}명 (isActive && isApproved)');

    // 필터링된 친구 목록 생성
    List<Map<String, dynamic>> result = preFiltered.where((friend) {
      final uid = friend['uid'] ?? friend['id'] ?? 'unknown';

      // 성별 필터 적용
      final genderFilters = _selectedFilters[FilterConstants.GENDER];
      if (genderFilters != null && genderFilters.isNotEmpty && genderFilters.first != '전체') {
        String expectedGender = FilterConstants.getGenderCode(genderFilters.first);
        String friendGender = (friend['gender'] as String?)?.toLowerCase() ?? '';

        if (friendGender != expectedGender.toLowerCase()) {
          debugPrint('❌ 성별 필터로 제외: $uid (기대: $expectedGender, 실제: $friendGender)');
          return false;
        }
      }

      // 언어 필터 적용
      final languageFilters = _selectedFilters[FilterConstants.LANGUAGE];
      if (languageFilters != null && languageFilters.isNotEmpty &&
          !languageFilters.contains('상관없음')) {
        String languageCode = FilterConstants.getLanguageCode(languageFilters.first);
        List<dynamic> languages = friend['languages'] ?? [];

        debugPrint('🔍 언어 필터 확인 - $uid:');
        debugPrint('  - 선택된 언어: ${languageFilters.first} (코드: $languageCode)');
        debugPrint('  - 친구의 언어: ${languages.join(', ')}');

        if (!languages.contains(languageCode)) {
          debugPrint('❌ 언어 필터로 제외: $uid');
          return false;
        } else {
          debugPrint('✅ 언어 필터 통과: $uid');
        }
      }

      return true;
    }).toList();

    debugPrint('🔍 최종 필터링 결과: ${result.length}명');

    return result;
  }

  // 정렬 로직 - null 값에 대해 적절히 처리
  List<Map<String, dynamic>> getSortedFriendsList(List<Map<String, dynamic>> friends) {
    // 빈 목록이면 그대로 반환
    if (friends.isEmpty) {
      return friends;
    }

    List<Map<String, dynamic>> sortedList = List.from(friends);

    // 먼저 average_rating이 null인 항목을 보정
    for (var i = 0; i < sortedList.length; i++) {
      if (sortedList[i]['average_rating'] == null) {
        sortedList[i]['average_rating'] = 0.0;
      }
    }

    switch (_currentSortType) {
      case 'match_high':
        sortedList.sort((a, b) {
          int countA = a['match_count'] ?? 0;
          int countB = b['match_count'] ?? 0;
          return countB.compareTo(countA); // 내림차순 (많은 순)
        });
        break;

      case 'match_low':
        sortedList.sort((a, b) {
          int countA = a['match_count'] ?? 0;
          int countB = b['match_count'] ?? 0;
          return countA.compareTo(countB); // 오름차순 (적은 순)
        });
        break;

      case 'rating_low':
        sortedList.sort((a, b) {
          double ratingA = safeParseDouble(a['average_rating']);
          double ratingB = safeParseDouble(b['average_rating']);
          return ratingA.compareTo(ratingB); // 오름차순 (낮은 순)
        });
        break;

      case 'rating_high':
        sortedList.sort((a, b) {
          double ratingA = safeParseDouble(a['average_rating']);
          double ratingB = safeParseDouble(b['average_rating']);
          int result = ratingB.compareTo(ratingA); // 내림차순 (높은 순)
          return result;
        });
        break;

      case 'none':
      default:
      // 정렬하지 않고 그대로 반환
        break;
    }

    return sortedList;
  }

  // 값을 double 형태로 변환하는 안전한 함수
  double safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    // 다른 타입인 경우에도 안전하게 0.0 반환
    return 0.0;
  }

  // 필터 상태 설정 (외부에서 상태 복원 시 사용)
  void setFilters(Map<String, Set<String>> filters) {
    // 초기화하지 않고 기존 필터 상태 유지
    if (filters.isEmpty) {
      return; // 빈 필터가 전달되면 아무것도 하지 않음 (기존 상태 유지)
    }

    // 전달된 필터로 설정 - 기존 필터를 지우지 않고 업데이트
    filters.forEach((key, value) {
      if (value.isNotEmpty) {
        _selectedFilters[key] = Set<String>.from(value);
      }
    });

    // 정렬 타입 업데이트
    _updateCurrentSortType();
    notifyListeners();
  }

  // 현재 필터 상태 복사본 가져오기
  Map<String, Set<String>> getFiltersCopy() {
    final copy = Map<String, Set<String>>.fromEntries(
        _selectedFilters.entries.map(
                (entry) => MapEntry(entry.key, Set<String>.from(entry.value))
        )
    );
    return copy;
  }

  // 정렬 타입 업데이트
  void _updateCurrentSortType() {
    // 매칭 횟수 필터 확인
    final matchCountFilters = _selectedFilters[FilterConstants.MATCH_COUNT];
    if (matchCountFilters != null && matchCountFilters.isNotEmpty &&
        matchCountFilters.first != '상관없음') {
      if (matchCountFilters.first == '매칭 횟수 많은 순') {
        _currentSortType = 'match_high';
        return;
      } else if (matchCountFilters.first == '매칭 횟수 적은 순') {
        _currentSortType = 'match_low';
        return;
      }
    }

    // 별점 필터 확인
    final ratingFilters = _selectedFilters[FilterConstants.RATING];
    if (ratingFilters != null && ratingFilters.isNotEmpty &&
        ratingFilters.first != '상관없음') {
      if (ratingFilters.first == '별점 높은 순') {
        _currentSortType = 'rating_high';
        return;
      } else if (ratingFilters.first == '별점 낮은 순') {
        _currentSortType = 'rating_low';
        return;
      }
    }

    // 기본값 - 정렬 없음
    _currentSortType = 'none';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}