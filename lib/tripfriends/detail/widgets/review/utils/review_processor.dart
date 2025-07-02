// lib/tripfriends/detail/widgets/review/utils/review_processor.dart

import 'package:flutter/material.dart';
import '../models/review_data.dart';

class ReviewProcessor {
  final List<Map<String, dynamic>> reviews;

  ReviewProcessor(this.reviews);

  ProcessedReviewData processReviews() {
    List<String> allGoodPoints = [];
    List<String> allBadPoints = [];

    // 각 리뷰에서 goodPoints와 badPoints 추출
    for (var review in reviews) {
      _extractPoints(review['goodPoints'], allGoodPoints);
      _extractPoints(review['badPoints'], allBadPoints);
    }

    // 포인트 데이터 처리
    List<Map<String, dynamic>> goodPointsData = _processPoints(allGoodPoints, true);
    List<Map<String, dynamic>> badPointsData = _processPoints(allBadPoints, false);

    // 정렬
    goodPointsData.sort((a, b) => b['count'].compareTo(a['count']));
    badPointsData.sort((a, b) => b['count'].compareTo(a['count']));

    // 통계 계산
    int totalGoodPointsCount = allGoodPoints.length;
    int totalBadPointsCount = allBadPoints.length;

    int maxGoodCount = 1;
    int minGoodCount = 1;
    if (goodPointsData.isNotEmpty) {
      maxGoodCount = goodPointsData.map((p) => p['count'] as int).reduce((a, b) => a > b ? a : b);
      minGoodCount = goodPointsData.map((p) => p['count'] as int).reduce((a, b) => a < b ? a : b);
    }

    int maxBadCount = 1;
    int minBadCount = 1;
    if (badPointsData.isNotEmpty) {
      maxBadCount = badPointsData.map((p) => p['count'] as int).reduce((a, b) => a > b ? a : b);
      minBadCount = badPointsData.map((p) => p['count'] as int).reduce((a, b) => a < b ? a : b);
    }

    debugPrint('좋았던 점 개수: $totalGoodPointsCount, 최대: $maxGoodCount, 최소: $minGoodCount');
    debugPrint('아쉬웠던 점 개수: $totalBadPointsCount, 최대: $maxBadCount, 최소: $minBadCount');

    return ProcessedReviewData(
      goodPointsData: goodPointsData,
      badPointsData: badPointsData,
      totalGoodPointsCount: totalGoodPointsCount,
      totalBadPointsCount: totalBadPointsCount,
      maxGoodCount: maxGoodCount,
      minGoodCount: minGoodCount,
      maxBadCount: maxBadCount,
      minBadCount: minBadCount,
      hasMoreItems: badPointsData.isNotEmpty,
    );
  }

  void _extractPoints(dynamic points, List<String> targetList) {
    if (points != null) {
      if (points is List) {
        for (var point in points) {
          if (point is String && point.isNotEmpty) {
            targetList.add(point);
          }
        }
      } else if (points is String && points.isNotEmpty) {
        targetList.add(points);
      }
    }
  }

  List<Map<String, dynamic>> _processPoints(List<String> points, bool isGood) {
    List<Map<String, dynamic>> pointsData = [];

    for (var point in points) {
      int index = pointsData.indexWhere((item) => item['text'] == point);
      if (index >= 0) {
        pointsData[index]['count']++;
      } else {
        pointsData.add({
          'text': point,
          'count': 1,
          'isGood': isGood,
        });
      }
    }

    return pointsData;
  }
}