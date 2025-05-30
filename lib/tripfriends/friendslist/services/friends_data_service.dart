// lib/tripfriends/friendslist/services/friends_data_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../filter/friends_filter_service.dart';
import 'dart:async'; // 타이머 추가

class FriendsDataService {
  // 싱글톤 패턴
  static final FriendsDataService _instance = FriendsDataService._internal();
  factory FriendsDataService() => _instance;
  FriendsDataService._internal();

  // 필터 서비스 인스턴스
  final FriendsFilterService _filterService = FriendsFilterService();

  // 캐시 및 페이지네이션 관련 변수
  final Map<String, List<Map<String, dynamic>>> _cachedData = {};
  final Map<String, DocumentSnapshot?> _lastDocuments = {};
  final Map<String, bool> _hasMoreData = {};
  final int _pageSize = 10000; // 페이지 사이즈를 20으로 유지하여 대용량 데이터 처리
  bool _isLoading = false;
  Map<String, Set<String>> _currentFilters = {};

  // 특정 요청이 로딩 중인지 추적하는 Map
  final Map<String, bool> _requestLoading = {};

  // 로드 타임아웃을 추적하는 Map
  final Map<String, Timer> _loadTimeoutTimers = {};

  // 타임아웃 발생 여부를 추적하는 Map
  final Map<String, bool> _requestTimedOut = {};

  // 이미 로드를 시도했던 키를 추적하는 Set - 무한 로딩 방지용
  final Set<String> _attemptedLoads = {};

  // 타임아웃 시간 설정 (60초로 증가)
  static const int _timeoutSeconds = 60;

  // 캐시 지속성 관리 - 앱이 실행되는 동안 유지
  bool _isCacheInitialized = false;

  // Getters
  bool get isLoading => _isLoading;
  Map<String, Set<String>> get currentFilters => _currentFilters;
  set currentFilters(Map<String, Set<String>> filters) {
    _currentFilters = filters;
  }

  bool get isCacheInitialized => _isCacheInitialized;
  set isCacheInitialized(bool value) {
    _isCacheInitialized = value;
  }

  // 요청의 타임아웃 여부 확인
  bool isRequestTimedOut(String requestId, String listType) {
    final cacheKey = '${requestId}_${listType}';
    return _requestTimedOut[cacheKey] == true;
  }

  // 캐시 관리 함수
  void setData(String key, List<Map<String, dynamic>> data) {
    _cachedData[key] = data;
    _isCacheInitialized = true;
  }

  List<Map<String, dynamic>>? getData(String key) {
    if (_cachedData.containsKey(key)) {
      return _cachedData[key];
    }
    return null;
  }

  bool hasData(String key) {
    return _cachedData.containsKey(key) && (_cachedData[key]?.isNotEmpty ?? false);
  }

  List<Map<String, dynamic>> getFriendsData(String requestId, String listType) {
    final cacheKey = '${requestId}_${listType}';
    return getData(cacheKey) ?? [];
  }

  bool hasCachedData(String requestId, String listType) {
    final cacheKey = '${requestId}_${listType}';
    return hasData(cacheKey);
  }

  bool hasMoreData(String requestId, String listType) {
    final cacheKey = '${requestId}_${listType}';
    return _hasMoreData[cacheKey] ?? true;
  }

  void setHasMoreData(String requestId, String listType, bool value) {
    final cacheKey = '${requestId}_${listType}';
    _hasMoreData[cacheKey] = value;
  }

  // 캐시 초기화 - 필요한 경우에만 호출
  void clearCache(String requestId, String listType) {
    final cacheKey = requestId.isEmpty && listType.isEmpty ? '' : '${requestId}_${listType}';

    debugPrint('🧹 캐시 초기화 요청: $cacheKey');

    if (cacheKey.isEmpty) {
      debugPrint('🧹 모든 캐시 초기화');
      _cachedData.clear();
      _lastDocuments.clear();
      _hasMoreData.clear();
      _requestLoading.clear();
      _cancelAllTimeoutTimers(); // 모든 타임아웃 타이머 취소
      _requestTimedOut.clear(); // 타임아웃 상태 초기화
      _attemptedLoads.clear(); // 추가: 로드 시도 추적 초기화
      _isCacheInitialized = false;
    } else {
      debugPrint('🧹 특정 캐시 초기화: $cacheKey');
      _cachedData.remove(cacheKey);
      _lastDocuments.remove(cacheKey);
      _hasMoreData[cacheKey] = true;
      _requestLoading.remove(cacheKey);
      _cancelTimeoutTimer(cacheKey); // 해당 요청의 타임아웃 타이머 취소
      _requestTimedOut.remove(cacheKey); // 타임아웃 상태 초기화
      _attemptedLoads.remove(cacheKey); // 추가: 로드 시도 추적 초기화
    }
  }

