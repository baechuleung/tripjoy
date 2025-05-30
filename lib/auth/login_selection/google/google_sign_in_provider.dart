import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider {
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String displayName = user.displayName ?? '';
        String photoUrl = user.photoURL ?? '';
        String email = user.email ?? ''; // 이메일 추가

        print('사용자 이름: $displayName');
        print('프로필 이미지 URL: $photoUrl');
        print('이메일: $email');

        return {
          'userCredential': userCredential,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'email': email, // 반환 값에 이메일 추가
        };
      }

      return null;
    } catch (e) {
      print('구글 회원가입 오류: $e');
      return null;
    }
  }
}
