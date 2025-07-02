// lib/tripfriends/detail/widgets/review/widgets/review_header.dart

import 'package:flutter/material.dart';

class ReviewHeader extends StatelessWidget {
  final int reviewCount;
  final int totalGoodPointsCount;
  final int totalBadPointsCount;

  const ReviewHeader({
    super.key,
    required this.reviewCount,
    required this.totalGoodPointsCount,
    required this.totalBadPointsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          const Text(
            '리뷰',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF353535),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($reviewCount)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
            ),
          ),
          const Spacer(),
          // 좋았던 점 아이콘과 카운트
          Row(
            children: [
              const Icon(
                Icons.thumb_up_outlined,
                size: 16,
                color: Color(0xFF999999),
              ),
              const SizedBox(width: 4),
              Text(
                '$totalGoodPointsCount',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // 아쉬웠던 점 아이콘과 카운트
          Row(
            children: [
              const Icon(
                Icons.thumb_down_outlined,
                size: 16,
                color: Color(0xFF999999),
              ),
              const SizedBox(width: 4),
              Text(
                '$totalBadPointsCount',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}