  // 타임아웃 타이머 취소
  void _cancelTimeoutTimer(String cacheKey) {
    if (_loadTimeoutTimers.containsKey(cacheKey)) {
      _loadTimeoutTimers[cacheKey]?.cancel();
      _loadTimeoutTimers.remove(cacheKey);
      debugPrint('⏱️ 타임아웃 타이머 취소: $cacheKey');
    }
  }

  // 모든 타임아웃 타이머 취소
  void _cancelAllTimeoutTimers() {
    for (var timer in _loadTimeoutTimers.values) {
      timer.cancel();
    }
    _loadTimeoutTimers.clear();
    debugPrint('⏱️ 모든 타임아웃 타이머 취소');
  }

  // 로딩 상태 강제 초기화
  void forceFinishLoading() {
    _isLoading = false;
    _requestLoading.clear();
    _cancelAllTimeoutTimers(); // 모든 타임아웃 타이머 취소
    debugPrint('🧹 로딩 상태 강제 초기화: _isLoading = false');
  }

  // 특정 요청이 로딩 중인지 확인
  bool isRequestLoading(String cacheKey) {
    return _requestLoading[cacheKey] == true;
  }

  // 로딩 상태 설정 및 타임아웃 타이머 설정
  void markRequestLoading(String requestId, String listType) {
    final cacheKey = '${requestId}_${listType}';
    _requestLoading[cacheKey] = true;
    _requestTimedOut[cacheKey] = false; // 타임아웃 상태 초기화

    // 기존 타이머가 있으면 취소
    _cancelTimeoutTimer(cacheKey);

    // 타임아웃 타이머 설정 (60초)
    _loadTimeoutTimers[cacheKey] = Timer(const Duration(seconds: _timeoutSeconds), () {
      debugPrint('⏱️ 데이터 로드 타임아웃 발생: $cacheKey');
      _requestTimedOut[cacheKey] = true;
      _requestLoading[cacheKey] = false;
      _isLoading = false;
    });

    _isLoading = true;
    debugPrint('🔄 요청 로딩 시작: $cacheKey (${_timeoutSeconds}초 타임아웃 타이머 설정)');
  }

  // 요청 로드 완료 추적
  void markRequestLoaded(String requestId, String listType) {
    final cacheKey = '${requestId}_${listType}';
    _requestLoading[cacheKey] = false;

    // 타임아웃 타이머 취소
    _cancelTimeoutTimer(cacheKey);

    _isLoading = false;
    debugPrint('✅ 요청 로딩 완료: $cacheKey');
  }

  // 로드 시도 여부 확인 및 설정
  bool hasAttemptedLoad(String cacheKey) {
    return _attemptedLoads.contains(cacheKey);
  }

  void markLoadAttempted(String cacheKey) {
    _attemptedLoads.add(cacheKey);
  }

