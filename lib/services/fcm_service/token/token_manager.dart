import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TokenManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 저장된 토큰 확인
  static Future<void> checkExistingToken() async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      print('👤 로그인된 사용자 없음');
      return;
    }

    // 현재 FCM 토큰 가져오기
    String? currentToken = await _messaging.getToken();
    print('🔍 현재 FCM 토큰: ${currentToken != null ? "${currentToken.substring(0, 10)}..." : "없음"}');

    if (currentToken != null) {
      await updateTokenInDatabase(currentUser.uid, currentToken);
    }
  }

  // FCM 토큰 발급 및 가져오기
  static Future<String?> getToken() async {
    try {
      print('🔔 FCM 토큰 요청 시작');

      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ 로그인된 사용자 없음, 토큰 요청 취소');
        return null;
      }

      // FCM 권한 요청
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('🔔 FCM 알림 권한 획득: ${settings.authorizationStatus}');

        // 토큰 얻기
        String? token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          print('🔑 FCM 토큰 발급 성공: ${token.substring(0, 10)}...');

          // 이전 토큰들 정리
          await cleanupOldTokens(token);

          // 현재 사용자의 정보로 토큰 저장
          await updateTokenInDatabase(currentUser.uid, token);

          return token;
        } else {
          print('⚠️ FCM 토큰이 비어있음');
          return null;
        }
      } else {
        print('❌ FCM 알림 권한 거부됨');
        return null;
      }
    } catch (e) {
      print('❌ FCM 토큰 발급 실패: $e');
      return null;
    }
  }

  // 이전 토큰 정리 메서드
  static Future<void> cleanupOldTokens(String currentToken) async {
    try {
      print('🧹 이전 FCM 토큰 정리 시작');

      // users 컬렉션에서 현재 토큰과 동일한 토큰을 가진 모든 사용자 찾기
      QuerySnapshot sameTokenUsers = await _firestore
          .collection('users')
          .where('fcmToken', isEqualTo: currentToken)
          .get();

      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // 현재 사용자가 아닌 다른 사용자들의 토큰 제거
      for (DocumentSnapshot doc in sameTokenUsers.docs) {
        if (doc.id != currentUser.uid) {
          await _firestore
              .collection('users')
              .doc(doc.id)
              .update({'fcmToken': null});

          print('🗑️ 사용자 ${doc.id}의 중복 토큰 제거됨');
        }
      }

      print('✅ 이전 FCM 토큰 정리 완료');
    } catch (e) {
      print('⚠️ 이전 토큰 정리 중 오류: $e');
    }
  }

  // 토큰 갱신 시 콜백 설정
  static void setupTokenRefresh(Function(String) onTokenRefresh) {
    _messaging.onTokenRefresh.listen((String token) {
      print('🔄 FCM 토큰 갱신됨: ${token.substring(0, 10)}...');

      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        cleanupOldTokens(token).then((_) {
          updateTokenInDatabase(currentUser.uid, token);
        });
      }

      onTokenRefresh(token);
    });
  }

  // FCM 토큰 데이터베이스에 업데이트 (Firestore)
  static Future<void> updateTokenInDatabase(String uid, String token) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != uid) {
        print('⚠️ 토큰 업데이트 취소: 로그인된 사용자 없거나 UID 불일치');
        return;
      }

      // users 컬렉션에 FCM 토큰 업데이트
      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Firestore의 FCM 토큰 업데이트 완료: uid=$uid');

    } catch (e) {
      print('⚠️ Firestore에 FCM 토큰 업데이트 실패: $e');

      // 문서가 없을 경우 새로 생성
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(uid)
            .get();

        if (!userDoc.exists) {
          await _firestore
              .collection('users')
              .doc(uid)
              .set({
            'fcmToken': token,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          print('✅ 문서가 없어 새로 생성하여 FCM 토큰 저장 완료: uid=$uid');
        }
      } catch (e) {
        print('⚠️ 문서 생성 중 오류: $e');
      }
    }
  }

  // 로그인 시 토큰 업데이트
  static Future<void> onUserLogin(String uid) async {
    try {
      print('👤 사용자 로그인: $uid');

      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != uid) {
        print('⚠️ 토큰 업데이트 취소: 로그인된 사용자 없거나 UID 불일치');
        return;
      }

      // 새 토큰 발급
      String? token = await getToken();
      if (token != null) {
        await updateTokenInDatabase(uid, token);
      }

      print('✅ 로그인 시 FCM 토큰 업데이트 완료');
    } catch (e) {
      print('⚠️ 로그인 시 FCM 토큰 업데이트 실패: $e');
    }
  }

  // 로그아웃 시 토큰 삭제
  static Future<void> onUserLogout(String uid) async {
    try {
      print('👤 사용자 로그아웃: $uid');

      // Firestore에서 토큰 제거
      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        'fcmToken': null,
        'lastLogout': FieldValue.serverTimestamp(),
        'tokenRemovedAt': FieldValue.serverTimestamp(),
      });

      // FCM 토큰 무효화
      try {
        await _messaging.deleteToken();
        print('🗑️ FCM 토큰 삭제됨');
      } catch (e) {
        print('⚠️ FCM 토큰 삭제 중 오류: $e');
      }

      print('✅ 로그아웃 시 FCM 토큰 삭제 완료');
    } catch (e) {
      print('⚠️ 로그아웃 시 FCM 토큰 삭제 실패: $e');
    }
  }
}