// lib/auth/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Firebase 인스턴스만 사용
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 사용자가 존재하는지 확인하는 메서드
  static Future<bool> checkUserExists(String uid) async {
    try {
      print('🔍 Firestore에서 사용자 확인 시작 - uid: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      bool exists = doc.exists;
      print('🔍 Firestore 사용자 존재 여부: $exists');

      if (exists) {
        print('🔍 사용자 데이터: ${doc.data()}');
      }

      return exists;
    } catch (e) {
      print('❌ checkUserExists 오류: $e');
      return false;
    }
  }

  // 로그아웃 메서드
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // 이메일로 회원가입 메서드
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 이메일 중복 체크
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: '이미 등록된 이메일입니다.',
        );
      }

      // 계정 생성
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 사용자 프로필 업데이트
      await userCredential.user?.updateDisplayName(displayName);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // 이메일로 로그인 메서드
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 현재 사용자 가져오기
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 비밀번호 재설정 이메일 보내기
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}