// lib/point_module/models/point_package.dart

class PointPackage {
  final String id;
  final int points;
  final int price;
  final String androidProductId;
  final String iosProductId;
  final double? discountRate;

  PointPackage({
    required this.id,
    required this.points,
    required this.price,
    required this.androidProductId,
    required this.iosProductId,
    this.discountRate,
  });

  // 포인트 패키지 목록
  static List<PointPackage> packages = [
    PointPackage(
      id: 'points_10000',
      points: 10000,
      price: 10000,
      androidProductId: 'com.leapcompany.tripjoy.points_10000',
      iosProductId: 'com.leapcompany.tripjoy.points.10000',
    ),
    PointPackage(
      id: 'points_20000',
      points: 20000,
      price: 20000,
      androidProductId: 'com.leapcompany.tripjoy.points_20000',
      iosProductId: 'com.leapcompany.tripjoy.points.20000',
    ),
    PointPackage(
      id: 'points_30000',
      points: 30000,
      price: 30000,
      androidProductId: 'com.leapcompany.tripjoy.points_30000',
      iosProductId: 'com.leapcompany.tripjoy.points.30000',
    ),
    PointPackage(
      id: 'points_40000',
      points: 40000,
      price: 40000,
      androidProductId: 'com.leapcompany.tripjoy.points_40000',
      iosProductId: 'com.leapcompany.tripjoy.points.40000',
    ),
    PointPackage(
      id: 'points_50000',
      points: 50000,
      price: 50000,
      androidProductId: 'com.leapcompany.tripjoy.points_50000',
      iosProductId: 'com.leapcompany.tripjoy.points.50000',
    ),
  ];
}