// lib/tripfriends/detail/widgets/review/widgets/review_point_item.dart

import 'package:flutter/material.dart';

class ReviewPointItem extends StatelessWidget {
  final String text;
  final int count;
  final bool isGood;
  final int totalPointsCount;
  final int maxCount;
  final int minCount;

  const ReviewPointItem({
    super.key,
    required this.text,
    required this.count,
    required this.isGood,
    required this.totalPointsCount,
    required this.maxCount,
    required this.minCount,
  });

  @override
  Widget build(BuildContext context) {
    // 이모지 추출 (첫 2바이트는 이모지로 간주)
    String emoji = text.substring(0, 2);
    String pointText = text.substring(2);

    // 바 길이 비율 계산 (각 카테고리 내에서의 비율)
    double widthRatio;
    if (totalPointsCount <= 0) {
      widthRatio = 0.2;
    } else {
      widthRatio = 0.2 + (0.8 * count / totalPointsCount);
    }

    // 색상 투명도 계산
    double opacity;
    if (maxCount == minCount) {
      opacity = 0.6;
    } else {
      opacity = 0.2 + (0.8 * (count - minCount) / (maxCount - minCount));
    }

    debugPrint('항목: $text, 카운트: $count, 카테고리: ${isGood ? "좋았던 점" : "아쉬웠던 점"}, '
        '총개수: $totalPointsCount, 범위: $minCount~$maxCount, '
        '바 비율: $widthRatio, 투명도: $opacity');

    // 기본 색상
    final Color colorWithOpacity = isGood
        ? Color.fromRGBO(0xBE, 0xDA, 0xFF, opacity) // Good points 색상
        : Color.fromRGBO(0xFF, 0x96, 0x96, opacity); // Bad points 색상

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      height: 44,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 기본 배경
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF7F7F9),
              ),
            ),
            // 색상 바
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widthRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorWithOpacity,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            // 내용
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pointText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF353535),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isGood ? const Color(0xFF4A90E2) : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}