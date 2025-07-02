// lib/auth/handlers/referrer_bonus_handler.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReferrerBonusHandler {
  static const int REFERRER_BONUS_POINTS = 3000;

  static Future<void> handleReferrerBonus({
    required String userId,
    required String referrerCode,
    required int currentPoints,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // 추천인 보너스 포인트 추가
    await firestore.collection('users').doc(userId).update({
      'points': FieldValue.increment(REFERRER_BONUS_POINTS),
    });

    // 포인트 내역 기록
    await firestore
        .collection('users')
        .doc(userId)
        .collection('points_history')
        .add({
      'amount': REFERRER_BONUS_POINTS,
      'type': 'bonus',
      'description': '추천인 코드 입력 보너스',
      'referrerCode': referrerCode,
      'createdAt': FieldValue.serverTimestamp(),
      'balance': currentPoints + REFERRER_BONUS_POINTS,
    });
  }
}