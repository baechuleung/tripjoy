// lib/tripfriends/detail/widgets/review/models/review_data.dart

class ReviewPoint {
  final String text;
  final int count;
  final bool isGood;

  ReviewPoint({
    required this.text,
    required this.count,
    required this.isGood,
  });
}

class ProcessedReviewData {
  final List<Map<String, dynamic>> goodPointsData;
  final List<Map<String, dynamic>> badPointsData;
  final int totalGoodPointsCount;
  final int totalBadPointsCount;
  final int maxGoodCount;
  final int minGoodCount;
  final int maxBadCount;
  final int minBadCount;
  final bool hasMoreItems;

  ProcessedReviewData({
    required this.goodPointsData,
    required this.badPointsData,
    required this.totalGoodPointsCount,
    required this.totalBadPointsCount,
    required this.maxGoodCount,
    required this.minGoodCount,
    required this.maxBadCount,
    required this.minBadCount,
    required this.hasMoreItems,
  });
}