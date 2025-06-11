import 'package:flutter/material.dart';
import 'package:tripjoy/loading_widgets/loading_spinner_login.dart';
import 'package:tripjoy/screens/main_page.dart';
import 'google/google_sign_in_function.dart';
import 'kakao/kakao_sign_in_function.dart';
import 'apple/apple_sign_in_function.dart';
import 'email/email_login_screen.dart'; // 이메일 로그인 화면 import 추가
import 'package:url_launcher/url_launcher.dart';

class LoginSelectionScreen extends StatefulWidget {
  const LoginSelectionScreen({Key? key}) : super(key: key);

  @override
  _LoginSelectionScreenState createState() => _LoginSelectionScreenState();
}

class _LoginSelectionScreenState extends State<LoginSelectionScreen> {
  bool isLoading = false;

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        isLoading = loading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
                  (route) => false,  // 모든 이전 route를 제거
            );
          },
        ),
        title: Text(
          '',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildContent(context),
          if (isLoading) const LoadingSpinnerLogin(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 로고를 화면 정중앙에 배치
          Expanded(
            child: Center(
              child: _buildLogo(),
            ),
          ),
          // 간편로그인 섹션을 하단에 배치
          Column(
            children: [
              _buildSimpleLoginDivider(),
              const SizedBox(height: 15),
              _buildLoginButton('google', context, () =>
                  handleSignInWithGoogle(context, setLoading)),
              const SizedBox(height: 15),
              _buildLoginButton('apple', context, () =>
                  handleSignInWithApple(context, setLoading)),
              const SizedBox(height: 15),
              _buildLoginButton('kakao', context, () =>
                  handleSignInWithKakao(context, setLoading)),
              const SizedBox(height: 15),
              _buildEmailLoginButton(context),
              const SizedBox(height: 100), // 간격을 100으로 증가
              _buildInquiryText(context),
              const SizedBox(height: 40), // 하단 여백
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/auth_logo.png',
      width: 204,
      height: 71,
    );
  }

  Widget _buildSimpleLoginDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Color(0xFFE0E0E0),
            thickness: 1,
            indent: 20,
            endIndent: 10,
          ),
        ),
        Text(
          '간편로그인',
          style: TextStyle(
            color: Color(0xFF424242),
            fontSize: 14,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFE0E0E0),
            thickness: 1,
            indent: 10,
            endIndent: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(String platform, BuildContext context, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          child: Image.asset(
            'assets/login/$platform.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // 이메일 로그인 버튼 추가
  Widget _buildEmailLoginButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EmailLoginScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email, color: Color(0xFF424242)),
              SizedBox(width: 8),
              Text(
                '이메일로 로그인',
                style: TextStyle(
                  color: Color(0xFF424242),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 문의하기 텍스트 추가
  Widget _buildInquiryText(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final Uri url = Uri.parse('http://pf.kakao.com/_Klbrn');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('링크를 열 수 없습니다.')),
          );
        }
      },
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '로그인이 안되시나요? ',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: '문의하기',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}