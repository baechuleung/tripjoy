// lib/point_module/services/android_payment_service.dart

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../models/point_package.dart';
import '../utils/payment_constants.dart';
import 'payment_service.dart';

class AndroidPaymentService implements PaymentService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final _purchaseStreamController = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Future<bool> initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      return false;
    }

    // 구매 업데이트 리스너 설정
    _subscription = _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      _purchaseStreamController.add(purchaseDetailsList);
      _handlePurchaseUpdates(purchaseDetailsList);
    }, onError: (error) {
      print('구매 스트림 오류: $error');
    });

    return true;
  }

  @override
  Future<List<ProductDetails>> loadProducts() async {
    final Set<String> productIds = PaymentConstants.androidProducts.values.toSet();
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

    if (response.error != null) {
      print('상품 로드 오류: ${response.error}');
      return [];
    }

    return response.productDetails;
  }

  @override
  Future<bool> purchasePoints(PointPackage package) async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({package.androidProductId});

      if (response.productDetails.isEmpty) {
        print('상품을 찾을 수 없습니다: ${package.androidProductId}');
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

      return await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('구매 오류: $e');
      return false;
    }
  }

  @override
  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseStreamController.stream;

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 결제 대기 중
        print('결제 대기 중: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // 결제 오류
        print('결제 오류: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        // 결제 완료
        print('결제 완료: ${purchaseDetails.productID}');
        // 서버 검증 로직 추가 필요
      }

      // 구매 완료 처리
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _purchaseStreamController.close();
  }
}