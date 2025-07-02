// lib/auth/screens/user_info_input_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/user_info_form.dart';

class UserInfoInputScreen extends StatelessWidget {
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

  const UserInfoInputScreen({
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: UserInfoForm(
            personalInfoConsent: personalInfoConsent,
            locationInfoConsent: locationInfoConsent,
            termsOfServiceConsent: termsOfServiceConsent,
            thirdPartyConsent: thirdPartyConsent,
            marketingConsent: marketingConsent,
            userCredential: userCredential,
            displayName: displayName,
            email: email,
            photoUrl: photoUrl,
            loginType: loginType,
            fcmToken: fcmToken,
          ),
        ),
      ),
    );
  }
}