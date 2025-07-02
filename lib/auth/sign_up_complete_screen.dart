import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tripjoy/screens/main_page.dart';
import 'package:tripjoy/utils/shared_preferences_util.dart';
import 'dart:ui' as ui;

class SignUpCompleteScreen extends StatefulWidget {
  final bool personalInfoConsent;
  final bool locationInfoConsent;
  final bool termsOfServiceConsent;
  final bool thirdPartyConsent;
  final bool marketingConsent;
  final UserCredential userCredential;
  final String displayName;
  final String email;
  final String photoUrl;
  final String loginType;
  final String fcmToken;

  const SignUpCompleteScreen({
    Key? key,
    required this.personalInfoConsent,
    required this.locationInfoConsent,
    required this.termsOfServiceConsent,
    required this.thirdPartyConsent,
    required this.marketingConsent,
    required this.userCredential,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.loginType,
    required this.fcmToken,
  }) : super(key: key);

  @override
  _SignUpCompleteScreenState createState() => _SignUpCompleteScreenState();
}

class _SignUpCompleteScreenState extends State<SignUpCompleteScreen> {
  Future<void> _saveToFirestore() async {
    final currentUser = widget.userCredential.user;
    if (currentUser != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      String currentLocale = ui.window.locale.languageCode;

      // Firestore에 저장할 데이터
      Map<String, dynamic> firestoreData = {
        'personalInfoConsent': widget.personalInfoConsent,
        'locationInfoConsent': widget.locationInfoConsent,
        'termsOfServiceConsent': widget.termsOfServiceConsent,
        'thirdPartyConsent': widget.thirdPartyConsent,
        'marketingConsent': widget.marketingConsent,
        'name': widget.displayName,
        'email': widget.email,
        'photoUrl': widget.photoUrl,
        'loginType': widget.loginType,
        'fcmToken': widget.fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'birthDate': null,
        'gender': null,
        'language': currentLocale,
        'points': 3000,
        'usage_count': 0, // 회원가입 시 usage_count를 0으로 초기화
        'is_premium': true, // 회원가입 시 is_premium을 true로 설정
      };

      // Firestore에 저장
      await userDocRef.set(firestoreData, SetOptions(merge: true));

      // SharedPreferences용 데이터 준비 (Timestamp 제외하고 직접 구성)
      Map<String, dynamic> prefsData = {
        'personalInfoConsent': widget.personalInfoConsent,
        'locationInfoConsent': widget.locationInfoConsent,
        'termsOfServiceConsent': widget.termsOfServiceConsent,
        'thirdPartyConsent': widget.thirdPartyConsent,
        'marketingConsent': widget.marketingConsent,
        'name': widget.displayName,
        'email': widget.email,
        'photoUrl': widget.photoUrl,
        'loginType': widget.loginType,
        'fcmToken': widget.fcmToken,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
        'birthDate': null,
        'gender': null,
        'language': currentLocale,
        'points': 3000,
        'usage_count': 0,
        'is_premium': true,
      };

      // SharedPreferences에 저장
      await SharedPreferencesUtil.saveUserDocument(prefsData);

      _showSignUpCompleteDialog();
    }
  }

  void _showSignUpCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('회원가입 완료'),
          content: Text('${widget.displayName}님, 회원가입이 완료되었습니다.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                      (route) => false,
                );
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _saveToFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}