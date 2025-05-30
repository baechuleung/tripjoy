import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class KakaoSignInProvider {
  static Future<Map<String, dynamic>?> signInWithKakao() async {
    try {
      print('🔄 카카오 로그인 시작');
      kakao.User? user;
      kakao.OAuthToken? token;

      // 카카오톡 실행 가능 여부 확인
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          print('🔄 카카오톡으로 로그인 시도');
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
          print('✅ 카카오톡 앱 로그인 성공');
        } on PlatformException catch (error) {
          print('⚠️ 카카오톡 앱 로그인 실패: $error');

          if (error.code == 'NotSupportError') {
            print('🔄 카카오톡 미로그인 상태, 카카오 계정으로 웹 로그인 시도');
            try {
              token = await kakao.UserApi.instance.loginWithKakaoAccount();
              print('✅ 카카오 계정 웹 로그인 성공');
            } catch (webError) {
              print('❌ 카카오 계정 웹 로그인 실패: $webError');
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      } else {
        print('📱 카카오톡 미설치: 카카오 계정으로 웹 로그인 시도');
        try {
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
          print('✅ 카카오 계정 웹 로그인 성공');
        } catch (error) {
          print('❌ 카카오 계정 웹 로그인 실패: $error');
          rethrow;
        }
      }

      if (token == null) {
        print('❌ 카카오 로그인 토큰이 null입니다');
        return null;
      }

      // 로그인 성공 후 사용자 정보 요청
      print('🔄 카카오 사용자 정보 요청');
      try {
        user = await kakao.UserApi.instance.me();
        print('✅ 카카오 사용자 정보 받음');

        // 이메일이 없는 경우 처리
        if (user.kakaoAccount?.email == null) {
          print('❌ 카카오 계정에 이메일이 없습니다');
          return null;
        }
      } catch (error) {
        print('❌ 카카오 사용자 정보 요청 실패: $error');
        return null;
      }

      // 서버에 보낼 요청 데이터
      final requestBody = {
        'kakao_uid': user.id.toString(),
        'firebase_identifier': user.kakaoAccount?.email,  // Firebase 식별자로 사용할 이메일
        'profile_nickname': user.kakaoAccount?.profile?.nickname,
        'profile_image': user.kakaoAccount?.profile?.profileImageUrl,
        'login_type': 'kakao'
      };

      print('📤 서버로 보내는 데이터: $requestBody');

      try {
        final response = await http.post(
          Uri.parse('https://main-okncywrwuq-uc.a.run.app/create-custom-token'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        print('📡 백엔드 응답 상태 코드: ${response.statusCode}');
        print('📡 백엔드 응답 내용: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('✅ 서버 응답 데이터: $responseData');
          final customToken = responseData['customToken'];

          if (customToken != null) {
            print('🔄 Firebase 인증 시작');
            UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCustomToken(customToken);
            print('✅ Firebase 인증 성공');

            return {
              'userCredential': userCredential,
              'displayName': user.kakaoAccount?.profile?.nickname ?? '',
              'photoUrl': user.kakaoAccount?.profile?.profileImageUrl ?? '',
              'email': user.kakaoAccount?.email ?? '',
              'loginType': 'kakao'
            };
          }
        }
        print('❌ 서버 응답 실패 또는 customToken이 null');
        return null;
      } catch (error) {
        print('❌ 서버 통신 중 에러: $error');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ 카카오 로그인 오류: $e');
      print('🔍 스택 트레이스: $stackTrace');
      return null;
    }
  }
}