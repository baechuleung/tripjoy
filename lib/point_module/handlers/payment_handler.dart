// lib/point_module/handlers/payment_handler.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/point_package.dart';

class PaymentHandler {
  static Future<void> handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails,
      int currentPoints,
      ) async {
    // 상품 ID로 포인트 패키지 찾기
    final package = PointPackage.packages.firstWhere(
          (p) => p.androidProductId == purchaseDetails.productID ||
          p.iosProductId == purchaseDetails.productID,
      orElse: () => PointPackage.packages.first,
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final firestore = FirebaseFirestore.instance;

    // 포인트 추가
    await firestore.collection('users').doc(currentUser.uid).update({
      'points': FieldValue.increment(package.points),
    });

    // 충전 내역 기록
    await firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('point_history')
        .add({
      'amount': package.points,
      'type': 'charge',
      'description': '포인트 충전',
      'price': package.price,
      'purchaseId': purchaseDetails.purchaseID,
      'productId': purchaseDetails.productID,
      'createdAt': FieldValue.serverTimestamp(),
      'balance': currentPoints + package.points,
    });
  }
}