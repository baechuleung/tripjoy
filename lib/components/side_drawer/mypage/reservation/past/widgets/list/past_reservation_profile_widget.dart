import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripjoy/tripfriends/detail/screens/friends_detail_page.dart';

/// 프렌즈 프로필 정보를 표시하는 위젯
class PastReservationProfileWidget extends StatelessWidget {
  final String friendsId;

  const PastReservationProfileWidget({
    Key? key,
    required this.friendsId,
  }) : super(key: key);

  // 프렌즈 상세 페이지로 이동
  Future<void> _navigateToFriendsDetailPage(BuildContext context, Map<String, dynamic> friendsData) async {
    try {
      if (context.mounted) {
        // 프렌즈 상세 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendsDetailPage(
              friends: friendsData,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프렌즈 상세 페이지 이동 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(friendsId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 50,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return SizedBox(); // 데이터가 없으면 빈 공간 표시
        }

        final friendsData = snapshot.data!.data() as Map<String, dynamic>;
        final String profileImageUrl = friendsData['profileImageUrl'] ?? '';
        final String name = friendsData['name'] ?? '프렌즈';

        // 평점 정보
        final double rating = (friendsData['average_rating'] ?? 0).toDouble();
        final int reviewCount = friendsData['review_count'] ?? 0;

        // 나이 계산 (birthDate가 있는 경우만)
        int age = 0;
        if (friendsData['birthDate'] != null && friendsData['birthDate'] is Map) {
          final birthDateMap = friendsData['birthDate'] as Map;
          if (birthDateMap.containsKey('year')) {
            age = DateTime.now().year - (birthDateMap['year'] as int);
          }
        }

        final String gender = friendsData['gender'] == 'male' ? '남성' : '여성';

        return InkWell(
          onTap: () => _navigateToFriendsDetailPage(context, friendsData),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 프로필 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    profileImageUrl.isNotEmpty
                        ? profileImageUrl
                        : "https://placehold.co/80x90",
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                // 오른쪽 정보들
                Expanded(
                  child: SizedBox(
                    height: 40, // 이미지와 같은 높이로 제한
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 1. 이름
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF353535),
                          ),
                        ),

                        // 약간의 간격 추가
                        SizedBox(height: 2),

                        // 2. 별점 + 나이(성별)
                        Row(
                          children: [
                            // 별점 표시
                            const Icon(Icons.star, size: 12, color: Color(0xFFFFD233)),
                            const SizedBox(width: 2),
                            Text(
                              '$rating/5',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF666666),
                              ),
                            ),

                            // 리뷰 수 표시
                            Text(
                              ' ($reviewCount)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF666666),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // 나이(성별)
                            if (age > 0)
                              Text(
                                '$age세($gender)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF666666),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 화살표 아이콘 추가
                Icon(
                  Icons.chevron_right,
                  color: Color(0xFF666666),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}