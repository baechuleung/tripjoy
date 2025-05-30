// screens/friends_detail_page.dart
import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import 'friends_profile_detail.dart';
import 'friends_reviews.dart';
import 'friends_one_line_reviews.dart';  // 한줄 리뷰 위젯 임포트
import 'friends_introduction.dart';
import 'friends_reservation_button.dart';
import 'friends_payment_amount.dart';  // 새로운 위젯 임포트

class FriendsDetailPage extends StatefulWidget {
  final Map<String, dynamic> friends;

  const FriendsDetailPage({
    super.key,
    required this.friends,
  });

  @override
  State<FriendsDetailPage> createState() => _FriendsDetailPageState();
}

class _FriendsDetailPageState extends State<FriendsDetailPage> {
  final TranslationService _translationService = TranslationService();
  bool _isTranslationsLoaded = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    if (_isDisposed) return;
    await _translationService.loadTranslations();
    if (mounted && !_isDisposed) {
      setState(() {
        _isTranslationsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomSpace = bottomPadding + 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          _isTranslationsLoaded
              ? _translationService.getTranslatedText('상세 정보')
              : '상세 정보',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 스크롤 가능한 콘텐츠 영역
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 프로필 정보
                    FriendsProfileDetail(friends: widget.friends),
                    const SizedBox(height: 8),

                    // 일반 콘텐츠 표시
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: FriendsIntroduction(friends: widget.friends),
                        ),
                        const SizedBox(height: 8),
                        // 현장 결제 금액 섹션 추가
                        FriendsPaymentAmount(friends: widget.friends),
                        const SizedBox(height: 8),
                        FriendsReviewsSection(
                          key: const ValueKey('friends_reviews_section'),
                          tripfriendsId: widget.friends['uid'],
                        ),
                        const SizedBox(height: 8),
                        // 한줄 리뷰 섹션
                        FriendsOneLineReviewsSection(
                          key: const ValueKey('friends_one_line_reviews_section'),
                          tripfriendsId: widget.friends['uid'],
                        ),
                        const SizedBox(height: 8),
                      ],
                    )
                  ],
                ),
              ),
            ),
            // 무조건 화면 맨 아래에 고정
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FriendsReservationButton(friends_uid: widget.friends['uid']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

// 한줄 리뷰 섹션 위젯
class FriendsOneLineReviewsSection extends StatelessWidget {
  final String tripfriendsId;

  const FriendsOneLineReviewsSection({
    super.key,
    required this.tripfriendsId,
  });

  @override
  Widget build(BuildContext context) {
    return FriendsOneLineReviews(tripfriendsId: tripfriendsId);
  }
}

// 리뷰 섹션을 별도의 위젯으로 분리
class FriendsReviewsSection extends StatelessWidget {
  final String tripfriendsId;

  const FriendsReviewsSection({
    super.key,
    required this.tripfriendsId,
  });

  @override
  Widget build(BuildContext context) {
    return FriendsReviews(tripfriendsId: tripfriendsId);
  }
}