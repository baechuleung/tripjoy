// lib/tripfriends/friendslist/utils/filter_handler.dart
import '../constants/filter_constants.dart';

/// 필터 처리를 위한 유틸리티 클래스
class FilterHandler {
  /// 필터 적용
  static List<Map<String, dynamic>> applyFilters(
      List<Map<String, dynamic>> friends,
      Map<String, Set<String>> selectedFilters,
      ) {
    if (friends.isEmpty) return [];
    if (selectedFilters.isEmpty) return friends;

    return friends.where((friend) {
      // 성별 필터
      if (!_matchesGenderFilter(friend, selectedFilters)) return false;

      // 언어 필터
      if (!_matchesLanguageFilter(friend, selectedFilters)) return false;

      return true;
    }).toList();
  }

  /// 성별 필터 매칭
  static bool _matchesGenderFilter(
      Map<String, dynamic> friend,
      Map<String, Set<String>> filters,
      ) {
    final genderFilters = filters[FilterConstants.GENDER];
    if (genderFilters == null || genderFilters.isEmpty || genderFilters.contains('전체')) {
      return true;
    }

    final expectedGender = FilterConstants.getGenderCode(genderFilters.first);
    final friendGender = (friend['gender'] as String?)?.toLowerCase() ?? '';

    return friendGender == expectedGender.toLowerCase();
  }

  /// 언어 필터 매칭
  static bool _matchesLanguageFilter(
      Map<String, dynamic> friend,
      Map<String, Set<String>> filters,
      ) {
    final languageFilters = filters[FilterConstants.LANGUAGE];
    if (languageFilters == null ||
        languageFilters.isEmpty ||
        languageFilters.contains('상관없음')) {
      return true;
    }

    final languageCode = FilterConstants.getLanguageCode(languageFilters.first);
    final languages = friend['languages'] as List<dynamic>? ?? [];

    return languages.contains(languageCode);
  }

  /// 친구 목록 정렬
  static List<Map<String, dynamic>> sortFriends(
      List<Map<String, dynamic>> friends,
      String sortType,
      ) {
    if (friends.isEmpty || sortType == 'none') return friends;

    final sorted = List<Map<String, dynamic>>.from(friends);

    switch (sortType) {
      case 'rating_high':
        sorted.sort((a, b) {
          double ratingA = a['average_rating'] ?? 0.0;
          double ratingB = b['average_rating'] ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;

      case 'rating_low':
        sorted.sort((a, b) {
          double ratingA = a['average_rating'] ?? 0.0;
          double ratingB = b['average_rating'] ?? 0.0;
          return ratingA.compareTo(ratingB);
        });
        break;

      case 'match_high':
        sorted.sort((a, b) {
          int countA = a['match_count'] ?? 0;
          int countB = b['match_count'] ?? 0;
          return countB.compareTo(countA);
        });
        break;

      case 'match_low':
        sorted.sort((a, b) {
          int countA = a['match_count'] ?? 0;
          int countB = b['match_count'] ?? 0;
          return countA.compareTo(countB);
        });
        break;
    }

    return sorted;
  }

  /// 필터에서 정렬 타입 추출
  static String getSortTypeFromFilters(Map<String, Set<String>> filters) {
    // 매칭 횟수 정렬 확인
    final matchCountFilters = filters[FilterConstants.MATCH_COUNT];
    if (matchCountFilters != null && matchCountFilters.isNotEmpty) {
      final filter = matchCountFilters.first;
      if (filter == '매칭 횟수 많은 순') return 'match_high';
      if (filter == '매칭 횟수 적은 순') return 'match_low';
    }

    // 별점 정렬 확인
    final ratingFilters = filters[FilterConstants.RATING];
    if (ratingFilters != null && ratingFilters.isNotEmpty) {
      final filter = ratingFilters.first;
      if (filter == '별점 높은 순') return 'rating_high';
      if (filter == '별점 낮은 순') return 'rating_low';
    }

    return 'none';
  }

  /// 활성 필터가 있는지 확인
  static bool hasActiveFilters(Map<String, Set<String>> filters) {
    for (var category in filters.keys) {
      final options = filters[category];
      if (options != null &&
          options.isNotEmpty &&
          !options.contains('상관없음') &&
          !options.contains('전체')) {
        return true;
      }
    }
    return false;
  }

  /// 정렬 필터가 있는지 확인
  static bool hasSortingFilter(Map<String, Set<String>> filters) {
    final sortType = getSortTypeFromFilters(filters);
    return sortType != 'none';
  }
}