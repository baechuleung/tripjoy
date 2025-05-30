import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsOneLineReviews extends StatefulWidget {
  final String tripfriendsId;

  const FriendsOneLineReviews({
    super.key,
    required this.tripfriendsId,
  });

  @override
  State<FriendsOneLineReviews> createState() => _FriendsOneLineReviewsState();
}

class _FriendsOneLineReviewsState extends State<FriendsOneLineReviews> with AutomaticKeepAliveClientMixin {
  bool _expanded = false;
  List<Map<String, dynamic>> _oneLineReviews = [];
  bool _isLoading = true;
  // 사용자 ID별 프로필 사진 URL을 저장하는 맵
  Map<String, String> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _fetchOneLineReviews();
  }

  Future<void> _fetchOneLineReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Firestore에서 리뷰 데이터 가져오기
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(widget.tripfriendsId)
          .collection('reviews')
          .where('oneLineReview', isNull: false)
          .get();

      debugPrint('한줄 리뷰 쿼리 결과 문서 수: ${querySnapshot.docs.length}', wrapWidth: 1024);

      // 가져온 각 문서 데이터 확인
      final reviews = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['oneLineReview'] != null &&
            data['oneLineReview'] is String &&
            (data['oneLineReview'] as String).isNotEmpty;
      }).map((doc) {
        final data = doc.data();
        debugPrint('한줄 리뷰 문서 ID: ${doc.id}, 리뷰: ${data['oneLineReview']}', wrapWidth: 1024);

        return {
          'id': doc.id,
          'oneLineReview': data['oneLineReview'] ?? '',
          'userName': data['userName'] ?? '익명',
          'userId': data['userId'] ?? '',
          'rating': data['rating'] ?? 0.0,
          'createdAt': data['createdAt'] ?? Timestamp.now(),
        };
      }).toList();

      // 날짜순으로 정렬 (최신순)
      reviews.sort((a, b) {
        final timestampA = a['createdAt'] as Timestamp;
        final timestampB = b['createdAt'] as Timestamp;
        return timestampB.compareTo(timestampA);
      });

      setState(() {
        _oneLineReviews = reviews;
      });

      // 각 리뷰 작성자의 프로필 사진 가져오기
      await _fetchUserProfiles();

    } catch (e) {
      debugPrint('한줄 리뷰 데이터 가져오기 오류: $e', wrapWidth: 1024);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 사용자 프로필 사진 가져오기
  Future<void> _fetchUserProfiles() async {
    try {
      // 중복 제거한 사용자 ID 목록 생성
      final userIds = _oneLineReviews
          .map((review) => review['userId'] as String)
          .where((userId) => userId.isNotEmpty)
          .toSet();

      // 각 사용자의 프로필 사진 URL 가져오기
      for (var userId in userIds) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data()!;
            if (userData['photoUrl'] != null) {
              _userProfiles[userId] = userData['photoUrl'] as String;
              debugPrint('사용자 $userId의 프로필 사진 URL: ${_userProfiles[userId]}');
            }
          }
        } catch (e) {
          debugPrint('사용자 $userId의 프로필 가져오기 오류: $e');
        }
      }
    } catch (e) {
      debugPrint('사용자 프로필 가져오기 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    // 한줄 리뷰가 없는 경우
    if (_oneLineReviews.isEmpty) {
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
                children: const [
                  Text(
                    '한줄 리뷰',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF353535),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '(0)',
                    style: TextStyle(
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
                  '아직 작성된 한줄 리뷰가 없습니다.',
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

    // 표시할 리뷰 개수 제한
    final displayReviews = _expanded
        ? _oneLineReviews
        : _oneLineReviews.take(3).toList();
    final hasMore = _oneLineReviews.length > 3;

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
            // 헤더
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
              child: Row(
                children: [
                  const Text(
                    '한줄 리뷰',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF353535),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_oneLineReviews.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),

            // 한줄 리뷰 목록
            for (int i = 0; i < displayReviews.length; i++) ...[
              // 리뷰 아이템
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildOneLineReviewItem(displayReviews[i]),
              ),

              // 마지막 항목이 아니면 구분선 추가 (양쪽 여백 적용)
              if (i < displayReviews.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: const Color(0xFFEEEEEE),
                  ),
                ),
            ],

            // 더보기/접기 버튼
            if (hasMore)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: _toggleExpanded,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? '접기' : '더보기',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF666666),
                        size: 20,
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

  Widget _buildOneLineReviewItem(Map<String, dynamic> review) {
    final String oneLineReview = review['oneLineReview'] as String;
    final String userName = review['userName'] as String;
    final String userId = review['userId'] as String;
    final double rating = (review['rating'] as num).toDouble();
    final Timestamp createdAt = review['createdAt'] as Timestamp;

    // 프로필 이미지 URL 가져오기
    final String? profileUrl = _userProfiles[userId];

    // 날짜 포맷
    final date = createdAt.toDate();
    final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 사용자 정보 및 별점
        Row(
          children: [
            // 프로필 이미지
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEEEEEE),
                image: profileUrl != null && profileUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(profileUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: profileUrl == null || profileUrl.isEmpty
                  ? const Icon(
                Icons.person,
                size: 20,
                color: Color(0xFF999999),
              )
                  : null,
            ),
            // 사용자 이름 (첫 2글자만 표시)
            Text(
              userName.length > 2 ? '${userName.substring(0, 2)}***' : '$userName***',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF353535),
              ),
            ),
            const Spacer(),
            // 별점
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: index < rating ? Colors.amber : Colors.grey[300],
                  size: 16,
                );
              }),
            ),
            const SizedBox(width: 8),
            // 날짜
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 한줄 리뷰 내용
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            oneLineReview,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}