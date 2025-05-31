import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service/customer_service_controller.dart';
import 'widgets/customer_service_form.dart';
import 'widgets/inquiry_success_popup.dart';
import 'my_inquiry_list_page.dart';

class CustomerServicePage extends StatefulWidget {
  @override
  _CustomerServicePageState createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final CustomerServiceController _controller = CustomerServiceController();

  String _selectedCategory = '일반문의';
  bool _isLoading = false;
  String? phoneNumber;
  String? email;

  Future<void> _submitInquiry() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('❌ 로그인이 필요합니다.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _controller.submitInquiry(
          user: user,
          category: _selectedCategory,
          title: _titleController.text,
          content: _contentController.text,
          phoneNumber: phoneNumber,
          email: email,
        );

        debugPrint('✅ 문의가 성공적으로 접수되었습니다.');

        // 입력 필드 초기화
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _selectedCategory = '일반문의';
          _isLoading = false;
        });

        // 성공 팝업 표시
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => InquirySuccessPopup(
              onConfirm: () {
                // 팝업 닫기
                Navigator.of(context).pop();
                // 내 문의 내역 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyInquiryListPage(),
                  ),
                );
              },
            ),
          );
        }

      } catch (e) {
        debugPrint('❌ 문의 접수 중 오류가 발생했습니다: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '고객센터',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          // 키보드 닫기
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 문의 폼
                CustomerServiceForm(
                  formKey: _formKey,
                  titleController: _titleController,
                  contentController: _contentController,
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                  onSubmit: _submitInquiry,
                  isLoading: _isLoading,
                  onPhoneChanged: (value) {
                    phoneNumber = value;
                  },
                  onEmailChanged: (value) {
                    email = value;
                  },
                ),

                SizedBox(height: 16),

                // 내 문의 내역 보기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyInquiryListPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF5963D0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      '내 문의 내역',
                      style: TextStyle(
                        color: Color(0xFF5963D0),
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}