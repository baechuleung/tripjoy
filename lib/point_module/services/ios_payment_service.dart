// lib/point_module/services/ios_payment_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../models/point_package.dart';
import '../utils/payment_constants.dart';
import 'payment_service.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class IOSPaymentService implements PaymentService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final _purchaseStreamController = StreamController<List<PurchaseDetails>>.broadcast();

// BuildContext for SnackBar
  BuildContext? _context;

// 서버 URL 설정
  static const String _serverUrl = 'https://main-okncywrwuq-uc.a.run.app/verify-apple-receipt';

// 구매 완료 콜백
  Function(bool success, String message)? onPurchaseComplete;

// 처리중인 트랜잭션 추적
  final Set<String> _processingTransactions = {};

// 완료된 트랜잭션 추적 (앱 실행 중 유지)
  static final Set<String> _completedTransactions = {};

// 초기화 상태
  bool _isInitialized = false;

// Context 설정
  void setContext(BuildContext context) {
    _context = context;
  }

// 스낵바 표시 함수
  void _showSnackBar(String message) {
    print(message); // 기존 print도 유지
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(seconds: 2),
          )
      );
    }
  }

  @override
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        _showSnackBar('⚠️ 이미 초기화되어 있음');
        return true;
      }

      final bool available = await _inAppPurchase.isAvailable();
      _showSnackBar('🔍 인앱 구매 사용 가능: $available');

      if (!available) {
        _showSnackBar('❌ 인앱 구매를 사용할 수 없습니다');
        return false;
      }

      // 초기화 시 모든 미완료 트랜잭션 강제 완료
      await _forceCompleteAllTransactions();

      // 구매 업데이트 리스너 설정
      _subscription = _inAppPurchase.purchaseStream.listen(
            (purchaseDetailsList) {
          _showSnackBar('🎯 구매 스트림 업데이트: ${purchaseDetailsList.length}개');

          // 모든 상태 처리 (restored도 포함)
          _handlePurchaseUpdates(purchaseDetailsList);
        },
        onError: (error) {
          _showSnackBar('❌ 구매 스트림 오류: $error');
        },
      );

      _isInitialized = true;
      _showSnackBar('✅ 초기화 완료');
      return true;
    } catch (e) {
      _showSnackBar('❌ 초기화 중 오류: $e');
      return false;
    }
  }

