// lib/tripfriends/friendslist/utils/shuffle_handler.dart
import 'dart:math';

/// 리스트 셔플을 위한 유틸리티 클래스
class ShuffleHandler {
  // 문서별 셔플 결과 캐시
  static final Map<String, Map<String, List<dynamic>>> _shuffleCache = {};

  /// 리스트를 셔플
  static List<T> shuffleList<T>(List<T> list, String requestDocId) {
    if (list.isEmpty) return [];

    final cacheKey = 'friends_$requestDocId';

    // 캐시 확인
    if (_shuffleCache.containsKey(requestDocId) &&
        _shuffleCache[requestDocId]!.containsKey('friends')) {
      return List<T>.from(_shuffleCache[requestDocId]!['friends']!);
    }

    // 새로 셔플
    final shuffled = List<T>.from(list);
    final random = Random(DateTime.now().microsecondsSinceEpoch);

    // Fisher-Yates 알고리즘
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }

    // 캐시 저장
    _shuffleCache[requestDocId] ??= {};
    _shuffleCache[requestDocId]!['friends'] = shuffled;

    return shuffled;
  }

  /// 특정 문서의 캐시 클리어
  static void clearCacheForDocument(String docId) {
    _shuffleCache.remove(docId);
  }

  /// 모든 캐시 클리어
  static void clearAllCache() {
    _shuffleCache.clear();
  }
}