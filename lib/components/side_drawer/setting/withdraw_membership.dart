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
                  maxLines: 6,
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
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Color(0xFF007CFF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Text(
                        '계속 이용하기',
                        style: TextStyle(
                          color: Color(0xFF007CFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showWithdrawPopup(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF007CFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Text(
                        '탈퇴하기',
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
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedComplaintTypes.add(type);
                      } else {
                        _selectedComplaintTypes.remove(type);
                      }
                    });
                  },
                  side: BorderSide(width: 1.0, color: Colors.grey.shade400),
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
    );
  }
}
