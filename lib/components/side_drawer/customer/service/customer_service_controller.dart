import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerServiceController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 문의 카테고리 목록
  static const List<String> categories = [
    '일반문의',
    '예약 관련',
    '결제 관련',
    '프렌즈 관련',
    '기타 문의'
  ];

  // 문의 제출
  Future<void> submitInquiry({
    required User user,
    required String category,
    required String title,
    required String content,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final docData = {
        'userId': user.uid,
        'userEmail': email ?? user.email ?? '',
        'phoneNumber': phoneNumber ?? user.phoneNumber ?? '',
        'userName': user.displayName ?? '익명',
        'category': category,
        'title': title,
        'content': content,
        'status': 'pending', // pending, answered, closed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      debugPrint('📝 Firestore에 저장할 데이터: $docData');

      final docRef = await _firestore.collection('customer_service').add(docData);

      debugPrint('✅ 문의가 Firestore에 저장됨. 문서 ID: ${docRef.id}');
    } catch (e) {
      debugPrint('❌ Firestore 저장 오류: $e');
      rethrow;
    }
  }

  // 날짜 포맷팅
  static String formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  // 상태 정보 가져오기
  static Map<String, dynamic> getStatusInfo(String? status) {
    switch (status) {
      case 'answered':
        return {
          'color': const Color(0xFF4CAF50),
          'text': '답변완료',
        };
      case 'closed':
        return {
          'color': const Color(0xFF9E9E9E),
          'text': '종료',
        };
      default:
        return {
          'color': const Color(0xFFFF9800),
          'text': '답변대기',
        };
    }
  }
}