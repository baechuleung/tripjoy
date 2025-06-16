// lib/point_module/widgets/charge_tab_view.dart

import 'package:flutter/material.dart';
import '../models/point_package.dart';
import 'charge_option_widget.dart';
import 'point_usage_guide_widget.dart';

class ChargeTabView extends StatelessWidget {
  final bool isPurchasing;
  final Function(PointPackage) onChargePressed;

  const ChargeTabView({
    super.key,
    required this.isPurchasing,
    required this.onChargePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9F9F9),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 타이틀
                const Text(
                  '포인트 충전하기',
                  style: TextStyle(
                    color: Color(0xFF353535),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    height: 1.20,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '포인트 충전 시 모든 서비스 이용이 가능합니다.',
                  style: TextStyle(
                    color: Color(0xFF858585),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    height: 1.20,
                  ),
                ),
                const SizedBox(height: 20),

                // 포인트 패키지 리스트 - 하나의 흰색 컨테이너
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      ...PointPackage.packages.map((package) {
                        String emoji = '';
                        String subtitle = '';
                        String badge = '';
                        Color badgeColor = Colors.transparent;

                        if (package.points == 10000) {
                          emoji = '🐤';
                          subtitle = '트립조이 회원이 처음이세요?';
                        } else if (package.points == 20000) {
                          emoji = '✨';
                          subtitle = '가볍게 시작하기';
                        } else if (package.points == 30000) {
                          emoji = '🔥';
                          subtitle = '실시간 제일 많은 포인트';
                          badge = 'HOT';
                          badgeColor = const Color(0xFFFF4B4B);
                        } else if (package.points == 40000) {
                          emoji = '💎';
                          subtitle = '꾸준히 쓰는 인기 포인트';
                          badge = 'BEST';
                          badgeColor = const Color(0xFF4047ED);
                        } else if (package.points == 50000) {
                          emoji = '🚀';
                          subtitle = '프로 유저 포인트';
                        }

                        return Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isPurchasing ? null : () => onChargePressed(package),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    children: [
                                      // 왼쪽 콘텐츠
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (badge.isNotEmpty) ...[
                                                  Container(
                                                    width: badge == 'HOT' ? 35 : 40,
                                                    height: 17,
                                                    decoration: ShapeDecoration(
                                                      color: badge == 'HOT'
                                                          ? const Color(0xFFFFE8E8)
                                                          : const Color(0xFFE8F2FF),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(5),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        badge,
                                                        style: TextStyle(
                                                          color: badge == 'HOT'
                                                              ? const Color(0xFFFF0000)
                                                              : const Color(0xFF0059B7),
                                                          fontSize: 12,
                                                          fontFamily: 'Pretendard',
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                Text(
                                                  subtitle,
                                                  style: const TextStyle(
                                                    color: Color(0xFF4E5968),
                                                    fontSize: 13,
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  emoji,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${package.points ~/ 1000},000P',
                                              style: const TextStyle(
                                                color: Color(0xFF353535),
                                                fontSize: 16,
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 오른쪽 버튼
                                      Container(
                                        width: 80,
                                        height: 32,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFEFEFFF),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '충전하기',
                                            style: TextStyle(
                                              color: Color(0xFF4047ED),
                                              fontSize: 14,
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (package != PointPackage.packages.last)
                              const Divider(
                                color: Color(0xFFECECEC),
                                thickness: 1,
                                height: 1,
                              ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 안내 사항
                const PointUsageGuideWidget(),
              ],
            ),
          ),
          if (isPurchasing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '결제 진행 중...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}