import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'complaint_caution.dart';
import 'complaint_complete.dart';

class ComplaintPage extends StatefulWidget {
  @override
  _ComplaintPageState createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _detailController = TextEditingController();

  // 불편 사항 유형 목록
  final List<String> _complaintTypes = [
    '프렌즈가 너무 불친절해요',
    '프렌즈 프로필 정보가 부족해요',
    '채팅이 원활하지 않았어요',
    '사용이 어려워요',
    '정보가 달라요',
    '기타'
  ];

  // 선택된 불편 사항 유형 목록
  List<String> _selectedComplaintTypes = [];

  // Firestore에 데이터 추가 및 팝업 표시
  Future<void> _submitComplaint() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('complaint').add({
          'complaintTypes': _selectedComplaintTypes,
          'details': _detailController.text,
          'userId': user.uid,
          'name': user.displayName ?? '익명 사용자',
          'email': user.email ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'date': DateTime.now(),
        });

        // 팝업 표시
        showDialog(
          context: context,
          builder: (context) => ComplaintComplete(
            onCancel: () {
              Navigator.of(context).pop(); // 취소 버튼 동작
            },
            onConfirm: () {
              Navigator.of(context).popUntil((route) => route.isFirst); // 완료 버튼 동작
            },
          ),
        );


        // 입력 필드 초기화
        _detailController.clear();
        setState(() {
          _selectedComplaintTypes.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _showCautionDialog() {
    showDialog(
      context: context,
      builder: (context) => ComplaintCaution(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '이용불편사항신고',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '트립조이에 대한 불편하신 사항을 남겨주세요!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // 체크박스 목록 (왼쪽 여백 제거 및 위아래 간격 추가)
                Column(
                  children: _complaintTypes.map((type) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                              side: BorderSide(width: 1.0, color: Colors.grey),
                              value: _selectedComplaintTypes.contains(type),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedComplaintTypes.add(type);
                                  } else {
                                    _selectedComplaintTypes.remove(type);
                                  }
                                });
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              type,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 20),

                Text(
                  '상세 내용',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // 상세 내용 입력 필드
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Color(0xFFDADADA)),
                  ),
                  child: TextFormField(
                    controller: _detailController,
                    maxLines: 7,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintText: '트립조이를 사용하면서 불편했던점을 남겨주세요.\n여러분의 소중한 피드백을 참고하여 더 노력하겠습니다!',
                      hintStyle: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '상세 내용을 입력해 주세요';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 5),
                GestureDetector(
                  onTap: _showCautionDialog,
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, color: Color(0xFF999999)),
                      SizedBox(width: 5),
                      Text(
                        '불편사항신고시 주의사항',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                // 신고하기 버튼 디자인
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF007CFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      '신고하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
