import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'review_popup.dart';
import 'one_line_review.dart';

class ReviewPageEdit extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const ReviewPageEdit({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  @override
  _ReviewPageEditState createState() => _ReviewPageEditState();
}

class _ReviewPageEditState extends State<ReviewPageEdit> {
  double _rating = 0;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _oneLineReviewController;
  bool _isLoading = true;

  // 선택된 항목들을 저장할 변수들
  List<String> _selectedGoodPoints = [];
  List<String> _selectedBadPoints = [];

  // 원본 리뷰 데이터
  Map<String, dynamic>? _originalReview;
  String? _docId;
  String? _tripfriendsId;

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
  void initState() {
    super.initState();
    _oneLineReviewController = TextEditingController();
    _loadReviewData();
  }

  @override
  void dispose() {
    _oneLineReviewController.dispose();
    super.dispose();
  }

  // 리뷰 데이터 로드
  Future<void> _loadReviewData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 인자에서 필요한 정보 추출
      _originalReview = widget.arguments['review'] as Map<String, dynamic>;
      _docId = widget.arguments['docId'] as String;
      _tripfriendsId = widget.arguments['tripfriendsId'] as String;

      if (_originalReview == null || _docId == null || _tripfriendsId == null) {
        throw Exception('필수 정보가 누락되었습니다.');
      }

      // 기존 데이터로 폼 초기화
      setState(() {
        _rating = (_originalReview?['rating'] ?? 0).toDouble();

        // 한줄 리뷰 설정
        if (_originalReview?['oneLineReview'] != null) {
          _oneLineReviewController.text = _originalReview!['oneLineReview'];
        }

        // 좋았던 점 설정
        if (_originalReview?['goodPoints'] != null && _originalReview?['goodPoints'] is List) {
          _selectedGoodPoints = List<String>.from(_originalReview!['goodPoints']);
        }

        // 아쉬웠던 점 설정
        if (_originalReview?['badPoints'] != null && _originalReview?['badPoints'] is List) {
          _selectedBadPoints = List<String>.from(_originalReview!['badPoints']);
        }

        _isLoading = false;
      });
    } catch (e) {
      print('리뷰 데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        await ReviewPopup.showErrorDialog(context, '리뷰 데이터를 불러오는데 실패했습니다.\n$e');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _updateReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      await ReviewPopup.showErrorDialog(context, '별점을 선택해주세요.');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('리뷰 수정 시작...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('로그인된 사용자가 없습니다.');
        await ReviewPopup.showErrorDialog(context, '로그인이 필요합니다.');
        return;
      }

      // 수정된 리뷰 데이터 생성
      final updatedReviewData = {
        'rating': _rating,
        'goodPoints': _selectedGoodPoints,
        'badPoints': _selectedBadPoints,
        'oneLineReview': _oneLineReviewController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('수정된 리뷰 데이터: $updatedReviewData');

      // Firestore에 업데이트
      await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(_tripfriendsId)
          .collection('reviews')
          .doc(_docId)
          .update(updatedReviewData);

      print('리뷰가 성공적으로 수정되었습니다.');

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // 성공 팝업 표시
      await ReviewPopup.showSuccessDialog(context, '리뷰가 성공적으로 수정되었습니다.');
      Navigator.pop(context);

    } catch (e, stackTrace) {
      print('리뷰 수정에 실패했습니다. 에러: $e');
      print('스택 트레이스: $stackTrace');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // 오류 팝업 표시
        await ReviewPopup.showErrorDialog(context, '리뷰 수정에 실패했습니다.\n${e.toString()}');
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            '리뷰 수정',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '리뷰 수정',
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

              // 한줄평 위젯 추가
              OneLineReview(controller: _oneLineReviewController),

              // 수정 완료 버튼
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _updateReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3182F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '수정완료',
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