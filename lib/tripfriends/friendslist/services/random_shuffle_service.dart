// lib/tripfriends/friendslist/services/random_shuffle_service.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// 오직 문서 ID 변경 기반으로 셔플을 결정하는 서비스
class RandomShuffleService {
  // 싱글톤 패턴
  static final RandomShuffleService _instance = RandomShuffleService._internal();

  // 마지막으로 처리한 plan_request 문서 ID
  static String _lastRequestDocId = '';

  // 문서별 셔플된 결과 저장 캐시 - 문서 ID가 키
  static final Map<String, Map<String, List<dynamic>>> _shuffledCache = {};

  // 셔플 활성화 여부 - 필터 적용 시 셔플 비활성화
  static bool _shuffleEnabled = true; // 기본값을 true로 변경

  factory RandomShuffleService() {
    return _instance;
  }

  RandomShuffleService._internal();

  // 마지막 문서 ID getter (디버깅용)
  String get lastRequestDocId => _lastRequestDocId;

  // 셔플 활성화/비활성화 설정
  set shuffleEnabled(bool value) {
    _shuffleEnabled = value;
    debugPrint('🎲 셔플 ${_shuffleEnabled ? '활성화' : '비활성화'} 설정됨');
  }

  /// 리스트를 셔플 - 문서 ID 변경 시에만 셔플 수행 (별점 정렬 우선)
  List<T> shuffleList<T>(List<T> list, String requestDocId, String listType) {
    if (list.isEmpty) return [];

    // 셔플 비활성화 상태라면 원본 리스트 반환 (정렬 유지)
    if (!_shuffleEnabled) {
      debugPrint('🎲 셔플 비활성화 상태: 원본 리스트 그대로 반환 (정렬 유지)');
      return list;
    }

    // 캐시 키 생성 (문서 ID + 목록 타입)
    String cacheKey = '${listType}_$requestDocId';

    // 문서 ID 변경 확인 - 이전과 다르면 셔플 필요
    bool isDocIdChanged = _lastRequestDocId != requestDocId;

    // 문서 ID 변경 및 캐시 초기화 처리 (캐시에 새 문서 공간 생성)
    if (isDocIdChanged) {
      debugPrint('📄 문서 ID 변경 감지! $_lastRequestDocId -> $requestDocId (새로운 셔플 적용)');
      _lastRequestDocId = requestDocId;

      // 변경된 문서 ID의 캐시 초기화
      if (!_shuffledCache.containsKey(requestDocId)) {
        _shuffledCache[requestDocId] = {};
      }
    } else {
      debugPrint('📄 동일한 문서 ID: $requestDocId (기존 셔플 유지)');
    }

    // 현재 문서의 캐시
    final docCache = _shuffledCache[requestDocId] ??= {};

    // 이미 캐시된 결과가 있으면 사용
    if (docCache.containsKey(listType)) {
      debugPrint('🎲 캐시된 셔플 결과 사용 (문서: $requestDocId, 목록: $listType)');
      return List<T>.from(docCache[listType]!);
    }

    // 새로 셔플 필요 - 문서 ID가 변경되었거나 캐시가 없을 때
    // 복사본 생성
    final shuffledList = List<T>.from(list);

    // 완전히 새로운 랜덤 시드로 셔플
    final random = Random(DateTime.now().microsecondsSinceEpoch);

    // Fisher-Yates 알고리즘으로 셔플
    for (int i = shuffledList.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      // 요소 교환
      final temp = shuffledList[i];
      shuffledList[i] = shuffledList[j];
      shuffledList[j] = temp;
    }

    debugPrint('🎲🎲🎲 새로운 셔플 적용됨 (문서: $requestDocId, 목록: $listType)');

    // 셔플 결과 캐싱
    docCache[listType] = shuffledList;

    return shuffledList;
  }

  /// 특정 문서 ID를 사용한 리스트가 이미 셔플되어 있는지 확인
  bool isAlreadyShuffled(String requestDocId, String listType) {
    return _shuffledCache.containsKey(requestDocId) &&
        _shuffledCache[requestDocId]!.containsKey(listType);
  }

  /// 특정 문서 ID에 대한 캐시 지우기 (특별한 상황에 사용)
  void clearCacheForDocument(String docId) {
    if (_shuffledCache.containsKey(docId)) {
      _shuffledCache.remove(docId);
      debugPrint('🧹 문서 $docId의 셔플 캐시 삭제됨');
    }
  }

  /// 모든 캐시 지우기 (앱 초기화 등에 사용)
  void clearAllCache() {
    _shuffledCache.clear();
    _lastRequestDocId = '';
    debugPrint('🧹 모든 셔플 캐시 삭제됨');
  }
}