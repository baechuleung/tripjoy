// lib/tripfriends/friendslist/services/friends_list_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../filter/friends_filter_service.dart';
import '../services/random_shuffle_service.dart';
import '../services/friends_data_service.dart';

/// 친구 목록 관리를 위한 통합 클래스
class FriendsListManager {
  // 싱글톤 패턴
  static final FriendsListManager _instance = FriendsListManager._internal();
  factory FriendsListManager() => _instance;
  FriendsListManager._internal();

  // 서비스 인스턴스
  final FriendsFilterService _filterService = FriendsFilterService();
  final RandomShuffleService _shuffleService = RandomShuffleService();
  final FriendsDataService _dataService = FriendsDataService();

  // 위치 정보
  String? _requestCity;
  String? _requestNationality;
  String? _requestDocId;

  // Getters
  String? get requestCity => _requestCity;
  String? get requestNationality => _requestNationality;
  String? get requestDocId => _requestDocId;
  FriendsFilterService get filterService => _filterService;
  RandomShuffleService get shuffleService => _shuffleService;
  FriendsDataService get dataService => _dataService;

  /// plan_request 정보 로드
  Future<Map<String, dynamic>> loadPlanRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      final requestSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('plan_requests')
          .limit(1)
          .get();

      if (requestSnapshot.docs.isEmpty) {
        throw Exception('여행 요청 정보가 없습니다.');
      }

      final requestDoc = requestSnapshot.docs.first;
      _requestDocId = requestDoc.id;
      final requestData = requestDoc.data();

      if (requestData['location'] is Map) {
        final location = Map<String, dynamic>.from(requestData['location'] as Map);
        _requestCity = location['city'] as String?;
        _requestNationality = location['nationality'] as String?;

        if (_requestCity == null || _requestNationality == null) {
          throw Exception('여행 요청의 위치 정보가 불완전합니다.');
        }

        // 필터 서비스에 위치 정보 설정
        _filterService.setLocationFilter(_requestCity, _requestNationality);
      } else {
        throw Exception('여행 요청의 위치 정보가 없습니다.');
      }

      return {
        'docId': _requestDocId!,
        'city': _requestCity!,
        'nationality': _requestNationality!,
      };
    } catch (e) {
      debugPrint('⚠️ plan_request 로드 오류: $e');
      rethrow;
    }
  }

  /// 친구 목록 처리 (필터링, 정렬, 셔플)
  List<Map<String, dynamic>> processFriendsList(
      List<Map<String, dynamic>> friends, {
        bool enableShuffle = true,
      }) {
    if (friends.isEmpty) return [];

    // 1. 유효한 친구만 필터링 (isActive && isApproved)
    List<Map<String, dynamic>> validFriends = friends.where((friend) {
      return isValidFriend(friend);
    }).toList();

    // 2. 추가 필터 적용
    List<Map<String, dynamic>> processed = _filterService.applyClientSideFilters(validFriends);

    // 3. 정렬 적용
    processed = _filterService.getSortedFriendsList(processed);

    // 4. 셔플 적용 (정렬이 없을 때만)
    if (enableShuffle && _requestDocId != null &&
        _filterService.currentSortType == 'none' &&
        _shuffleService.shuffleEnabled) {
      processed = _shuffleService.shuffleList(
          processed,
          _requestDocId!,
          'friends_list'
      );
    }

    debugPrint('📊 친구 목록 처리: 원본 ${friends.length}명 → 유효 ${validFriends.length}명 → 처리 후 ${processed.length}명');
    return processed;
  }

  /// 필터 활성화 여부 확인
  bool hasActiveFilters(Map<String, Set<String>> filters) {
    for (var category in filters.keys) {
      if (filters[category]!.isNotEmpty &&
          !filters[category]!.contains('상관없음') &&
          !filters[category]!.contains('전체')) {
        return true;
      }
    }
    return false;
  }

  /// 정렬 필터 여부 확인
  bool hasSortingFilter(Map<String, Set<String>> filters) {
    // 별점 정렬
    if (filters['별점']?.isNotEmpty == true &&
        !filters['별점']!.contains('상관없음')) {
      return true;
    }

    // 매칭 횟수 정렬
    if (filters['매칭 횟수']?.isNotEmpty == true &&
        !filters['매칭 횟수']!.contains('상관없음')) {
      return true;
    }

    return false;
  }

  /// 친구 유효성 검증
  bool isValidFriend(Map<String, dynamic> friend) {
    // isActive가 없으면 true로 간주
    final bool isActive = friend.containsKey('isActive')
        ? friend['isActive'] == true
        : true;

    // isApproved가 없으면 true로 간주
    final bool isApproved = friend.containsKey('isApproved')
        ? friend['isApproved'] == true
        : true;

    return isActive && isApproved;
  }

  /// 셔플 활성화/비활성화
  void setShuffleEnabled(bool enabled) {
    _shuffleService.shuffleEnabled = enabled;
    if (enabled) {
      _shuffleService.clearAllCache();
    }
  }

  /// 위치 정보 재설정
  void resetLocationInfo() {
    _requestCity = null;
    _requestNationality = null;
    _requestDocId = null;
  }

  /// 모든 캐시 초기화
  void clearAllCache() {
    _dataService.clearCache('', '');
    _shuffleService.clearAllCache();
  }
}