  // Firestore에서 친구 데이터 로드 - 스트림 방식
  Stream<List<Map<String, dynamic>>> loadFriendsStream(
      Query baseQuery,
      String requestId,
      String listType,
      {bool forceRefresh = false}) async* {
    final cacheKey = '${requestId}_${listType}';
    final List<Map<String, dynamic>> allData = [];

    // 캐시가 있고 forceRefresh가 아니면 캐시 먼저 전송
    if (!forceRefresh && hasData(cacheKey)) {
      yield getData(cacheKey) ?? [];
      return;
    }

    // 로딩 시작
    markRequestLoading(requestId, listType);
    markLoadAttempted(cacheKey);

    try {
      // 배치 크기 설정 (한 번에 50개씩)
      const int batchSize = 50;
      DocumentSnapshot? lastDoc;
      bool hasMore = true;

      while (hasMore) {
        Query query = baseQuery.limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final querySnapshot = await query.get();
        final docs = querySnapshot.docs;

        if (docs.isEmpty) {
          hasMore = false;
          break;
        }

        if (docs.length < batchSize) {
          hasMore = false;
        }

        lastDoc = docs.isNotEmpty ? docs.last : null;

        // 각 배치 처리
        for (var doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;

            if (data.containsKey('average_rating')) {
              data['average_rating'] = _filterService.safeParseDouble(data['average_rating']);
            } else {
              data['average_rating'] = 0.0;
            }

            allData.add(data);
          } catch (e) {
            debugPrint('⚠️ 친구 데이터 처리 오류: $e');
          }
        }

        // 정렬 후 스트림으로 전송
        _sortDataByRating(allData);
        setData(cacheKey, List.from(allData));
        yield List.from(allData);

        // UI 업데이트를 위한 짧은 딜레이
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _hasMoreData[cacheKey] = false;
      _isCacheInitialized = true;

    } catch (e) {
      debugPrint('❌ 데이터 로드 오류: $e');
      if (!hasData(cacheKey)) {
        setData(cacheKey, []);
        _hasMoreData[cacheKey] = false;
      }
      yield getData(cacheKey) ?? [];
    } finally {
      markRequestLoaded(requestId, listType);
    }
  }