// 모든 미완료 트랜잭션 강제 완료
  Future<void> _forceCompleteAllTransactions() async {
    try {
      _showSnackBar('🧹 모든 미완료 트랜잭션 강제 완료 시작…');

      final transactions = await SKPaymentQueueWrapper().transactions();

      for (final transaction in transactions) {
        _showSnackBar('🧹 트랜잭션 발견: ${transaction.transactionIdentifier}');
        await SKPaymentQueueWrapper().finishTransaction(transaction);
        _showSnackBar('✅ 트랜잭션 완료: ${transaction.transactionIdentifier}');
      }

      _showSnackBar('✅ 모든 미완료 트랜잭션 정리 완료');
    } catch (e) {
      _showSnackBar('❌ 트랜잭션 정리 오류: $e');
    }
  }

  @override
  Future<List<ProductDetails>> loadProducts() async {
    try {
      final Set<String> productIds = PaymentConstants.iosProducts.values.toSet();
      _showSnackBar('🔍 요청하는 상품 ID들: $productIds');

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

      _showSnackBar('📦 응답 상품 개수: ${response.productDetails.length}');
      for (var product in response.productDetails) {
        _showSnackBar('✅ 찾은 상품: ${product.id} - ${product.title} - ${product.price}');
      }

      if (response.error != null) {
        _showSnackBar('❌ 상품 로드 오류: ${response.error}');
      }

      return response.productDetails;
    } catch (e) {
      _showSnackBar('❌ 상품 로드 중 예외 발생: $e');
      return [];
    }
  }

  @override
  Future<bool> purchasePoints(PointPackage package) async {
    try {
      _showSnackBar('💳 === 구매 시작 ===');
      _showSnackBar('📦 요청 상품 ID: ${package.iosProductId}');

      // 상품 조회
      _showSnackBar('🔍 상품 조회 시작...');
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({package.iosProductId});

      if (response.error != null) {
        _showSnackBar('❌ 상품 쿼리 오류: ${response.error}');
        onPurchaseComplete?.call(false, '상품 정보를 가져올 수 없습니다.');
        return false;
      }

      if (response.productDetails.isEmpty) {
        _showSnackBar('❌ 상품을 찾을 수 없습니다: ${package.iosProductId}');
        onPurchaseComplete?.call(false, '상품을 찾을 수 없습니다.');
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;
      _showSnackBar('✅ 구매할 상품 찾음: ${productDetails.id}');
      _showSnackBar('💰 상품 가격: ${productDetails.price}');

      // PurchaseParam 생성
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      // 구매 시작
      _showSnackBar('🛒 buyConsumable 호출...');
      final bool result = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );

      _showSnackBar('✅ 구매 요청 결과: $result');

      if (!result) {
        onPurchaseComplete?.call(false, '구매를 시작할 수 없습니다.');
      }

      return result;

    } catch (e) {
      _showSnackBar('❌ 구매 오류: $e');
      onPurchaseComplete?.call(false, '구매 중 오류가 발생했습니다.');
      return false;
    }
  }

  @override
  Future<void> restorePurchases() async {
// 소모성 상품은 복원하지 않음
    _showSnackBar('⚠️ 소비성 상품은 복원하지 않습니다');
    return;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseStreamController.stream;

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _showSnackBar('\n🔍 ===== 구매 상세 정보 =====');
      _showSnackBar('📌 status: ${purchaseDetails.status}');
      _showSnackBar('📌 productID: ${purchaseDetails.productID}');
      _showSnackBar('📌 pendingCompletePurchase: ${purchaseDetails.pendingCompletePurchase}');
      _showSnackBar('📌 purchaseID: ${purchaseDetails.purchaseID}');
      _showSnackBar('📌 transactionDate: ${purchaseDetails.transactionDate}');

      final transactionId = purchaseDetails.purchaseID ?? '';

      // 이미 처리중인 트랜잭션인지 확인
      if (transactionId.isNotEmpty && _processingTransactions.contains(transactionId)) {
        _showSnackBar('⚠️ 이미 처리중인 트랜잭션: $transactionId');
        continue;
      }

      // 이미 완료된 트랜잭션인지 확인
      if (transactionId.isNotEmpty && _completedTransactions.contains(transactionId)) {
        _showSnackBar('✅ 이미 완료된 트랜잭션 - 스킵: $transactionId');

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        continue;
      }

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _showSnackBar('⏳ 결제 대기 중...');
          _purchaseStreamController.add([purchaseDetails]);
          break;

        case PurchaseStatus.purchased:
          _showSnackBar('✅ 새로운 구매 완료 - 서버 검증 진행');
          await _processPurchase(purchaseDetails);
          break;

        case PurchaseStatus.restored:
        // TestFlight에서는 새 구매도 restored로 올 수 있으므로 처리
          _showSnackBar('⚠️ Restored 상태 - 서버 검증 진행');
          await _processPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          _showSnackBar('❌ 결제 오류: ${purchaseDetails.error}');

          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }

          onPurchaseComplete?.call(false, '결제 중 오류가 발생했습니다.');
          _purchaseStreamController.add([purchaseDetails]);
          break;

        case PurchaseStatus.canceled:
          _showSnackBar('❌ 결제 취소됨');

          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }

          onPurchaseComplete?.call(false, '결제가 취소되었습니다.');
          _purchaseStreamController.add([purchaseDetails]);
          break;
      }
    }
  }

