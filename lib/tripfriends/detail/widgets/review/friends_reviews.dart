import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsReviews extends StatefulWidget {
  final String tripfriendsId;
  // 데이터를 직접 전달받는 대신 ID만 받아서 위젯 내부에서 쿼리

  const FriendsReviews({
    super.key,
    required this.tripfriendsId,
  });

  @override
  State<FriendsReviews> createState() => _FriendsReviewsState();
}

class _FriendsReviewsState extends State<FriendsReviews> with AutomaticKeepAliveClientMixin {
  bool _expanded = false;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 직접 Firestore에서 리뷰 데이터 가져오기
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(widget.tripfriendsId)
          .collection('reviews')
          .get();

      debugPrint('쿼리 결과 문서 수: ${querySnapshot.docs.length}', wrapWidth: 1024);

      // 가져온 각 문서 데이터 확인
      final reviews = querySnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('문서 ID: ${doc.id}, 데이터: $data', wrapWidth: 1024);

        // 전체 필드 목록 확인
        debugPrint('필드 목록: ${data.keys.toList().join(", ")}', wrapWidth: 1024);

        // goodPoints와 badPoints 필드 특별 확인
        if (data.containsKey('goodPoints')) {
          debugPrint('goodPoints 존재: ${data['goodPoints']}', wrapWidth: 1024);
        } else {
          debugPrint('goodPoints 필드 없음', wrapWidth: 1024);
        }

        if (data.containsKey('badPoints')) {
          debugPrint('badPoints 존재: ${data['badPoints']}', wrapWidth: 1024);
        } else {
          debugPrint('badPoints 필드 없음', wrapWidth: 1024);
        }

