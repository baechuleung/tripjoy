// lib/auth/validators/referrer_code_validator.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferrerCodeValidator {
  static Future<bool> validateReferrerCode(String code) async {
    if (code.trim().isEmpty) {
      return true; // 빈 값이면 유효한 것으로 처리 (선택사항이므로)
    }

    try {
      // users 컬렉션의 모든 문서를 가져와서 확인
      final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // 각 문서를 순회하면서 referrer_code 필드 확인
      for (final doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // referrer_code 필드가 존재하고 입력한 코드와 일치하는지 확인
        if (data.containsKey('referrer_code') &&
            data['referrer_code'] == code.trim()) {
          return true;
        }
      }

      // 일치하는 코드를 찾지 못한 경우
      return false;
    } catch (e) {
      print('추천인 코드 검증 중 오류 발생: $e');
      return false;
    }
  }
}