// 구매 처리 로직 통합
  Future<void> _processPurchase(PurchaseDetails purchaseDetails) async {
    final transactionId = purchaseDetails.purchaseID ?? '';

    _showSnackBar('🚀 _processPurchase 시작 - transactionId: $transactionId');

// 처리중 표시
    if (transactionId.isNotEmpty) {
      _processingTransactions.add(transactionId);
    }

// 영수증 데이터 가져오기
    String? receiptData;
    try {
      _showSnackBar('📄 영수증 데이터 가져오기 시작...');
      final String? receipt = await SKReceiptManager.retrieveReceiptData();
      receiptData = receipt;
      _showSnackBar('📄 영수증 데이터 길이: ${receipt?.length ?? 0}');
    } catch (e) {
      _showSnackBar('❌ 영수증 데이터 가져오기 실패: $e');
    }

// 서버 검증
    _showSnackBar('🌐 서버로 영수증 전송 시작...');
    final result = await _verifyPurchaseOnServer(purchaseDetails, receiptData);
    _showSnackBar('📡 서버 응답 받음: ${result['success']}');

// 완료된 트랜잭션으로 표시
    if (transactionId.isNotEmpty) {
      _completedTransactions.add(transactionId);
    }

// 처리 완료 후 제거
    if (transactionId.isNotEmpty) {
      _processingTransactions.remove(transactionId);
    }

// completePurchase 강제 호출 (중요!)
    _showSnackBar('🔧 completePurchase 강제 호출 (pending: ${purchaseDetails.pendingCompletePurchase})');
    await _inAppPurchase.completePurchase(purchaseDetails);
    _showSnackBar('✅ completePurchase 완료 - 트랜잭션 큐에서 제거됨');

// 결과 콜백
    onPurchaseComplete?.call(
        result['success'],
        result['message']
    );

    _purchaseStreamController.add([purchaseDetails]);
  }

// 서버 영수증 검증 메서드
  Future<Map<String, dynamic>> _verifyPurchaseOnServer(
      PurchaseDetails purchaseDetails,
      String? receiptData,
      ) async {
    try {
      _showSnackBar('🔍 === 서버 검증 시작 ===');

      // 현재 로그인한 사용자 ID 가져오기
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('❌ 로그인한 사용자가 없습니다');
        return {'success': false, 'message': '로그인이 필요합니다'};
      }

      final String userId = currentUser.uid;
      _showSnackBar('🔍 사용자 ID: $userId');
      _showSnackBar('📱 제품 ID: ${purchaseDetails.productID}');
      _showSnackBar('🎫 구매 ID: ${purchaseDetails.purchaseID}');
      _showSnackBar('📅 구매 날짜: ${purchaseDetails.transactionDate}');
      _showSnackBar('📄 영수증 데이터 있음: ${receiptData != null}');

      // 서버로 구매 정보 전송
      _showSnackBar('🌐 서버로 구매 정보 전송 중...');

      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'productId': purchaseDetails.productID,
        'transactionId': purchaseDetails.purchaseID,
        'purchaseDate': purchaseDetails.transactionDate,
        'status': purchaseDetails.status.toString(),
        'isProduction': false,  // TestFlight도 샌드박스 사용
        'verificationData': {
          'localData': receiptData,
          'serverData': purchaseDetails.verificationData.serverVerificationData,
        }
      };

      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _showSnackBar('⏱️ 서버 요청 타임아웃!');
          throw Exception('서버 요청 시간 초과');
        },
      );

      _showSnackBar('📡 서버 응답 상태 코드: ${response.statusCode}');
      print('📄 서버 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          _showSnackBar('✅ 서버 구매 확인 성공');
          final data = result['data'];
          return {
            'success': true,
            'message': '${data['pointsAdded']} 포인트가 충전되었습니다',
            'pointsAdded': data['pointsAdded'],
            'newTotalPoints': data['newTotalPoints'],
          };
        } else if (result['status'] == 'already_processed') {
          _showSnackBar('⚠️ 이미 처리된 구매');
          return {
            'success': false,
            'message': 'already_processed',
            'isAlreadyProcessed': true,
          };
        } else {
          _showSnackBar('❌ 서버 확인 실패: ${result['message']}');
          return {
            'success': false,
            'message': result['message'] ?? '구매 확인에 실패했습니다',
          };
        }
      } else {
        _showSnackBar('❌ 서버 응답 오류: ${response.statusCode}');
        return {
          'success': false,
          'message': '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        };
      }
    } catch (e) {
      _showSnackBar('❌ 서버 구매 확인 중 오류: $e');
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      };
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _purchaseStreamController.close();
    _processingTransactions.clear();
    _isInitialized = false;
  }
}