// lib/tripfriends/friendslist/widgets/friends_list_header.dart
import 'package:flutter/material.dart';

/// 친구 목록 헤더와 필터 버튼
class FriendsListHeader extends StatefulWidget {
  final VoidCallback onFilterTap;
  final int friendsCount;

  const FriendsListHeader({
    Key? key,
    required this.onFilterTap,
    this.friendsCount = 0,
  }) : super(key: key);

  @override
  State<FriendsListHeader> createState() => _FriendsListHeaderState();
}

class _FriendsListHeaderState extends State<FriendsListHeader> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 헤더 (왼쪽에 배치)
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 4),
                  const Text(
                    '현재 추천받은 프렌즈',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.friendsCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3182F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.friendsCount}명',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // 필터 버튼 (오른쪽에 배치)
              InkWell(
                onTap: widget.onFilterTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: Color(0xFFD9D9D9)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 16, color: Color(0xFF4E5968)),
                      const SizedBox(width: 4),
                      Text(
                        '필터',
                        style: TextStyle(
                          color: Color(0xFF4E5968),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}