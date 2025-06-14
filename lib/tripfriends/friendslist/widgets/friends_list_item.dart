// lib/tripfriends/friendslist/widgets/friends_list_item.dart
import 'package:flutter/material.dart';
import 'friends_profile_item.dart';  // FriendsProfileItem import

class FriendsListItem extends StatelessWidget {
  final Map<String, dynamic> friends;
  final VoidCallback? onTap;

  const FriendsListItem({
    super.key,
    required this.friends,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 데이터 안전 검사
    final uid = friends['uid'] ?? friends['id'] ?? 'unknown';
    final isActive = friends['isActive'] == true;
    final isApproved = friends['isApproved'] == true;

    debugPrint('🎯 FriendsListItem 렌더링: $uid (isActive: $isActive, isApproved: $isApproved)');

    // 필수 필드가 없는 경우 선제적으로 채워넣기
    // Firestore에서 가져온 데이터가 불완전한 경우를 대비
    final Map<String, dynamic> safeData = Map<String, dynamic>.from(friends);

    // isActive가 없는 경우 기본값으로 true 설정
    if (!safeData.containsKey('isActive')) {
      safeData['isActive'] = true;
      debugPrint('⚠️ isActive 필드가 없어 기본값 true 설정: $uid');
    }

    // isApproved가 없는 경우 기본값으로 false 설정
    if (!safeData.containsKey('isApproved')) {
      safeData['isApproved'] = false;
      debugPrint('⚠️ isApproved 필드가 없어 기본값 false 설정: $uid');
    }

    // isActive가 false이거나 isApproved가 false인 경우 빈 컨테이너 반환
    if (!isActive || !isApproved) {
      debugPrint('⛔ 비활성 친구 렌더링 취소: $uid (isActive: $isActive, isApproved: $isApproved)');
      return Container(); // 화면에 표시하지 않음
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FriendsProfileItem(friends: safeData),  // 안전하게 처리된 데이터 전달
      ),
    );
  }
}