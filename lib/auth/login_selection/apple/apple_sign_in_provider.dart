import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInProvider {
  // Apple 로그인 설정값
  static const String serviceBundleId = 'com.leapcompany.tripjoy';  // 서비스 ID
  static const String appleTeamId = 'RR5CF93Z4U';  // Apple 팀 ID
  static const String clientId = 'LQN3PTYRVM';  // Key ID
  static const String redirectUrl = 'https://tripjoy-d309f.firebaseapp.com/__/auth/handler';  // 리다이렉트 URL

  static Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      if (Platform.isAndroid) {
        // Android에서는 Firebase Auth의 OAuthProvider 사용
        final provider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name');

        // Firebase Auth를 통한 웹 기반 로그인
        final result = await FirebaseAuth.instance.signInWithProvider(provider);
        final user = result.user;

        if (user != null) {
          String displayName = user.displayName ?? '';
          String photoUrl = user.photoURL ?? '';
          String email = user.email ?? '';

          print('✅ Apple 웹 로그인 성공');
          print('사용자 이름: $displayName');
          print('프로필 이미지 URL: $photoUrl');
          print('이메일: $email');

          return {
            'userCredential': result,
            'displayName': displayName,
            'photoUrl': photoUrl,
            'email': email,
          };
        }
      } else {
        final isAvailable = await SignInWithApple.isAvailable();
        if (!isAvailable) {
          print('Apple Sign In is not available on this device');
          return null;
        }

        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: credential.identityToken,
          accessToken: credential.authorizationCode,
        );

        UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        User? user = userCredential.user;

        if (user != null) {
          String displayName = user.displayName ??
              '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
          String photoUrl = user.photoURL ?? '';
          String email = user.email ?? credential.email ?? '';

          print('✅ Apple 네이티브 로그인 성공');
          print('사용자 이름: $displayName');
          print('프로필 이미지 URL: $photoUrl');
          print('이메일: $email');

          return {
            'userCredential': userCredential,
            'displayName': displayName,
            'photoUrl': photoUrl,
            'email': email,
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Apple 회원가입 오류: $e');
      return null;
    }
  }
}