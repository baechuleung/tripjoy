// lib/auth/login_selection/kakao/kakao_sign_in_function.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'kakao_sign_in_provider.dart';
import '../../consent/consent_page.dart';
import '../../auth_service.dart';
import '../../../screens/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripjoy/utils/shared_preferences_util.dart';

Future<void> handleSignInWithKakao(BuildContext context, Function setLoading) async {
  print('🔄 카카오 로그인 프로세스 시작');
  setLoading(true);

  try {
    print('🔄 KakaoSignInProvider.signInWithKakao 호출');
    final signInResult = await KakaoSignInProvider.signInWithKakao();
    print('📦 signInResult: $signInResult');

    if (signInResult != null) {
      print('✅ 카카오 로그인 결과 받음');
      UserCredential userCredential = signInResult['userCredential'];
      String displayName = signInResult['displayName'];
      String email = signInResult['email'];
      String photoUrl = signInResult['photoUrl'];
      String loginType = signInResult['loginType'];

      if (email.isEmpty) {
        print('❌ 이메일이 비어있습니다');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카카오 계정에 이메일이 등록되어 있지 않습니다. 이메일을 등록 후 다시 시도해주세요.')),
        );
        return;
      }

      print('🔄 Firebase ID 토큰 요청');
      String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        print('✅ ID 토큰 받음');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', idToken);
        await prefs.setString('userEmail', email);
        await prefs.setString('userPhotoUrl', photoUrl);
        await prefs.setString('userName', displayName);
        await prefs.setString('loginType', loginType);

        print('✅ userToken 저장 성공: $idToken');
        print('✅ userEmail 저장 성공: $email');
        print('✅ userPhotoUrl 저장 성공: $photoUrl');
        print('✅ userName 저장 성공: $displayName');
        print('✅ loginType 저장 성공: $loginType');

        await SharedPreferencesUtil.setLoggedIn(true);
        print('✅ 로그인 상태 저장됨: true');

        // FCM 토큰 가져오기만 하고 저장하지는 않음
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        print('🔄 사용자 존재 여부 확인');
        bool userExists = await AuthService.checkUserExists(userCredential.user!.uid);
        print('👤 사용자 존재 여부: $userExists');

        if (userExists) {
          // 기존 사용자는 바로 메인 페이지로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        } else {
          // 신규 사용자는 동의 페이지로 이동
          print('✅ ConsentPage로 이동');
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
        print('❌ ID 토큰이 null임');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 정보를 가져오는데 실패했습니다.')),
        );
      }
    } else {
      print('❌ signInResult가 null임');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인에 실패했습니다.')),
      );
    }
  } catch (e) {
    print('❌ 카카오 로그인 처리 오류: $e');
    print('❌ 오류 스택트레이스: ${StackTrace.current}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('로그인 중 오류가 발생했습니다. 다시 시도해주세요.')),
    );
  } finally {
    print('🏁 로그인 프로세스 종료');
    setLoading(false);
  }
}