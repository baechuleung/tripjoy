// lib/point_module/screens/point_page.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../models/point_package.dart';
import '../services/payment_service.dart';
import '../services/android_payment_service.dart';
import '../services/ios_payment_service.dart';
import '../handlers/payment_handler.dart';
import '../widgets/point_header_widget.dart';
import '../widgets/charge_tab_view.dart';
import '../widgets/history_tab_view.dart';
import '../dialogs/charge_confirm_dialog.dart';

class PointPage extends StatefulWidget {
  const PointPage({super.key});

  @override
  State<PointPage> createState() => _PointPageState();
}

class _PointPageState extends State<PointPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _numberFormat = NumberFormat('#,###');
  int _currentPoints = 0;
  bool _isLoading = true;

  // 결제 관련 변수
  late PaymentService _paymentService;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserPoints();
    _initializePayment();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _purchaseSubscription?.cancel();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    // 플랫폼별 결제 서비스 초기화
    if (Platform.isAndroid) {
      _paymentService = AndroidPaymentService();
    } else if (Platform.isIOS) {
      _paymentService = IOSPaymentService();
    } else {
      print('지원하지 않는 플랫폼입니다.');
      return;
    }

    final bool initialized = await _paymentService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제 서비스를 초기화할 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 구매 업데이트 리스너 설정
    _purchaseSubscription = _paymentService.purchaseStream.listen((purchaseDetailsList) {
      _handlePurchaseUpdates(purchaseDetailsList);
    });
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          _isPurchasing = true;
        });
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          setState(() {
            _isPurchasing = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('결제 오류: ${purchaseDetails.error?.message ?? "알 수 없는 오류"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          // 결제 성공 - 포인트 충전 처리
          try {
            await PaymentHandler.handleSuccessfulPurchase(purchaseDetails, _currentPoints);

            // 포인트 패키지 찾기
            final package = PointPackage.packages.firstWhere(
                  (p) => p.androidProductId == purchaseDetails.productID ||
                  p.iosProductId == purchaseDetails.productID,
              orElse: () => PointPackage.packages.first,
            );

            // 포인트 업데이트
            setState(() {
              _currentPoints += package.points;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_numberFormat.format(package.points)} 포인트가 충전되었습니다.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('포인트 충전 처리 중 오류가 발생했습니다: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  Future<void> _loadUserPoints() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _currentPoints = userDoc.data()?['points'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('포인트 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          '포인트',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFEEEEEE),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // 현재 포인트 표시
          PointHeaderWidget(
            currentPoints: _currentPoints,
            isLoading: _isLoading,
          ),

          // 탭바
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 50,
              decoration: ShapeDecoration(
                color: const Color(0xFFF3F3F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(5),
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF4E5968),
                unselectedLabelColor: const Color(0xFF858585),
                labelStyle: const TextStyle(
                  color: Color(0xFF4E5968),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  color: Color(0xFF858585),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: '포인트 충전'),
                  Tab(text: '사용 내역'),
                ],
              ),
            ),
          ),

          // 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 포인트 충전 탭
                ChargeTabView(
                  isPurchasing: _isPurchasing,
                  onChargePressed: _showChargeConfirmDialog,
                ),
                // 사용 내역 탭
                const HistoryTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChargeConfirmDialog(PointPackage package) {
    ChargeConfirmDialog.show(
      context: context,
      package: package,
      onConfirm: () => _purchasePoints(package),
    );
  }

  Future<void> _purchasePoints(PointPackage package) async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      final success = await _paymentService.purchasePoints(package);
      if (!success && mounted) {
        setState(() {
          _isPurchasing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제를 시작할 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isPurchasing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('결제 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}