import 'package:flutter/material.dart';
import 'withdraw_membership_popup.dart';

class WithdrawMembershipPage extends StatefulWidget {
  const WithdrawMembershipPage({Key? key}) : super(key: key);

  @override
  _WithdrawMembershipPageState createState() => _WithdrawMembershipPageState();
}

class _WithdrawMembershipPageState extends State<WithdrawMembershipPage> {
  // 선택된 불편 사항 유형을 저장할 리스트
  List<String> _selectedComplaintTypes = [];
  bool _isAgreed = false; // 동의 체크박스 상태

  final List<String> _complaintTypes = [
    '사용하기 어려워요',
    '유용한 서비스가 없어요',
    '다른 서비스를 이용하려해요',
    '오류가 너무 잦아요',
    '카메라 인식이 잘 안되는 것 같아요',
    '기타',
  ];

  void _showWithdrawPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WithdrawMembershipPopup();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '회원탈퇴하기',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '어떤점이 마음에 들지 않으셨어요?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '불편한 점을 말씀해주시면\n더 나은 서비스를 위해 노력하겠습니다!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 20),
              _buildCheckBoxList(),
              SizedBox(height: 20),
              Text(
                '상세 내용',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: '서비스 이용 중 아쉬운 점에 대해 알려주세요.\n고객님의 소리에 귀 기울일게요.',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // 주의사항 텍스트 추가
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• 모든 개인 정보 및 설정이 삭제됩니다.'),
                  Text('• 진행 중인 매칭과 대화가 모두 삭제됩니다.'),
                  Text('• 작성한 리뷰와 평가는 삭제되지 않습니다.'),
                  Text('• 삭제된 계정은 복구할 수 없습니다.'),
                  Text('• 동일한 이메일로 재가입은 가능합니다.'),
                ],
              ),
              SizedBox(height: 15),
              // 동의 체크박스
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAgreed = !_isAgreed;
                  });
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: ShapeDecoration(
                        color: _isAgreed ? const Color(0xFF3182F6) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(
                            color: _isAgreed ? const Color(0xFF3182F6) : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: _isAgreed
                          ? Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                          : null,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '위의 주의사항을 모두 확인했으며, 회원 탈퇴에 동의합니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 45,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE8F2FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '계속 이용하기',
                            style: TextStyle(
                              color: const Color(0xFF3182F6),
                              fontSize: 14,
                              fontFamily: 'Spoqa Han Sans Neo',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isAgreed ? () => _showWithdrawPopup(context) : null,
                      child: Opacity(
                        opacity: _isAgreed ? 1.0 : 0.5,
                        child: Container(
                          height: 45,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFFE8E8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '회원탈퇴',
                              style: TextStyle(
                                color: const Color(0xFFFF5050),
                                fontSize: 14,
                                fontFamily: 'Spoqa Han Sans Neo',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckBoxList() {
    return Column(
      children: _complaintTypes.map((type) {
        final isSelected = _selectedComplaintTypes.contains(type);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedComplaintTypes.remove(type);
                } else {
                  _selectedComplaintTypes.add(type);
                }
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: ShapeDecoration(
                    color: isSelected ? const Color(0xFF3182F6) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF3182F6) : Colors.grey,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                      : null,
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
          ),
        );
      }).toList(),
    );
  }
}