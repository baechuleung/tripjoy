// lib/tripfriends/friendslist/widgets/friends_profile_item.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/translation_service.dart';
import 'package:intl/intl.dart';

class FriendsProfileItem extends StatelessWidget {
  final Map<String, dynamic> friends;

  const FriendsProfileItem({
    super.key,
    required this.friends,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = friends['currencySymbol'] ?? '';
    final NumberFormat numberFormat = NumberFormat('#,###');

    // 디버깅 - 전체 필드 로그 출력
    debugPrint('🔍 FriendsProfileItem 데이터: ${friends.keys.join(', ')}');

    // isActive, isApproved 로깅
    final uid = friends['uid'] ?? friends['id'] ?? 'unknown';
    final isActive = friends['isActive'] == true;
    final isApproved = friends['isApproved'] == true;
    debugPrint('👤 FriendsProfileItem: $uid 상태 - isActive=$isActive, isApproved=$isApproved');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ProfileImage(friends: friends),
              const SizedBox(width: 12),
              Expanded(child: _FriendsInfo(
                  friends: friends,
                  currencySymbol: currencySymbol,
                  numberFormat: numberFormat
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final Map<String, dynamic> friends;

  const _ProfileImage({required this.friends});

  @override
  Widget build(BuildContext context) {
    // 이미지 URL 가져오기 (다양한 필드명에 대응)
    final String uid = friends['uid'] ?? friends['id'] ?? 'unknown';

    return Stack(
      children: [
        Container(
          width: 70,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: _getProfileImage(),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider _getProfileImage() {
    // 여러 가능한 필드명 시도 (다양한 필드명에 대응)
    final profileUrl = friends['profileImageUrl'] ??
        friends['profileImage'] ??
        friends['photoURL'] ??
        friends['photoUrl'] ??
        '';

    debugPrint('🖼️ 프로필 이미지 URL: $profileUrl');

    return (profileUrl != null && profileUrl.toString().isNotEmpty)
        ? NetworkImage(profileUrl)
        : const NetworkImage(
        'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y');
  }
}

class _FriendsInfo extends StatefulWidget {
  final Map<String, dynamic> friends;
  final String currencySymbol;
  final NumberFormat numberFormat;

  const _FriendsInfo({
    required this.friends,
    required this.currencySymbol,
    required this.numberFormat,
  });

  @override
  State<_FriendsInfo> createState() => _FriendsInfoState();
}

class _FriendsInfoState extends State<_FriendsInfo> {
  final TranslationService _translationService = TranslationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _numberFormat = NumberFormat('#,###');
  bool _isTranslationsLoaded = false;
  bool _isDisposed = false;
  int _reviewCount = 0;
  List<String> _translatedLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadTranslations();
    _loadCounts();
  }

  Future<void> _loadTranslations() async {
    if (_isDisposed) return;
    await _translationService.loadTranslations();

    if (mounted && !_isDisposed) {
      // 언어 데이터 가져오기 및 번역
      List<String> languages = [];
      final List<dynamic> languagesList = widget.friends['languages'] ?? [];

      for (final language in languagesList) {
        if (language != null) {
          String translatedLanguage = _translationService.getTranslatedText(language.toString());
          languages.add(translatedLanguage);
        }
      }

      setState(() {
        _isTranslationsLoaded = true;
        _translatedLanguages = languages;
      });
    }
  }

  Future<void> _loadCounts() async {
    if (_isDisposed) return;

    try {
      final uid = widget.friends['uid'] ?? widget.friends['id'];
      if (uid == null) {
        debugPrint('⚠️ 사용자 ID를 찾을 수 없음');
        return;
      }

      final userRef = _firestore.collection('tripfriends_users').doc(uid);

      // 리뷰 문서들 가져오기
      final reviewsSnapshot = await userRef.collection('reviews').get();

      if (reviewsSnapshot.docs.isNotEmpty && mounted && !_isDisposed) {
        // 리뷰 수 설정
        setState(() {
          _reviewCount = reviewsSnapshot.docs.length;
        });

        // 평균 평점 계산
        double totalRating = 0;
        for (var doc in reviewsSnapshot.docs) {
          final rating = doc.data()['rating'];
          if (rating is num) {
            totalRating += rating.toDouble();
          }
        }
        double averageRating = totalRating / reviewsSnapshot.docs.length;

        try {
          // 평균 평점 업데이트
          await userRef.update({
            'average_rating': double.parse(averageRating.toStringAsFixed(1))
          });
        } catch (e) {
          debugPrint('⚠️ 평점 업데이트 실패: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ 카운트 로딩 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return Container();

    // 이름 필드 여러 가능성 처리
    final String name = widget.friends['name'] ??
        widget.friends['displayName'] ??
        widget.friends['display_name'] ??
        widget.friends['userName'] ??
        '이름 없음';

    // 나이 계산 - 안전하게 처리
    int age = 0;
    final birthDate = widget.friends['birthDate'];
    if (birthDate != null) {
      try {
        // birthDate가 Map<dynamic, dynamic>일 수 있으므로 안전하게 처리
        if (birthDate is Map) {
          // birthDate를 직접 Map<dynamic, dynamic>으로 처리
          int year = 0;
          int month = 0;
          int day = 0;

          if (birthDate.containsKey('year')) {
            final yearValue = birthDate['year'];
            if (yearValue is int) year = yearValue;
          }

          if (birthDate.containsKey('month')) {
            final monthValue = birthDate['month'];
            if (monthValue is int) month = monthValue;
          }

          if (birthDate.containsKey('day')) {
            final dayValue = birthDate['day'];
            if (dayValue is int) day = dayValue;
          }

          age = _calculateAgeFromValues(year, month, day);
        }
      } catch (e) {
        debugPrint('⚠️ 생년월일 처리 오류: $e');
      }
    } else {
      debugPrint('⚠️ 생년월일 정보 없음');
    }

    // 성별 처리
    final String genderEn = widget.friends['gender'] ?? '';

    // 성별 한국어로 변환
    String gender = '성별 정보 없음';
    if (genderEn.toLowerCase() == 'male') {
      gender = '남성';
    } else if (genderEn.toLowerCase() == 'female') {
      gender = '여성';
    } else if (genderEn.isNotEmpty) {
      gender = genderEn;
    }

    // 평점 안전하게 가져오기
    final rating = widget.friends['average_rating'];
    final ratingDisplay = rating != null ? '$rating/5' : '0/5';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 첫 번째 줄: 이름
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),

        // 두 번째 줄: 별점, 나이(성별)
        Row(
          children: [
            // 별점 표시
            const Icon(Icons.star, size: 14, color: Color(0xFFFFD233)),
            const SizedBox(width: 2),
            Text(
              ratingDisplay,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              ' (${_numberFormat.format(_reviewCount)})',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(width: 8),

            // 나이(성별)
            Text(
              '$age세($gender)',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 세 번째 줄: 언어 (컨테이너 스타일)
        if (_translatedLanguages.isNotEmpty)
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _translatedLanguages.map((language) =>
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE8F2FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        language,
                        style: const TextStyle(
                          color: Color(0xFF3182F6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
            ).toList(),
          )
        else
          Row(
            children: [
              const Icon(Icons.language, size: 14, color: Color(0xFF009688)),
              const SizedBox(width: 4),
              Text(
                '언어 정보 없음',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // 새로운 메서드: 년, 월, 일 값으로부터 나이 계산
  int _calculateAgeFromValues(int year, int month, int day) {
    try {
      if (year <= 0 || month <= 0 || day <= 0) {
        return 0;
      }

      final now = DateTime.now();
      final birth = DateTime(year, month, day);

      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age > 0 ? age : 0;
    } catch (e) {
      debugPrint('⚠️ 나이 계산 오류: $e');
      return 0;
    }
  }
}