// lib/tripfriends/friendslist/widgets/friends_list_content.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/friends_list_controller.dart';
import 'friends_list_item.dart';

/// 친구 목록 컨텐츠 관련 클래스 - 주 진입점 (UI 표시 담당)
class FriendsListContent {
  /// 특정 친구 목록만 표시하는 위젯
  static Widget buildSpecificFriendsList(
      FriendsListController controller,
      List<String> friendUserIds,
      Function(BuildContext, Map<String, dynamic>) navigateToDetail,
      {int forceRefreshCounter = 0,
        bool preserveState = false}) {

    // friends_list_view.dart에서 직접 처리하므로 빈 컨테이너 반환
    return Container();
  }

  /// 일반 친구 목록 위젯
  static Widget buildFriendsList(
      BuildContext context,
      FriendsListController controller,
      Function(BuildContext, Map<String, dynamic>) navigateToDetail,
      {int forceRefreshCounter = 0,
        bool preserveState = false}) {

    // friends_list_view.dart에서 직접 처리하므로 빈 컨테이너 반환
    return Container();
  }

  /// 친구 목록 UI 구현
  static Widget buildFriendsListUI(
      List<Map<String, dynamic>> friends,
      BuildContext context,
      Function(BuildContext, Map<String, dynamic>) onFriendTap) {

    if (friends.isEmpty) {
      return Container();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FriendsListItem(
            friends: friends[index],
            onTap: () => onFriendTap(context, friends[index]),
          ),
        );
      },
    );
  }
}