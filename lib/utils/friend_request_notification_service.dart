import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestNotificationService {
  // 싱글톤 패턴 구현
  static final FriendRequestNotificationService _instance =
  FriendRequestNotificationService._internal();

  factory FriendRequestNotificationService() => _instance;

  FriendRequestNotificationService._internal();

  // Firebase 메시징 인스턴스
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // 초기화 여부
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // 초기화 메소드 - FCM 토큰 등록 기능만 유지
  Future<void> initialize(String userId) async {
    if (_isInitialized) {
      debugPrint('🔔 FriendRequestNotificationService가 이미 초기화되어 있습니다.');
      return;
    }

    debugPrint('🔔 FriendRequestNotificationService 초기화 중... 사용자 ID: $userId');

    await _initializeNotifications();
    await updateFcmToken(userId);

    _isInitialized = true;
    debugPrint('✅ FriendRequestNotificationService 초기화 완료');
  }

  // 알림 초기화 - 간소화
  Future<void> _initializeNotifications() async {
    // FCM 권한 요청
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 FCM 권한 상태: ${settings.authorizationStatus}');

    // FCM 알림 클릭 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 FCM 알림 클릭됨: ${message.data}');
    });
  }

  // 사용자 FCM 토큰 업데이트 - fcmToken으로 저장 (서버 알림 전송용)
  Future<void> updateFcmToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        // users 컬렉션에 FCM 토큰 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});

        debugPrint('✅ FCM 토큰 업데이트됨: $token');

        // 현재 토큰 확인을 위한 로그
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String? storedToken = userData['fcmToken'];
          debugPrint('✅ 저장된 FCM 토큰 확인: $storedToken');
        }
      } else {
        debugPrint('❌ FCM 토큰을 가져올 수 없음');
      }
    } catch (e) {
      debugPrint('❌ FCM 토큰 업데이트 오류: $e');
    }
  }

  // 리소스 해제
  void dispose() {
    _isInitialized = false;
    debugPrint('🔔 FriendRequestNotificationService 리소스 해제됨');
  }
}