  // 기존 loadMoreFriends 메서드는 스트림의 마지막 값만 반환하도록 수정
  Future<List<Map<String, dynamic>>> loadMoreFriends(
      Query baseQuery,
      String requestId,
      String listType,
      {bool forceRefresh = false}) async {
    final cacheKey = '${requestId}_${listType}';

    // 이미 로딩 중인 경우 캐시된 데이터 반환 (중복 요청 방지)
    if (isRequestLoading(cacheKey)) {
      debugPrint('🔄 이미 로딩 중: $cacheKey - 캐시된 데이터 반환');
      return getData(cacheKey) ?? [];
    }

    // 타임아웃이 발생한 경우 재시도 또는 캐시된 데이터 반환
    if (_requestTimedOut[cacheKey] == true && !forceRefresh) {
      debugPrint('⏱️ 타임아웃 발생한 요청: $cacheKey');
      // 캐시된 데이터가 있으면 반환
      if (hasData(cacheKey)) {
        debugPrint('📦 타임아웃 발생했지만 캐시된 데이터 사용');
        return getData(cacheKey) ?? [];
      }
      // 캐시가 없으면 재시도
      _requestTimedOut[cacheKey] = false;
      debugPrint('🔄 타임아웃 후 재시도');
    }

    // 캐시 체크 - forceRefresh가 false이고 캐시된 데이터가 있는 경우
    if (!forceRefresh && hasData(cacheKey)) {
      debugPrint('📦 캐시된 데이터 사용 (loadMoreFriends): $cacheKey');
      return getData(cacheKey) ?? [];
    }

    // 더 로드할 데이터가 없는 경우 캐시된 데이터 반환
    if (!forceRefresh && !(hasMoreData(requestId, listType))) {
      debugPrint('🛑 더 로드할 데이터 없음: $cacheKey');

      // 빈 데이터면 hasMoreData를 false로 설정하고 빈 배열 반환
      if (!hasData(cacheKey) || (hasData(cacheKey) && (getData(cacheKey)?.isEmpty ?? true))) {
        _hasMoreData[cacheKey] = false;
        setData(cacheKey, []);
      }

      return getData(cacheKey) ?? [];
    }

    // 이미 로드를 시도했고 빈 결과를 가진 경우 재시도 방지
    if (!forceRefresh && hasAttemptedLoad(cacheKey) && hasData(cacheKey) && (getData(cacheKey)?.isEmpty ?? true)) {
      debugPrint('🛑 이미 로드 시도했고 빈 결과: $cacheKey');
      _hasMoreData[cacheKey] = false;
      return getData(cacheKey) ?? [];
    }

    // 로딩 상태 설정 및 타임아웃 타이머 설정
    markRequestLoading(requestId, listType);
    markLoadAttempted(cacheKey); // 로드 시도 표시
    debugPrint('🔄 로딩 시작 (loadMoreFriends): $cacheKey, _isLoading = true');

    try {
      // 페이지네이션 쿼리 설정
      Query query = baseQuery.limit(_pageSize);

      // forceRefresh가 true면 처음부터 로드, 아니면 이전 페이지 이후부터 로드
      if (!forceRefresh && _lastDocuments[cacheKey] != null) {
        query = query.startAfterDocument(_lastDocuments[cacheKey]!);
      } else if (forceRefresh) {
        // forceRefresh가 true이면 캐시 및 lastDocument 초기화
        _cachedData.remove(cacheKey);
        _lastDocuments.remove(cacheKey);
      }

      // 쿼리 실행
      final querySnapshot = await query.get();
      final docs = querySnapshot.docs;

      // 결과 처리
      if (docs.isEmpty) {
        _hasMoreData[cacheKey] = false;
        if (forceRefresh || !hasData(cacheKey)) {
          setData(cacheKey, []);
        }
        debugPrint('🚫 쿼리 결과 없음: $cacheKey');
        return getData(cacheKey) ?? [];
      } else if (docs.length < _pageSize) {
        _hasMoreData[cacheKey] = false;
        debugPrint('🔍 마지막 페이지 로드: $cacheKey (${docs.length} 항목)');
      }

      // 마지막 문서 저장
      if (docs.isNotEmpty) {
        _lastDocuments[cacheKey] = docs.last;
      }

      // 데이터 변환 - 예약 상태 확인 제거
      final List<Map<String, dynamic>> newData = [];
      for (var doc in docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          // average_rating 필드 정규화
          if (data.containsKey('average_rating')) {
            data['average_rating'] = _filterService.safeParseDouble(data['average_rating']);
          } else {
            data['average_rating'] = 0.0;
          }

          // ✅ 예약 체크 없이 바로 추가
          newData.add(data);
        } catch (e) {
          debugPrint('⚠️ 친구 데이터 처리 오류: $e');
        }
      }

      // 정렬 및 캐시 업데이트
      _sortDataByRating(newData);

      if (forceRefresh || !hasData(cacheKey)) {
        setData(cacheKey, newData);
      } else {
        final existingData = getData(cacheKey) ?? [];
        existingData.addAll(newData);
        _sortDataByRating(existingData);
        setData(cacheKey, existingData);
      }

      debugPrint('✅ 데이터 로드 완료: $cacheKey (${newData.length} 항목)');

      // 캐시 초기화 상태 업데이트
      _isCacheInitialized = true;

      return getData(cacheKey) ?? [];
    } catch (e) {
      debugPrint('❌ 데이터 로드 오류: $e');

      // 오류 발생 시 빈 리스트 반환
      if (!hasData(cacheKey)) {
        setData(cacheKey, []);
        _hasMoreData[cacheKey] = false;
      }

      // 오류는 로깅만 하고 실제로는 throw하지 않음
      return getData(cacheKey) ?? [];
    } finally {
      // 로딩 상태 해제
      markRequestLoaded(requestId, listType);
      debugPrint('🔄 로딩 완료 (loadMoreFriends): $cacheKey, _isLoading = false');
    }
  }

  // 특정 ID 목록의 친구 데이터 로드
  Future<List<Map<String, dynamic>>> loadMoreFriendsWithIds(
      List<String> friendUserIds,
      Map<String, dynamic> requestLocation,
      String requestId,
      String listType,
      {bool forceRefresh = false}) async {
    final cacheKey = '${requestId}_${listType}';

    // ID 목록이 비어있는 경우 빈 배열 반환
    if (friendUserIds.isEmpty) {
      _hasMoreData[cacheKey] = false;
      setData(cacheKey, []);
      debugPrint('🚫 친구 ID 목록이 비어있음: $cacheKey');
      return [];
    }

    // 이미 로딩 중인 경우 캐시된 데이터 반환 (중복 요청 방지)
    if (isRequestLoading(cacheKey)) {
      debugPrint('🔄 이미 로딩 중: $cacheKey - 캐시된 데이터 반환');
      return getData(cacheKey) ?? [];
    }

    // 타임아웃이 발생한 경우 재시도 또는 캐시된 데이터 반환
    if (_requestTimedOut[cacheKey] == true && !forceRefresh) {
      debugPrint('⏱️ 타임아웃 발생한 요청: $cacheKey');
      // 캐시된 데이터가 있으면 반환
      if (hasData(cacheKey)) {
        debugPrint('📦 타임아웃 발생했지만 캐시된 데이터 사용');
        return getData(cacheKey) ?? [];
      }
      // 캐시가 없으면 재시도
      _requestTimedOut[cacheKey] = false;
      debugPrint('🔄 타임아웃 후 재시도');
    }

    // 캐시 체크 - forceRefresh가 false이고 캐시된 데이터가 있는 경우
    if (!forceRefresh && hasData(cacheKey)) {
      debugPrint('🔄 캐시된 데이터 사용 (loadMoreFriendsWithIds): $cacheKey');
      return getData(cacheKey) ?? [];
    }

    // 더 로드할 데이터가 없는 경우 캐시된 데이터 반환
    if (!forceRefresh && !(hasMoreData(requestId, listType))) {
      debugPrint('🛑 더 로드할 데이터 없음 (loadMoreFriendsWithIds): $cacheKey');

      // 빈 데이터면 hasMoreData를 false로 설정
      if (!hasData(cacheKey) || (hasData(cacheKey) && (getData(cacheKey)?.isEmpty ?? true))) {
        _hasMoreData[cacheKey] = false;
        setData(cacheKey, []);
      }

      return getData(cacheKey) ?? [];
    }

    // 이미 로드를 시도했고 빈 결과를 가진 경우 재시도 방지
    if (!forceRefresh && hasAttemptedLoad(cacheKey) && hasData(cacheKey) && (getData(cacheKey)?.isEmpty ?? true)) {
      debugPrint('🛑 이미 로드 시도했고 빈 결과: $cacheKey');
      _hasMoreData[cacheKey] = false;
      return getData(cacheKey) ?? [];
    }

    // 로딩 상태 설정 및 타임아웃 타이머 설정
    markRequestLoading(requestId, listType);
    markLoadAttempted(cacheKey); // 로드 시도 표시
    debugPrint('🔄 로딩 시작 (loadMoreFriendsWithIds): $cacheKey, _isLoading = true');

    try {
      // 위치 정보 확인
      final String? requestCity = requestLocation['city'] as String?;
      final String? requestNationality = requestLocation['nationality'] as String?;

      if (requestCity == null || requestNationality == null) {
        _hasMoreData[cacheKey] = false;
        setData(cacheKey, []);
        debugPrint('🚫 요청 위치 정보가 없음: $cacheKey');
        return [];
      }

      // 페이지네이션 관련 변수
      final existingData = forceRefresh ? <Map<String, dynamic>>[] : (getData(cacheKey) ?? []);
      int startIndex = forceRefresh ? 0 : existingData.length;

      if (!forceRefresh && startIndex >= friendUserIds.length) {
        _hasMoreData[cacheKey] = false;
        debugPrint('🛑 이미 모든 친구 ID를 로드함: $cacheKey');
        return existingData;
      }

      int endIndex = startIndex + _pageSize;
      if (endIndex >= friendUserIds.length) {
        endIndex = friendUserIds.length;
        _hasMoreData[cacheKey] = false;
        debugPrint('🛑 마지막 친구 ID 페이지 로드: $cacheKey');
      }

      List<String> idsToFetch = friendUserIds.sublist(startIndex, endIndex);
      List<Map<String, dynamic>> newData = [];

      // 각 ID에 대해 데이터 가져오기
      for (String friendId in idsToFetch) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('tripfriends_users')
              .doc(friendId)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            data['uid'] = doc.id; // uid 필드 명시적으로 추가

            // average_rating 필드 정규화
            if (data.containsKey('average_rating')) {
              data['average_rating'] = _filterService.safeParseDouble(data['average_rating']);
            } else {
              data['average_rating'] = 0.0;
            }

            // 중요: isActive와 isApproved 필드가 없는 경우, isActive는 true로, isApproved는 false로 설정
            if (!data.containsKey('isActive')) {
              data['isActive'] = true; // isActive는 기본값으로 true 유지
              debugPrint('⚠️ $friendId에 isActive 필드가 없어 기본값 true 설정');
            }

            if (!data.containsKey('isApproved')) {
              data['isApproved'] = false; // 요청대로 isApproved는 기본값으로 false 설정
              debugPrint('⚠️ $friendId에 isApproved 필드가 없어 기본값 false 설정');
            }

            // ✅ 예약 체크 없이 바로 추가

            // 위치 확인
            if (data['location'] is Map) {
              final friendLocation = Map<String, dynamic>.from(data['location'] as Map);
              final String? friendCity = friendLocation['city'] as String?;
              final String? friendNationality = friendLocation['nationality'] as String?;

              if (friendCity != null && friendNationality != null &&
                  friendCity == requestCity && friendNationality == requestNationality) {
                // 매치되는 항목만 추가
                newData.add(data);
                debugPrint('✅ 친구 데이터 매치됨: $friendId, isActive=${data['isActive']}, isApproved=${data['isApproved']}');
              } else {
                debugPrint('❌ 친구 위치 불일치: $friendId (요청: $requestCity/$requestNationality, 친구: $friendCity/$friendNationality)');
              }
            } else {
              debugPrint('❓ 친구 위치 정보가 없음: $friendId');
              // 위치가 없는 경우 - 강제로 일치하도록 설정하고 포함
              data['location'] = {
                'city': requestCity,
                'nationality': requestNationality
              };
              newData.add(data);
              debugPrint('✅ 위치 정보 없는 친구 강제 추가: $friendId, isActive=${data['isActive']}, isApproved=${data['isApproved']}');
            }
          } else {
            debugPrint('❌ 친구 문서가 존재하지 않음: $friendId');
          }
        } catch (e) {
          // 개별 에러 무시하고 계속 진행
          debugPrint('❌ 친구 데이터 로드 오류 (ID: $friendId): $e');
        }
      }

      // 결과가 비어있는 경우 더 이상 데이터가 없음을 표시
      if (newData.isEmpty && existingData.isEmpty) {
        _hasMoreData[cacheKey] = false;
        setData(cacheKey, []);
        debugPrint('🚫 일치하는 친구 데이터 없음: $cacheKey');
        return [];
      }

      // 추가된 데이터 로그
      debugPrint('➕ 새로 추가된 친구 데이터: ${newData.length}명');
      for (var friend in newData) {
        final uid = friend['uid'] ?? friend['id'] ?? 'unknown';
        final isActive = friend['isActive'] == true;
        final isApproved = friend['isApproved'] == true;
        debugPrint('👤 친구 $uid 상태: isActive=$isActive, isApproved=$isApproved');
      }

      // 정렬 및 캐시 업데이트
      if (newData.isNotEmpty) {
        _sortDataByRating(newData);
      }

      // 결과 처리 및 캐시 업데이트
      if (forceRefresh) {
        setData(cacheKey, newData);
      } else if (existingData.isEmpty) {
        setData(cacheKey, newData);
      } else {
        existingData.addAll(newData);
        _sortDataByRating(existingData);
        setData(cacheKey, existingData);
      }

      debugPrint('✅ 친구 데이터 로드 완료: $cacheKey (${newData.length} 항목)');
      return getData(cacheKey) ?? [];
    } catch (e) {
      debugPrint('❌ 친구 ID 로드 오류: $e');

      // 오류 발생 시 빈 리스트 반환
      if (!hasData(cacheKey)) {
        setData(cacheKey, []);
        _hasMoreData[cacheKey] = false;
      }

      // 오류는 로깅만 하고 실제로는 throw하지 않음
      return getData(cacheKey) ?? [];
    } finally {
      // 로딩 상태 해제
      markRequestLoaded(requestId, listType);
      debugPrint('🔄 로딩 완료 (loadMoreFriendsWithIds): $cacheKey, _isLoading = false');
    }
  }

  // 공통 정렬 메서드
  void _sortDataByRating(List<Map<String, dynamic>> data) {
    data.sort((a, b) {
      double ratingA = a['average_rating'] ?? 0.0;
      double ratingB = b['average_rating'] ?? 0.0;
      return ratingB.compareTo(ratingA);
    });
  }

  // 필터링 초기화
  void resetFiltering() {
    _currentFilters = {};
    // 필터링만 초기화하고 데이터 캐시는 유지
  }

  // 메모리 정리 - 앱 종료 시에만 호출
  void clearMemory() {
    _cachedData.clear();
    _lastDocuments.clear();
    _hasMoreData.clear();
    _requestLoading.clear();
    _cancelAllTimeoutTimers(); // 모든 타임아웃 타이머 취소
    _requestTimedOut.clear(); // 타임아웃 상태 초기화
    _attemptedLoads.clear(); // 추가: 로드 시도 추적 초기화
    _isLoading = false;
    _isCacheInitialized = false;
    debugPrint('🧹 메모리 전체 초기화 완료');
  }
}