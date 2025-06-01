import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_page_edit.dart';

class ReviewItemWidget extends StatefulWidget {
  final Map<String, dynamic> review;
  final QueryDocumentSnapshot doc;
  final Map<String, String> countryCodeToName;
  final Map<String, String> cityCodeToName;

  const ReviewItemWidget({
    Key? key,
    required this.review,
    required this.doc,
    required this.countryCodeToName,
    required this.cityCodeToName,
  }) : super(key: key);

  @override
  _ReviewItemWidgetState createState() => _ReviewItemWidgetState();
}

class _ReviewItemWidgetState extends State<ReviewItemWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _friendsData;

  @override
  void initState() {
    super.initState();
    _fetchFriendsData();
  }

  // 트립프렌즈 정보 가져오기
  Future<void> _fetchFriendsData() async {
    try {
      final tripfriendsId = widget.review['tripfriendsId'];

      if (tripfriendsId == null || tripfriendsId.isEmpty) {
        print('tripfriendsId가 없습니다.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final tripfriendsDoc = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(tripfriendsId)
          .get();

      if (!tripfriendsDoc.exists) {
        print('트립프렌즈 문서가 존재하지 않습니다: $tripfriendsId');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _friendsData = tripfriendsDoc.data();
        _isLoading = false;
      });
    } catch (e) {
      print('트립프렌즈 정보 가져오기 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 위치 정보 처리 함수
  String _getLocationInfo() {
    if (widget.review['location'] is Map) {
      String nationality = '';
      String city = '';

      final location = widget.review['location'] as Map<String, dynamic>;

      if (location['nationality'] != null && location['nationality'] is String) {
        String nationCode = location['nationality'] as String;
        nationality = widget.countryCodeToName[nationCode] ?? nationCode;
      }

      if (location['city'] != null && location['city'] is String) {
        String cityCode = location['city'] as String;
        city = widget.cityCodeToName[cityCode] ?? cityCode;
      }

      if (nationality.isNotEmpty && city.isNotEmpty) {
        return '$nationality $city';
      } else if (nationality.isNotEmpty) {
        return nationality;
      } else if (city.isNotEmpty) {
        return city;
      }
    }
    return '알 수 없는 위치';
  }

  // 수정 페이지로 이동
  void _navigateToEditPage() {
    // 수정 페이지로 직접 이동하는 로직
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewPageEdit(
          arguments: {
            'review': widget.review,
            'docId': widget.doc.id,
            'tripfriendsId': widget.review['tripfriendsId'],
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = widget.review['createdAt'] as Timestamp;
    final date = createdAt.toDate();
    final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    // 위치 정보 및 예약번호
    final locationInfo = _getLocationInfo();
    final reservationNumber = widget.review['reservationNumber'] ?? '';

    // 한줄 리뷰 가져오기
    String oneLineReview = '';
    if (widget.review['oneLineReview'] != null && widget.review['oneLineReview'] is String) {
      oneLineReview = widget.review['oneLineReview'] as String;
    }

    // goodPoints와 badPoints 정보 가져오기
    List<String> goodPoints = [];
    if (widget.review['goodPoints'] != null && widget.review['goodPoints'] is List) {
      goodPoints = (widget.review['goodPoints'] as List).map((item) => item.toString()).toList();
    }

    List<String> badPoints = [];
    if (widget.review['badPoints'] != null && widget.review['badPoints'] is List) {
      badPoints = (widget.review['badPoints'] as List).map((item) => item.toString()).toList();
    }

    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Stack(
        children: [
          // 메인 콘텐츠
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프렌즈 정보 섹션 (로딩 중이 아닐 때만 표시)
              if (!_isLoading && _friendsData != null) _buildFriendsInfo(),

              // 위치 정보와 예약번호 표시
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '$locationInfo | $reservationNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // 별점과 날짜
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 별점
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                          (index) => Icon(
                        Icons.star_rounded,
                        color: index < (widget.review['rating'] ?? 0)
                            ? Colors.amber
                            : Colors.grey[300],
                        size: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // 구분선
                  Text(
                    '|',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 8),
                  // 날짜
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // 한줄 리뷰 표시
              if (oneLineReview.isNotEmpty) ...[
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    oneLineReview,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 16),

              // 좋았던 점과 아쉬웠던 점 태그들
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 좋았던 점 태그
                  ...goodPoints.map((point) =>
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFEBF3FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3182F6),
                          ),
                        ),
                      )
                  ),
                  // 아쉬웠던 점 태그
                  ...badPoints.map((point) =>
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      )
                  )
                ],
              ),
            ],
          ),

          // 오른쪽 상단에 메뉴 아이콘 배치
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.grey[600],
              ),
              color: Colors.white, // 팝업 메뉴 배경색을 흰색으로 설정
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToEditPage();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.grey[700], size: 18),
                      SizedBox(width: 8),
                      Text('수정하기'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 프렌즈 정보 위젯
  Widget _buildFriendsInfo() {
    // 기본 정보 추출
    final name = _friendsData?['name'] ?? '';
    final profileImageUrl = _friendsData?['profileImageUrl'] ?? '';
    final gender = _friendsData?['gender'] == 'male' ? '남성' : '여성';

    // 나이 계산
    int age = 0;
    if (_friendsData?['birthDate'] is Map && _friendsData?['birthDate']['year'] is int) {
      age = DateTime.now().year - (_friendsData?['birthDate']['year'] as int);
    }

    // 별점 정보
    final averageRating = _friendsData?['average_rating'] ?? 0;
    final reviewCount = _friendsData?['review_count'] ?? 0;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                profileImageUrl.isNotEmpty ? profileImageUrl : "https://placehold.co/80x90",
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[400],
                      size: 30,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            // 오른쪽 정보들
            Expanded(
              child: SizedBox(
                height: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 이름
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF353535),
                      ),
                    ),
                    SizedBox(height: 4),
                    // 별점 + 나이(성별)
                    Row(
                      children: [
                        // 별점 표시
                        Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD233)),
                        SizedBox(width: 2),
                        Text(
                          '$averageRating/5',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        // 리뷰 수
                        Text(
                          ' ($reviewCount)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(width: 8),
                        // 나이(성별)
                        Text(
                          '$age세($gender)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // 구분선 추가
        SizedBox(height: 12),
        Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        SizedBox(height: 12),
      ],
    );
  }
}