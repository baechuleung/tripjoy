import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../point_module/screens/point_page.dart';
import '../../../../point_module/screens/point_usage_info_page.dart';

class PointChargeSection extends StatelessWidget {
  final int points;

  const PointChargeSection({
    Key? key,
    required this.points,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 상단: 보유 포인트
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PointUsageInfoPage(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Image.asset(
                      'assets/point/point_icon.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '보유 포인트',
                      style: TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.help_outline,
                      size: 16,
                      color: Color(0xFF999999),
                    ),
                  ],
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(points)}P',
                style: const TextStyle(
                  color: Color(0xFF353535),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),

          // 하단: 사용내역, 충전하기
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PointPage(initialTabIndex: 1),
                    ),
                  );
                },
                child: Container(
                  width: 65,
                  height: 30,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '사용내역',
                      style: TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PointPage(initialTabIndex: 0),
                    ),
                  );
                },
                child: Container(
                  width: 65,
                  height: 30,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF3672E0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '충전하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}