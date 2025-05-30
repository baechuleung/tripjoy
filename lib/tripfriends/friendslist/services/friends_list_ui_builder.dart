// lib/tripfriends/friendslist/services/friends_list_ui_builder.dart
import 'package:flutter/material.dart';
import '../widgets/friends_list_item.dart';
import '../services/friends_request_handler.dart';
import '../controllers/friends_list_controller.dart';

/// 친구 목록 UI 구현을 담당하는 클래스
class FriendsListUIBuilder {
  /// 친구 목록 UI 구현
  static Widget buildFriendsList(
      List<Map<String, dynamic>> friends,
      BuildContext context,
      Function(BuildContext, Map<String, dynamic>) onFriendTap,
      ) {

    // 데이터가 없으면 빈 컨테이너 반환 (정상적으로는 이 부분이 실행되지 않아야 함)
    if (friends.isEmpty) {
      debugPrint('⚠️ buildFriendsList: 빈 친구 목록이 전달됨');
      return Container();
    }

    // isActive, isApproved 상태 확인
    final List<Map<String, dynamic>> validFriends = [];

    for (var friend in friends) {
      final uid = friend['uid'] ?? friend['id'] ?? 'unknown';

      // 기본값 설정: isActive는 true, isApproved는 false
      bool isActive = friend['isActive'] == true;
      bool isApproved = friend['isApproved'] == true;

      // 필드가 존재하지 않는 경우 처리
      if (!friend.containsKey('isActive')) {
        friend['isActive'] = true;
        isActive = true;
        debugPrint('⚠️ isActive 필드가 없어 기본값 true 설정: $uid');
      }

      if (!friend.containsKey('isApproved')) {
        friend['isApproved'] = false;
        isApproved = false;
        debugPrint('⚠️ isApproved 필드가 없어 기본값 false 설정: $uid');
      }

      debugPrint('👤 친구 $uid 상태: isActive=${isActive ? '활성화(true)' : '비활성화(false)'}, isApproved=${isApproved ? '승인됨(true)' : '미승인(false)'}');

      // 두 값이 모두 true인 경우에만 유효한 프렌즈로 추가
      if (isActive && isApproved) {
        validFriends.add(friend);
      }
    }

    // 유효한 프렌즈가 없는 경우 빈 컨테이너 반환
    if (validFriends.isEmpty) {
      debugPrint('🚫 유효한 프렌즈 없음: isActive 또는 isApproved가 false인 프렌즈만 있음');
      return Container();
    }

    debugPrint('👁️ 유효한 프렌즈: ${validFriends.length}명');

    // 중요: 모든 validFriends의 상태 로깅 - 디버깅용
    for (var friend in validFriends) {
      final uid = friend['uid'] ?? friend['id'] ?? 'unknown';
      debugPrint('✓ 표시할 유효한 친구: $uid, isActive=${friend['isActive']}, isApproved=${friend['isApproved']}');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: validFriends.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12), // 아이템 간 간격
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: FriendsListItem(
              friends: validFriends[index],
              onTap: () => onFriendTap(context, validFriends[index]),
            ),
          );
        },
      ),
    );
  }

  /// 친구 목록 UI 구현 (친구 없음 메시지 포함)
  static Widget buildFriendsListWithEmptyMessage(
      List<Map<String, dynamic>> friends,
      BuildContext context,
      Function(BuildContext, Map<String, dynamic>) onFriendTap,
      FriendsListController controller
      ) {

    // 데이터가 없으면 친구 없음 메시지 표시
    if (friends.isEmpty) {
      debugPrint('⚠️ buildFriendsListWithEmptyMessage: 빈 친구 목록이 전달됨');
      return FriendsRequestHandler.buildEmptyListMessage(controller);
    }

    // isActive, isApproved 상태 확인 및 필터링
    final List<Map<String, dynamic>> validFriends = [];

    debugPrint('👁️ 친구 목록 필터링 시작 (총 ${friends.length}명)');

    for (var friend in friends) {
      final uid = friend['uid'] ?? friend['id'] ?? 'unknown';

      // 기본값 설정: isActive는 true, isApproved는 false
      bool isActive = friend['isActive'] == true;
      bool isApproved = friend['isApproved'] == true;

      // 필드가 존재하지 않는 경우 처리
      if (!friend.containsKey('isActive')) {
        friend['isActive'] = true;
        isActive = true;
        debugPrint('⚠️ isActive 필드가 없어 기본값 true 설정: $uid');
      }

      if (!friend.containsKey('isApproved')) {
        friend['isApproved'] = false;
        isApproved = false;
        debugPrint('⚠️ isApproved 필드가 없어 기본값 false 설정: $uid');
      }

      debugPrint('👤 친구 $uid 상태 체크: isActive=${isActive ? '활성화(true)' : '비활성화(false)'}, isApproved=${isApproved ? '승인됨(true)' : '미승인(false)'}');

      // 두 값이 모두 true인 경우에만 유효한 프렌즈로 추가
      if (isActive && isApproved) {
        validFriends.add(friend);
        debugPrint('✓ 유효한 친구 추가됨: $uid');
      } else {
        debugPrint('✗ 유효하지 않은 친구 제외: $uid (isActive: $isActive, isApproved: $isApproved)');
      }
    }

    // 유효한 프렌즈가 없는 경우 친구 없음 메시지 표시
    if (validFriends.isEmpty) {
      debugPrint('🚫 유효한 프렌즈 없음: isActive 또는 isApproved가 false인 프렌즈만 있음');
      return FriendsRequestHandler.buildEmptyListMessage(controller);
    }

    debugPrint('👁️ 유효한 프렌즈: ${validFriends.length}명 (필터링 후)');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: validFriends.length,
        itemBuilder: (context, index) {
          final friend = validFriends[index];
          final uid = friend['uid'] ?? friend['id'] ?? 'unknown';
          debugPrint('🖼️ 친구 UI 렌더링: $uid');

          return Container(
            margin: const EdgeInsets.only(bottom: 12), // 아이템 간 간격
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: FriendsListItem(
              friends: friend,
              onTap: () => onFriendTap(context, friend),
            ),
          );
        },
      ),
    );
  }
}