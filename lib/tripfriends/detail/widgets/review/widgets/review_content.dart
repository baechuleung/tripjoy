// lib/tripfriends/detail/widgets/review/widgets/review_content.dart

import 'package:flutter/material.dart';
import '../models/review_data.dart';
import 'review_header.dart';
import 'review_point_item.dart';
import 'review_expand_button.dart';

class ReviewContent extends StatelessWidget {
  final int reviewCount;
  final ProcessedReviewData processedData;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const ReviewContent({
    super.key,
    required this.reviewCount,
    required this.processedData,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReviewHeader(
              reviewCount: reviewCount,
              totalGoodPointsCount: processedData.totalGoodPointsCount,
              totalBadPointsCount: processedData.totalBadPointsCount,
            ),
            Column(
              children: [
                // 좋았던 점 헤더
                if (processedData.goodPointsData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.thumb_up,
                          size: 18,
                          color: Color(0xFF4A90E2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '좋았던 점',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A90E2),
                          ),
                        ),
                      ],
                    ),
                  ),
                // 좋았던 점 목록
                ...processedData.goodPointsData.map((item) => ReviewPointItem(
                  text: item['text'],
                  count: item['count'],
                  isGood: true,
                  totalPointsCount: processedData.totalGoodPointsCount,
                  maxCount: processedData.maxGoodCount,
                  minCount: processedData.minGoodCount,
                )),
                // 아쉬웠던 점 헤더
                if (expanded && processedData.badPointsData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.thumb_down,
                          size: 18,
                          color: Color(0xFFFF6B6B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '아쉬웠던 점',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (expanded)
                  ...processedData.badPointsData.map((item) => ReviewPointItem(
                    text: item['text'],
                    count: item['count'],
                    isGood: false,
                    totalPointsCount: processedData.totalBadPointsCount,
                    maxCount: processedData.maxBadCount,
                    minCount: processedData.minBadCount,
                  )),
                // 더보기/접기 버튼 - 리뷰가 1개 이상 있으면 항상 표시
                if (reviewCount > 0)
                  ReviewExpandButton(
                    expanded: expanded,
                    onTap: onToggleExpanded,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}