// lib/tripfriends/friendslist/utils/data_transformer.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// 친구 데이터 변환을 위한 유틸리티 클래스
class DataTransformer {
  /// Firestore 문서를 친구 데이터 맵으로 변환
  static Map<String, dynamic> transformDocument(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return transformData(data, doc.id);
    } catch (e) {
      print('⚠️ 친구 데이터 변환 오류: $e');
      return _createEmptyFriendData(doc.id);
    }
  }

  /// 친구 데이터 정규화
  static Map<String, dynamic> transformData(Map<String, dynamic> data, String docId) {
    // ID 설정
    data['id'] = docId;
    data['uid'] = data['uid'] ?? docId;

    // average_rating 정규화
    data['average_rating'] = _parseDouble(data['average_rating']);

    // isActive와 isApproved 기본값 설정
    if (!data.containsKey('isActive')) {
      data['isActive'] = true;
    }

    if (!data.containsKey('isApproved')) {
      data['isApproved'] = true;
    }

    return data;
  }

  /// 안전한 double 파싱
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// 빈 친구 데이터 생성
  static Map<String, dynamic> _createEmptyFriendData(String docId) {
    return {
      'id': docId,
      'uid': docId,
      'average_rating': 0.0,
      'isActive': true,
      'isApproved': true,
    };
  }

  /// 친구 목록을 평점순으로 정렬
  static void sortByRating(List<Map<String, dynamic>> friends, {bool descending = true}) {
    friends.sort((a, b) {
      double ratingA = a['average_rating'] ?? 0.0;
      double ratingB = b['average_rating'] ?? 0.0;
      return descending ? ratingB.compareTo(ratingA) : ratingA.compareTo(ratingB);
    });
  }

  /// 친구가 유효한지 확인 (isActive && isApproved)
  static bool isValidFriend(Map<String, dynamic> friend) {
    final bool isActive = friend['isActive'] == true;
    final bool isApproved = friend['isApproved'] == true;
    return isActive && isApproved;
  }

  /// 위치 정보가 일치하는지 확인
  static bool matchesLocation(Map<String, dynamic> friend, String? requestCity, String? requestNationality) {
    if (requestCity == null || requestNationality == null) return false;

    if (friend['location'] is Map) {
      final friendLocation = Map<String, dynamic>.from(friend['location'] as Map);
      final String? friendCity = friendLocation['city'] as String?;
      final String? friendNationality = friendLocation['nationality'] as String?;

      return friendCity == requestCity && friendNationality == requestNationality;
    }

    return false;
  }
}