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
  setLoading(true);

  try {
    final signInResult = await GoogleSignInProvider.signInWithGoogle();
    if (signInResult != null) {
      UserCredential userCredential = signInResult['userCredential'];
      String displayName = signInResult['displayName'];
      String email = signInResult['email'];
      String photoUrl = signInResult['photoUrl'];
      String loginType = 'google';

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

      // 사용자 존재 여부 확인
      bool userExists = await AuthService.checkUserExists(userCredential.user!.uid);

      if (userExists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인에 실패했습니다.')),
      );
    }
  } catch (e) {
    print('❌ Google 로그인 오류: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('로그인 중 오류가 발생했습니다. 다시 시도해주세요.')),
    );
  } finally {
    setLoading(false);
  }
}