        // 모든 필드를 포함하는 Map 반환
        return {
          ...data,
          'goodPoints': data['goodPoints'] ?? [],
          'badPoints': data['badPoints'] ?? [],
        };
      }).toList();

      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('리뷰 데이터 가져오기 오류: $e', wrapWidth: 1024);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 로딩 중일 때
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // 리뷰가 없는 경우
    if (_reviews.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    '(0)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '아직 작성된 리뷰가 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // DB에서 모든 goodPoints와 badPoints 수집
    List<String> allGoodPoints = [];
    List<String> allBadPoints = [];

    // 각 리뷰에서 goodPoints와 badPoints 추출
    for (var review in _reviews) {
      var goodPoints = review['goodPoints'];
      if (goodPoints != null) {
        if (goodPoints is List) {
          for (var point in goodPoints) {
            if (point is String && point.isNotEmpty) {
              allGoodPoints.add(point);
            }
          }
        } else if (goodPoints is String && goodPoints.isNotEmpty) {
          allGoodPoints.add(goodPoints);
        }
      }

      var badPoints = review['badPoints'];
      if (badPoints != null) {
        if (badPoints is List) {
          for (var point in badPoints) {
            if (point is String && point.isNotEmpty) {
              allBadPoints.add(point);
            }
          }
        } else if (badPoints is String && badPoints.isNotEmpty) {
          allBadPoints.add(badPoints);
        }
      }
    }

    // 각 포인트가 몇 번 등장했는지 계산 및 구분 정보 함께 저장
    List<Map<String, dynamic>> goodPointsData = [];
    List<Map<String, dynamic>> badPointsData = [];

    // goodPoints 처리
    for (var point in allGoodPoints) {
      int index = goodPointsData.indexWhere((item) => item['text'] == point);
      if (index >= 0) {
        goodPointsData[index]['count']++;
      } else {
        goodPointsData.add({
          'text': point,
          'count': 1,
          'isGood': true,
        });
      }
    }

    // badPoints 처리
    for (var point in allBadPoints) {
      int index = badPointsData.indexWhere((item) => item['text'] == point);
      if (index >= 0) {
        badPointsData[index]['count']++;
      } else {
        badPointsData.add({
          'text': point,
          'count': 1,
          'isGood': false,
        });
      }
    }

    // 각각 카운트에 따라 정렬 (내림차순)
    goodPointsData.sort((a, b) => b['count'].compareTo(a['count']));
    badPointsData.sort((a, b) => b['count'].compareTo(a['count']));

    // 좋았던 점 총 개수
    int totalGoodPointsCount = allGoodPoints.length;

    // 아쉬웠던 점 총 개수
    int totalBadPointsCount = allBadPoints.length;

    // 좋았던 점 최대/최소 카운트
    int maxGoodCount = 1;
    int minGoodCount = 1;

    if (goodPointsData.isNotEmpty) {
      maxGoodCount = goodPointsData.map((p) => p['count'] as int).reduce((a, b) => a > b ? a : b);
      minGoodCount = goodPointsData.map((p) => p['count'] as int).reduce((a, b) => a < b ? a : b);
    }

    // 아쉬웠던 점 최대/최소 카운트
    int maxBadCount = 1;
    int minBadCount = 1;

    if (badPointsData.isNotEmpty) {
      maxBadCount = badPointsData.map((p) => p['count'] as int).reduce((a, b) => a > b ? a : b);
      minBadCount = badPointsData.map((p) => p['count'] as int).reduce((a, b) => a < b ? a : b);
    }

    // 더보기 버튼 표시 여부 결정
    bool hasMoreItems = badPointsData.isNotEmpty;

    debugPrint('좋았던 점 개수: $totalGoodPointsCount, 최대: $maxGoodCount, 최소: $minGoodCount');
    debugPrint('아쉬웠던 점 개수: $totalBadPointsCount, 최대: $maxBadCount, 최소: $minBadCount');

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
            // 헤더 (컨테이너 안으로 이동)
            Padding(
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
                    '(${_reviews.length})',
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
            ),

            // 포인트 목록
            Column(
              children: [
                // 좋았던 점 헤더
                if (goodPointsData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Row(
                      children: [
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
                ...goodPointsData.map((item) => _buildPointItem(
                  item['text'],
                  item['count'],
                  true, // isGood
                  totalPointsCount: totalGoodPointsCount,
                  maxCount: maxGoodCount,
                  minCount: minGoodCount,
                )),
                // 아쉬웠던 점 헤더
                if (_expanded && badPointsData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Row(
                      children: [
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

                if (_expanded)
                  ...badPointsData.map((item) => _buildPointItem(
                    item['text'],
                    item['count'],
                    false, // isGood
                    totalPointsCount: totalBadPointsCount,
                    maxCount: maxBadCount,
                    minCount: minBadCount,
                  )),

                // 더 보여줄 항목이 있을 경우에만 더보기/접기 버튼 표시
                if (hasMoreItems)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: _toggleExpanded,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                // 포인트가 없는 경우 디버그 정보
                if (goodPointsData.isEmpty && badPointsData.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("리뷰 데이터 디버그 정보:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("리뷰 수: ${_reviews.length}"),
                        const SizedBox(height: 4),
                        if (_reviews.isNotEmpty) ...[
                          Text("첫 번째 리뷰 키: ${_reviews.first.keys.toList().join(', ')}"),
                          const SizedBox(height: 8),
                          ..._reviews.first.entries.map((e) =>
                              Text("${e.key}: ${e.value} (${e.value.runtimeType})")
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointItem(String text, int count, bool isGood, {
    required int totalPointsCount,
    required int maxCount,
    required int minCount,
  }) {
    // 이모지 추출 (첫 2바이트는 이모지로 간주)
    String emoji = text.substring(0, 2);
    String pointText = text.substring(2);

    // 바 길이 비율 계산 (각 카테고리 내에서의 비율)
    double widthRatio;

    if (totalPointsCount <= 0) {
      // 포인트가 없는 경우 기본값
      widthRatio = 0.2;
    } else {
      // 최소 20%, 최대 100% 범위 내에서 비율 계산
      widthRatio = 0.2 + (0.8 * count / totalPointsCount);
    }

    // 색상 투명도 계산 - 카테고리 내 카운트 범위에서 위치 계산
    // 최대 카운트일 경우 1.0, 최소 카운트일 경우 0.2
    double opacity;
    if (maxCount == minCount) {
      // 카운트 범위가 없으면 0.6 (중간값) 사용
      opacity = 0.6;
    } else {
      // 카운트 범위 내에서 선형 보간
      opacity = 0.2 + (0.8 * (count - minCount) / (maxCount - minCount));
    }

    debugPrint('항목: $text, 카운트: $count, 카테고리: ${isGood ? "좋았던 점" : "아쉬웠던 점"}, '
        '총개수: $totalPointsCount, 범위: $minCount~$maxCount, '
        '바 비율: $widthRatio, 투명도: $opacity');

    // 기본 색상
    final Color colorWithOpacity = isGood
        ? Color.fromRGBO(0xBE, 0xDA, 0xFF, opacity) // Good points 색상 (0xFFBEDAFF)
        : Color.fromRGBO(0xFF, 0x96, 0x96, opacity); // Bad points 색상 (0xFFFF9696)

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      height: 44, // 고정 높이 설정
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 기본 배경 (F7F7F9 색상)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF7F7F9),
              ),
            ),

            // 색상 바 (비율에 따라 너비 제한)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widthRatio, // 비율에 따라 너비 제한
                child: Container(
                  decoration: BoxDecoration(
                    color: colorWithOpacity,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // 내용 (수직 가운데 정렬)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center, // 수직 가운데 정렬
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