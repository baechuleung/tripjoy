// lib/tripfriends/friendslist/core/friends_state_manager.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/data_transformer.dart';
import '../utils/filter_handler.dart';
import '../constants/filter_constants.dart';
import 'friends_repository.dart';

/// 친구 목록의 모든 상태를 관리하는 통합 매니저
class FriendsStateManager with ChangeNotifier {
  // 인스턴스 변수로 변경 (정적 변수 제거)
  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _displayFriends = [];
  Map<String, Set<String>> _selectedFilters = {};
  String? _currentRequestDocId;
  bool _hasData = false;

  FriendsStateManager() {
    _repository = FriendsRepository();
    // 생성자에서 즉시 로딩 상태로 설정
    _isLoading = true;
  }

  // 의존성
  late final FriendsRepository _repository;

  // dispose 상태 체크
  bool _isDisposed = false;

  // 상태 변수들
  bool _isLoading = true;  // 초기값을 true로 변경
  bool _hasError = false;
  String _errorMessage = '';

  // 위치 정보
  String? _requestCity;
  String? _requestNationality;

  // 필터 상태
  Map<String, Set<String>> get selectedFilters => _selectedFilters;

  // 데이터
  List<Map<String, dynamic>> get displayFriends => _displayFriends;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  /// 친구 데이터 스트림으로 로드
  Stream<List<Map<String, dynamic>>> loadFriendsStream() async* {
    print('📍 loadFriendsStream 시작');

    try {
      // 1. plan_request 정보 가져오기
      final requestInfo = await _repository.loadPlanRequest();
      final newDocId = requestInfo['docId'];

      // 2. 새로운 요청이면 데이터 클리어
      if (_currentRequestDocId != newDocId) {
        print('📍 새로운 plan_request - 데이터 클리어');
        _allFriends.clear();
        _displayFriends.clear();
        _hasData = false;
        _currentRequestDocId = newDocId;
      }

      // 3. 로딩 상태 유지
      _setLoading(true);

      _requestCity = requestInfo['city'];
      _requestNationality = requestInfo['nationality'];

      print('📍 위치: $_requestCity/$_requestNationality');

      // 4. 해당 위치의 친구들 가져오기
      final query = FirebaseFirestore.instance
          .collection('tripfriends_users')
          .where('location.city', isEqualTo: _requestCity)
          .where('location.nationality', isEqualTo: _requestNationality)
          .where('isActive', isEqualTo: true)
          .where('isApproved', isEqualTo: true);

      // 5. 모든 데이터를 먼저 수집
      await for (final friend in _repository.loadAllFriendsOneByOne(query)) {
        if (_isDisposed) break;

        // 위치 더블 체크
        final location = friend['location'] as Map<String, dynamic>?;
        if (location?['city'] != _requestCity || location?['nationality'] != _requestNationality) {
          continue;
        }

        // 유효성 체크
        if (friend['isActive'] != true || friend['isApproved'] != true) {
          continue;
        }

        // 데이터 추가
        _allFriends.add(friend);
      }

      // 6. 모든 데이터 로드 완료 후 처리
      if (!_isDisposed) {
        // 랜덤 정렬
        _shuffleFriends();

        // 필터 적용
        _applyFilters();

        // 로딩 완료
        _hasData = true;
        _setLoading(false);

        // 결과 반환
        yield List.from(_displayFriends);
      }

    } catch (e) {
      print('❌ 오류: $e');
      if (!_isDisposed) {
        _setLoading(false);
        _setError('데이터를 불러오는 중 오류가 발생했습니다.');
        yield [];
      }
    }
  }

  /// 친구 목록 랜덤 정렬
  void _shuffleFriends() {
    if (_allFriends.isEmpty) return;

    final random = Random();
    _allFriends.shuffle(random);
    print('🎲 친구 목록 랜덤 정렬 완료 - ${_allFriends.length}명');
  }

  /// 필터 적용
  void _applyFilters() {
    // 필터가 없으면 전체 표시
    if (_selectedFilters.isEmpty) {
      _displayFriends = List.from(_allFriends);
      return;
    }

    // 필터 적용
    _displayFriends = FilterHandler.applyFilters(_allFriends, _selectedFilters);

    // 정렬 적용
    final sortType = FilterHandler.getSortTypeFromFilters(_selectedFilters);
    if (sortType != 'none') {
      _displayFriends = FilterHandler.sortFriends(_displayFriends, sortType);
    }
  }

  /// 필터 적용
  void applyFilters(Map<String, Set<String>> filters) {
    if (_isDisposed) return;
    _selectedFilters = Map.from(filters);
    _applyFilters();
    notifyListeners();
  }

  /// 필터 제거
  void removeFilter(String category, String option) {
    if (_isDisposed) return;
    _selectedFilters[category]?.remove(option);
    if (_selectedFilters[category]?.isEmpty ?? false) {
      _selectedFilters.remove(category);
    }
    _applyFilters();
    notifyListeners();
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  /// 에러 설정
  void _setError(String message) {
    if (_isDisposed) return;
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}