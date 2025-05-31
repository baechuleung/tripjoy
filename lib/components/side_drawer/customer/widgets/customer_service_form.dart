import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/customer_service_controller.dart';

class CustomerServiceForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final String selectedCategory;
  final Function(String?) onCategoryChanged;
  final VoidCallback onSubmit;
  final bool isLoading;
  final Function(String) onPhoneChanged;
  final Function(String) onEmailChanged;

  const CustomerServiceForm({
    Key? key,
    required this.formKey,
    required this.titleController,
    required this.contentController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSubmit,
    required this.isLoading,
    required this.onPhoneChanged,
    required this.onEmailChanged,
  }) : super(key: key);

  @override
  State<CustomerServiceForm> createState() => _CustomerServiceFormState();
}

class _CustomerServiceFormState extends State<CustomerServiceForm> {
  late TextEditingController phoneController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    emailController = TextEditingController(text: user?.email ?? '');

    // 초기값 전달
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPhoneChanged(phoneController.text);
      widget.onEmailChanged(emailController.text);
    });

    // 리스너 추가
    phoneController.addListener(() {
      widget.onPhoneChanged(phoneController.text);
    });

    emailController.addListener(() {
      widget.onEmailChanged(emailController.text);
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸드폰 번호
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '핸드폰 번호',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: const Color(0xFFFF3E6C),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 50,
            child: TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Color(0xFF5963D0)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '핸드폰 번호를 입력해주세요';
                }
                return null;
              },
            ),
          ),

          SizedBox(height: 20),

          // 이메일 주소
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '이메일 주소',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: const Color(0xFFFF3E6C),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 50,
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Color(0xFF5963D0)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일 주소를 입력해주세요';
                }
                if (!value.contains('@')) {
                  return '올바른 이메일 형식을 입력해주세요';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 6),
          Text(
            '문의주신 내용은 이메일로 답변이 전송될 예정입니다. 정확한 이메일 주소를 입력해주세요.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),

          SizedBox(height: 20),

          // 문의 유형
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '문의 유형',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: const Color(0xFFFF3E6C),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Color(0xFFE0E0E0)),
            ),
            child: DropdownButtonFormField<String>(
              value: widget.selectedCategory,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              items: CustomerServiceController.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: widget.onCategoryChanged,
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFF999999)),
            ),
          ),

          SizedBox(height: 20),

          // 문의 내용
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '문의 내용',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: const Color(0xFFFF3E6C),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: widget.titleController,
            decoration: InputDecoration(
              hintText: '제목을 입력해주세요',
              hintStyle: TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Color(0xFF5963D0)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: widget.contentController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: '문의내용을 입력해주세요',
              hintStyle: TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Color(0xFF5963D0)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '문의 내용을 입력해주세요';
              }
              return null;
            },
          ),

          SizedBox(height: 30),

          // 접수하기 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : () {
                // 키보드 닫기
                FocusScope.of(context).unfocus();
                widget.onSubmit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5963D0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                '접수하기',
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
    );
  }
}