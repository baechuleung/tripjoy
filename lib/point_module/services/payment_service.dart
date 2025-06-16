// lib/point_module/services/payment_service.dart

import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/point_package.dart';

abstract class PaymentService {
  // 결제 서비스 초기화
  Future<bool> initialize();

  // 상품 정보 로드
  Future<List<ProductDetails>> loadProducts();

  // 포인트 구매
  Future<bool> purchasePoints(PointPackage package);

  // 구매 복원
  Future<void> restorePurchases();

  // 구매 상태 스트림
  Stream<List<PurchaseDetails>> get purchaseStream;

  // 리소스 정리
  void dispose();
}