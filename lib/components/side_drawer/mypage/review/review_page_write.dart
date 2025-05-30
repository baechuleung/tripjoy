import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'review_popup.dart';
import 'one_line_review.dart';

class ReviewPageWrite extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const ReviewPageWrite({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  _ReviewPageWriteState createState() => _ReviewPageWriteState();
}

class _ReviewPageWriteState extends State<ReviewPageWrite> {
  double _rating = 0;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oneLineReviewController = TextEditingController();

  // 선택된 항목들을 저장할 변수들
  List<String> _selectedGoodPoints = [];
  List<String> _selectedBadPoints = [];

  // 좋았던 점 목록
  final List<String> _goodPoints = [
    "😊 친절하고 적극적이에요",
    "🏙️ 현지 정보를 잘 알려줬어요",
    "💬 소통이 원활했어요",
    "🙌 요청을 잘 들어줬어요",
    "⏰ 시간 약속을 잘 지켰어요"
  ];

  // 아쉬웠던 점 목록
  final List<String> _badPoints = [
    "⏰ 약속 시간에 늦었어요",
    "😞 대화가 어려웠어요",
    "🤷 요청을 잘 반영하지 않았어요"
  ];

  @override
  void dispose() {
    _oneLineReviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      await ReviewPopup.showErrorDialog(context, '별점을 선택해주세요.');
      return;
    }

    try {
      print('리뷰 등록 시작...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('로그인된 사용자가 없습니다.');
        await ReviewPopup.showErrorDialog(context, '로그인이 필요합니다.');
        return;
      }

      // 사용자 이름 가져오기
      print('사용자 정보 가져오기 시도...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userName = userDoc.data()?['name'] ?? '익명';
      print('사용자 이름: $userName');

      // path에서 tripfriendsId 추출
      print('예약 데이터 정보: ${widget.reservation}');
      print('예약 경로 정보: ${widget.reservation['_path']}');

      final pathParts = widget.reservation['_path'].split('/');
      print('경로 분할 결과: $pathParts');

      if (pathParts.length < 2) {
        throw Exception('예약 경로 정보가 올바르지 않습니다: ${widget.reservation['_path']}');
      }

      final tripfriendsId = pathParts[1]; // tripfriends_users/{uid}/reservations/{reservationId}
      print('추출된 tripfriendsId: $tripfriendsId');

      // 트립프렌즈 정보 가져오기
      print('트립프렌즈 사용자 정보 가져오기 시도...');
      final tripfriendsDoc = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(tripfriendsId)
          .get();

      if (!tripfriendsDoc.exists) {
        print('트립프렌즈 문서가 존재하지 않습니다: $tripfriendsId');
        throw Exception('트립프렌즈 사용자 정보를 찾을 수 없습니다.');
      }

      final tripfriendsName = tripfriendsDoc.data()?['name'] ?? '알 수 없음';
      final location = tripfriendsDoc.data()?['location'] ?? '알 수 없음';
      print('트립프렌즈 이름: $tripfriendsName, 위치: $location');

      // 좋았던 점, 아쉬웠던 점 데이터 추가
      print('리뷰 데이터 생성 중...');
      final reviewData = {
        'userId': user.uid,
        'userName': userName,
        'tripfriendsName': tripfriendsName,
        'tripfriendsId': tripfriendsId,
        'location': location,
        'reservationNumber': widget.reservation['reservationNumber'],
        'rating': _rating,
        'goodPoints': _selectedGoodPoints,
        'badPoints': _selectedBadPoints,
        'oneLineReview': _oneLineReviewController.text.trim(), // 한줄 리뷰 데이터 추가
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('생성된 리뷰 데이터: $reviewData');

      // tripfriends_users/{tripfriendsId}/reviews 컬렉션에 저장
      print('Firestore에 리뷰 데이터 저장 시도...');
      final docRef = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(tripfriendsId)
          .collection('reviews')
          .add(reviewData);

      print('리뷰가 성공적으로 저장되었습니다. 문서 ID: ${docRef.id}');

      if (!mounted) return;

      // 성공 팝업 표시
      await ReviewPopup.showSuccessDialog(context, '리뷰가 성공적으로 등록되었습니다.');

      Navigator.pop(context);

    } catch (e, stackTrace) {
      print('리뷰 등록에 실패했습니다. 에러: $e');
      print('스택 트레이스: $stackTrace');

      if (mounted) {
        // 오류 팝업 표시
        await ReviewPopup.showErrorDialog(context, '리뷰 등록에 실패했습니다.\n${e.toString()}');
      }
    }
  }

  // 선택 옵션 버튼 위젯
  Widget _buildSelectionButton(String option, bool isSelected, Function() onPressed, bool isBadPoint) {
    // 이모지와 텍스트 분리 (첫 번째 문자는 이모지로 간주)
    String emoji = option.substring(0, 2); // 이모지는 보통 2바이트 차지
    String text = option.substring(2);

    // 선택된 경우 색상 설정
    Color selectedColor = isBadPoint ? Color(0xFFFFF0F0) : Color(0xFFEAF2FF); // 배경색
    Color selectedBorderColor = isBadPoint ? Color(0xFFFF3B30) : Color(0xFF3182F6); // 테두리색
    Color selectedTextColor = isBadPoint ? Color(0xFFFF3B30) : Color(0xFF3182F6); // 텍스트색

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.only(bottom: 5, right: 0),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBorderColor : Color(0xFFDDDDDD),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? selectedTextColor : Colors.black,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '리뷰 작성',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFF5F5F5),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '별점',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: index < _rating ? Colors.amber : Colors.grey[300],
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // 어떤 점이 좋았나요?
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFF5F5F5),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '어떤 점이 좋았나요?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '다중선택가능',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _goodPoints.map((option) {
                        final isSelected = _selectedGoodPoints.contains(option);
                        return _buildSelectionButton(
                            option,
                            isSelected,
                                () {
                              setState(() {
                                if (isSelected) {
                                  _selectedGoodPoints.remove(option);
                                } else {
                                  _selectedGoodPoints.add(option);
                                }
                              });
                            },
                            false // isBadPoint = false
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // 어떤 점이 아쉬웠나요?
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFF5F5F5),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '어떤 점이 아쉬웠나요?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '다중선택가능',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _badPoints.map((option) {
                        final isSelected = _selectedBadPoints.contains(option);
                        return _buildSelectionButton(
                            option,
                            isSelected,
                                () {
                              setState(() {
                                if (isSelected) {
                                  _selectedBadPoints.remove(option);
                                } else {
                                  _selectedBadPoints.add(option);
                                }
                              });
                            },
                            true // isBadPoint = true
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // 한줄평 위젯 추가 (맨 아래로 이동)
              OneLineReview(controller: _oneLineReviewController),

              // 등록 버튼
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3182F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '리뷰작성완료',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}