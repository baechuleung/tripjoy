// lib/tripfriends/friendslist/filter/filter_constants.dart
import 'package:flutter/material.dart';

/// 필터 관련 상수와 유틸리티 함수를 중앙 집중화한 클래스
class FilterConstants {
  // 필터 카테고리 이름
  static const String RATING = '별점';
  static const String LANGUAGE = '사용 가능 언어';
  static const String GENDER = '성별';
  static const String MATCH_COUNT = '매칭 횟수';

  // 필터 기본 옵션 정의
  static final Map<String, List<String>> filterOptions = {
    RATING: ['별점 높은 순', '별점 낮은 순', '상관없음'],
    LANGUAGE: ['한국어', '중국어', '영어', '베트남어', '일본어', '태국어', '상관없음'],
    GENDER: ['남성 프렌즈', '여성 프렌즈', '전체'],
    MATCH_COUNT: ['매칭 횟수 많은 순', '매칭 횟수 적은 순', '상관없음'],
  };

  // 필터 초기 상태
  static Map<String, Set<String>> getInitialFilterState() {
    return {
      RATING: {},
      LANGUAGE: {},
      GENDER: {},
      MATCH_COUNT: {},
    };
  }


  // 언어 코드 변환 (중복 제거)
  static String getLanguageCode(String selectedLanguage) {
    debugPrint('🔍 언어 코드 변환: $selectedLanguage');

    switch (selectedLanguage) {
      case '한국어':
        debugPrint('  → korean');
        return 'korean';
      case '영어':
        debugPrint('  → english');
        return 'english';
      case '일본어':
        debugPrint('  → japanese');
        return 'japanese';
      case '중국어':
        debugPrint('  → chinese');
        return 'chinese';
      case '베트남어':
        debugPrint('  → vietnamese');
        return 'vietnamese';
      case '태국어':
        debugPrint('  → thai');
        return 'thai';
      default:
        debugPrint('  → 빈 문자열 (매칭 없음)');
        return '';
    }
  }

  // 성별 코드 변환
  static String getGenderCode(String selectedGender) {
    if (selectedGender == '남성 프렌즈') return 'male';
    if (selectedGender == '여성 프렌즈') return 'female';
    return '';
  }

  // 필터에 따른 아이콘 및 색상 데이터 구조
  static Map<String, dynamic> getFilterDisplayData(String category, String option) {
    IconData iconData;
    IconData? secondIconData;
    Color iconColor;
    String displayText = option;

    switch (category) {
      case RATING:
        iconData = Icons.star;
        iconColor = const Color(0xFFFFDD67);
        if (option == '별점 높은 순') {
          secondIconData = Icons.arrow_drop_up;
          displayText = '별점';
        } else if (option == '별점 낮은 순') {
          secondIconData = Icons.arrow_drop_down;
          displayText = '별점';
        }
        break;
      case GENDER:
        if (option == '남성 프렌즈') {
          iconData = Icons.male;
          displayText = '남성';
          iconColor = const Color(0xFF6B3EFF);
        } else {
          iconData = Icons.female;
          displayText = '여성';
          iconColor = const Color(0xFFFF3E6C);
        }
        break;
      case LANGUAGE:
        iconData = Icons.language;
        iconColor = const Color(0xFF60A6DF);
        break;
      case MATCH_COUNT:
        iconData = Icons.handshake;
        iconColor = const Color(0xFF5E684A);
        if (option == '매칭 횟수 많은 순') {
          secondIconData = Icons.arrow_drop_up;
          displayText = '매칭 횟수';
        } else if (option == '매칭 횟수 적은 순') {
          secondIconData = Icons.arrow_drop_down;
          displayText = '매칭 횟수';
        }
        break;
      default:
        iconData = Icons.filter_list;
        iconColor = Colors.grey;
    }

    return {
      'iconData': iconData,
      'secondIconData': secondIconData,
      'iconColor': iconColor,
      'displayText': displayText,
    };
  }
}