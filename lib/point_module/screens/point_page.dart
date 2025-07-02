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
  final int initialTabIndex;

  const PointPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<PointPage> createState() => _PointPageState();
}

class _PointPageState extends State<PointPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _numberFormat = NumberFormat('#,###');
  int _currentPoints = 0;
  bool _isLoading = true;
  StreamSubscription<DocumentSnapshot>? _pointsSubscription;

  PaymentService? _paymentService;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadUserPoints();
    _initializePayment();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _purchaseSubscription?.cancel();
    _pointsSubscription?.cancel();
    _paymentService?.dispose();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    if (Platform.isAndroid) {
      _paymentService = AndroidPaymentService();
    } else if (Platform.isIOS) {
      _paymentService = IOSPaymentService();
      // iOS의 경우 서버 검증 콜백 설정
      (_paymentService as IOSPaymentService).onPurchaseComplete = (success, message) {
        if (mounted) {
          setState(() {
            _isPurchasing = false;
          });

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      };
    } else {
      return;
    }

    final bool initialized = await _paymentService!.initialize();
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

    _purchaseSubscription = _paymentService!.purchaseStream.listen((purchaseDetailsList) {
      _handlePurchaseUpdates(purchaseDetailsList);
    });
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('📱 구매 상태: ${purchaseDetails.status}, pending: ${purchaseDetails.pendingCompletePurchase}');

      // iOS에서 restored는 이미 필터링되었지만, 혹시 모르니 여기서도 체크
      if (purchaseDetails.status == PurchaseStatus.restored) {
        print('📱 restored 무시됨');
        continue;
      }

      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          _isPurchasing = true;
        });
      } else if (purchaseDetails.status == PurchaseStatus.error) {
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
        // Android의 경우에만 여기서 처리
        if (Platform.isAndroid) {
          try {
            await PaymentHandler.handleSuccessfulPurchase(purchaseDetails, _currentPoints);

            final package = PointPackage.packages.firstWhere(
                  (p) => p.androidProductId == purchaseDetails.productID ||
                  p.iosProductId == purchaseDetails.productID,
              orElse: () => PointPackage.packages.first,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_numberFormat.format(package.points)} 포인트가 충전되었습니다.'),
                  backgroundColor: Colors.green,
                ),
              );
            }

            setState(() {
              _isPurchasing = false;
            });
          } catch (e) {
            setState(() {
              _isPurchasing = false;
            });
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
        // iOS는 IOSPaymentService의 콜백에서 처리됨
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        setState(() {
          _isPurchasing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('결제가 취소되었습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadUserPoints() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _currentPoints = 0;
        });
        return;
      }

      _pointsSubscription?.cancel();

      _pointsSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            _currentPoints = snapshot.data()?['points'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _currentPoints = 0;
          });
        }
      }, onError: (error) {
        setState(() {
          _isLoading = false;
          _currentPoints = 0;
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPoints = 0;
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
          PointHeaderWidget(
            currentPoints: _currentPoints,
            isLoading: _isLoading,
          ),
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
          Container(
            color: const Color(0xFFF9F9F9),
            height: 10,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ChargeTabView(
                  isPurchasing: _isPurchasing,
                  onChargePressed: _showChargeConfirmDialog,
                ),
                const HistoryTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChargeConfirmDialog(PointPackage package) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('포인트 충전을 위해 로그인이 필요합니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ChargeConfirmDialog.show(
      context: context,
      package: package,
      points: _currentPoints,
      onConfirm: () => _purchasePoints(package),
    );
  }

  Future<void> _purchasePoints(PointPackage package) async {
    if (_paymentService == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제 서비스가 초기화되지 않았습니다. 잠시 후 다시 시도해주세요.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    try {
      final success = await _paymentService!.purchasePoints(package);
      if (!success && mounted) {
        setState(() {
          _isPurchasing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제를 시작할 수 없습니다. 잠시 후 다시 시도해주세요.'),
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