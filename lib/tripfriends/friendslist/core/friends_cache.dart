// lib/tripfriends/friendslist/core/friends_cache.dart

/// 친구 데이터 캐시를 관리하는 클래스
class FriendsCache {
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // 캐시 유효 시간 (5분)
  static const Duration cacheValidDuration = Duration(minutes: 5);

  /// 캐시에 데이터 저장
  void set(String key, List<Map<String, dynamic>> data) {
    _cache[key] = List.from(data);
    _cacheTimestamps[key] = DateTime.now();
  }

  /// 캐시에서 데이터 가져오기
  List<Map<String, dynamic>>? get(String key) {
    if (!_cache.containsKey(key)) return null;

    // 캐시 유효성 검사
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null) {
      final elapsed = DateTime.now().difference(timestamp);
      if (elapsed > cacheValidDuration) {
        // 캐시 만료
        remove(key);
        return null;
      }
    }

    return List.from(_cache[key]!);
  }

  /// 특정 키의 캐시 제거
  void remove(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// 모든 캐시 제거
  void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// 캐시 존재 여부 확인
  bool has(String key) {
    return _cache.containsKey(key) && get(key) != null;
  }
}