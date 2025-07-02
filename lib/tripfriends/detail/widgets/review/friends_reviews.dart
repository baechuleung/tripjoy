// lib/tripfriends/detail/widgets/review/friends_reviews.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/review_data.dart';
import 'widgets/review_loading.dart';
import 'widgets/review_empty.dart';
import 'widgets/review_content.dart';
import 'utils/review_processor.dart';

class FriendsReviews extends StatefulWidget {
  final String tripfriendsId;

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
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(widget.tripfriendsId)
          .collection('reviews')
          .get();

      debugPrint('쿼리 결과 문서 수: ${querySnapshot.docs.length}', wrapWidth: 1024);

      final reviews = querySnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('문서 ID: ${doc.id}, 데이터: $data', wrapWidth: 1024);
        debugPrint('필드 목록: ${data.keys.toList().join(", ")}', wrapWidth: 1024);

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

    if (_isLoading) {
      return const ReviewLoading();
    }

    if (_reviews.isEmpty) {
      return const ReviewEmpty();
    }

    // 리뷰 데이터 처리
    final processor = ReviewProcessor(_reviews);
    final processedData = processor.processReviews();

    // 디버그 정보 출력
    debugPrint("좋은 리뷰 개수: ${processedData.goodPointsData.length}", wrapWidth: 1024);
    debugPrint("나쁜 리뷰 개수: ${processedData.badPointsData.length}", wrapWidth: 1024);
    debugPrint("hasMoreItems: ${processedData.hasMoreItems}", wrapWidth: 1024);

    if (processedData.goodPointsData.isEmpty && processedData.badPointsData.isEmpty) {
      debugPrint("리뷰 데이터 디버그 정보:", wrapWidth: 1024);
      debugPrint("리뷰 수: ${_reviews.length}", wrapWidth: 1024);
      if (_reviews.isNotEmpty) {
        debugPrint("첫 번째 리뷰 키: ${_reviews.first.keys.toList().join(', ')}", wrapWidth: 1024);
        for (var e in _reviews.first.entries) {
          debugPrint("${e.key}: ${e.value} (${e.value.runtimeType})", wrapWidth: 1024);
        }
      }
    }

    return ReviewContent(
      reviewCount: _reviews.length,
      processedData: processedData,
      expanded: _expanded,
      onToggleExpanded: _toggleExpanded,
    );
  }
}