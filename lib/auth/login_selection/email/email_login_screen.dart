// lib/auth/login_selection/email/email_login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tripjoy/loading_widgets/loading_spinner_login.dart';
import 'package:tripjoy/screens/main_page.dart';
import 'package:tripjoy/auth/auth_service.dart';
import 'package:tripjoy/auth/consent/consent_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripjoy/utils/shared_preferences_util.dart';
import 'email_sign_up_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({Key? key}) : super(key: key);

  @override
  _EmailLoginScreenState createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Firebase ID 토큰 가져오기
        String? idToken = await userCredential.user?.getIdToken();

        if (idToken != null) {
          // SharedPreferences에 사용자 정보 저장
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userToken', idToken);
          await prefs.setString('userEmail', _emailController.text.trim());
          await prefs.setString('userName', userCredential.user?.displayName ?? '');
          await prefs.setString('userPhotoUrl', userCredential.user?.photoURL ?? '');
          await prefs.setString('loginType', 'email');

          // 로그인 상태 저장
          await SharedPreferencesUtil.setLoggedIn(true);
        }

        // FCM 토큰 가져오기
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // 사용자 존재 여부 확인
        bool userExists = await AuthService.checkUserExists(userCredential.user!.uid);

        if (mounted) {
          if (userExists) {
            // 기존 사용자는 바로 메인 페이지로 이동
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
                  (route) => false,
            );
          } else {
            // 신규 사용자는 동의 페이지로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConsentPage(
                  userCredential: userCredential,
                  displayName: userCredential.user?.displayName ?? '',
                  email: _emailController.text.trim(),
                  photoUrl: userCredential.user?.photoURL ?? '',
                  loginType: 'email',
                  fcmToken: fcmToken ?? '',
                ),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = '해당 이메일로 등록된 사용자가 없습니다.';
        } else if (e.code == 'wrong-password') {
          message = '비밀번호가 일치하지 않습니다.';
        } else if (e.code == 'invalid-email') {
          message = '유효하지 않은 이메일 형식입니다.';
        } else {
          message = '로그인에 실패했습니다. 다시 시도해주세요.';
        }
        setState(() {
          _errorMessage = message;
        });
      } catch (e) {
        setState(() {
          _errorMessage = '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '이메일 로그인',
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
          if (_isLoading) const LoadingSpinnerLogin(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),
                Text(
                  '이메일',
                  style: TextStyle(
                    color: Color(0xFF424242),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: '이메일 주소를 입력해주세요',
                    hintStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF4CAF50)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '유효한 이메일 주소를 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text(
                  '비밀번호',
                  style: TextStyle(
                    color: Color(0xFF424242),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '비밀번호를 입력해주세요',
                    hintStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF4CAF50)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Color(0xFF757575),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 최소 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // SizedBox(height: 16),
                // Center(
                //   child: TextButton(
                //     onPressed: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(builder: (context) => EmailSignUpScreen()),
                //       );
                //     },
                //     child: Text(
                //       '계정이 없으신가요? 회원가입',
                //       style: TextStyle(
                //         color: Color(0xFF4CAF50),
                //         fontSize: 14,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}