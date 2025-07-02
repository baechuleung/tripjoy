// lib/point_module/utils/payment_constants.dart

import 'dart:io';

class PaymentConstants {
  // 플랫폼별 상품 ID 맵
  static Map<String, String> get productIds {
    if (Platform.isAndroid) {
      return androidProducts;
    } else if (Platform.isIOS) {
      return iosProducts;
    }
    return {};
  }

  // Android 상품 ID
  static const androidProducts = {
    'points_10000': 'com.leapcompany.tripjoy.points_10000',
    'points_20000': 'com.leapcompany.tripjoy.points_20000',
    'points_30000': 'com.leapcompany.tripjoy.points_30000',
    'points_40000': 'com.leapcompany.tripjoy.points_40000',
    'points_50000': 'com.leapcompany.tripjoy.points_50000',
  };

  // App Store 상품 ID
  static const iosProducts = {
    'points_10000': 'com.leapcompany.tripjoy.points.10000',
    'points_20000': 'com.leapcompany.tripjoy.points.20000',
    'points_30000': 'com.leapcompany.tripjoy.points.30000',
    'points_40000': 'com.leapcompany.tripjoy.points.40000',
    'points_50000': 'com.leapcompany.tripjoy.points.50000',
  };

  // 기타 설정
  static const int maxRetryAttempts = 3;
}