// lib/auth/login_selection/google/google_sign_in_function.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'google_sign_in_provider.dart';
import '../../consent/consent_page.dart';
import '../../auth_service.dart';
import '../../../screens/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripjoy/utils/shared_preferences_util.dart';

Future<void> handleSignInWithGoogle(BuildContext context, Function setLoading) async {
  print('🔵 Google 로그인 시작');
  setLoading(true);

  try {
    print('🔵 GoogleSignInProvider.signInWithGoogle 호출');
    final signInResult = await GoogleSignInProvider.signInWithGoogle();
    print('🔵 signInResult: $signInResult');

    if (signInResult != null) {
      UserCredential userCredential = signInResult['userCredential'];
      String displayName = signInResult['displayName'];
      String email = signInResult['email'];
      String photoUrl = signInResult['photoUrl'];
      String loginType = 'google';

      print('🔵 사용자 정보 - displayName: $displayName, email: $email');

      // FirebaseUser의 idToken을 가져와서 SharedPreferences에 저장
      String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        // SharedPreferences에 사용자 정보 및 로그인 상태 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', idToken);
        await prefs.setString('userEmail', email);
        await prefs.setString('userPhotoUrl', photoUrl);
        await prefs.setString('userName', displayName);
        await prefs.setString('loginType', 'google');

        print('✅ userToken 저장 성공: $idToken');
        print('✅ userEmail 저장 성공: $email');
        print('✅ userPhotoUrl 저장 성공: $photoUrl');
        print('✅ userName 저장 성공: $displayName');

        // 로그인 상태 저장
        await SharedPreferencesUtil.setLoggedIn(true);
        print('✅ 로그인 상태 저장됨: true');
      }

      // FCM 토큰 가져오기만 하고 저장하지는 않음
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print('🔵 FCM 토큰: $fcmToken');

      // 사용자 존재 여부 확인
      print('🔵 사용자 존재 여부 확인 시작 - uid: ${userCredential.user!.uid}');
      bool userExists = await AuthService.checkUserExists(userCredential.user!.uid);
      print('🔵 사용자 존재 여부: $userExists');

      if (userExists) {
        print('🔵 기존 사용자 - 메인 페이지로 이동');
        // 기존 사용자는 바로 메인 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
        print('🔵 신규 사용자 - 동의 페이지로 이동');
        // 신규 사용자는 동의 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConsentPage(
              userCredential: userCredential,
              displayName: displayName,
              email: email,
              photoUrl: photoUrl,
              loginType: loginType,
              fcmToken: fcmToken ?? '',
            ),
          ),
        );
      }
    } else {
      print('🔴 signInResult가 null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인에 실패했습니다.')),
      );
    }
  } catch (e) {
    print('❌ Google 로그인 오류: $e');
    print('❌ 스택 트레이스: ${StackTrace.current}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('로그인 중 오류가 발생했습니다. 다시 시도해주세요.')),
    );
  } finally {
    print('🔵 Google 로그인 프로세스 종료');
    setLoading(false);
  }
}