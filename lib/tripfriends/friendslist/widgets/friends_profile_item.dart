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
          SizedBox(
            height: 120,
            width: double.infinity,
            child: _ProfileImage(friends: friends),
          ),
          const SizedBox(height: 2),
          _FriendsInfo(
              friends: friends,
              currencySymbol: currencySymbol,
              numberFormat: numberFormat
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image(
        image: _getProfileImage(),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.person,
              color: Colors.grey,
              size: 40,
            ),
          );
        },
      ),
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

  int _calculateAgeFromValues(int year, int month, int day) {
    if (year <= 0 || month <= 0 || day <= 0) return 0;

    final now = DateTime.now();
    final birthDate = DateTime(year, month, day);

    int age = now.year - birthDate.year;

    // 생일이 지나지 않았으면 1살 빼기
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름
          SizedBox(
            width: double.infinity,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 2),

          // 나이(성별)
          Text(
            '$age세($gender)',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}