import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'config/fcm_initializer.dart';
import 'token/token_manager.dart';
import 'token/notification_settings.dart' as app_notification;
import 'handlers/message_handler.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isInitialized = false;

  // FCM 서비스 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;

    print('🚀 FCM 서비스 초기화 시작');

    // FCM 초기화 (플랫폼별 설정 포함)
    await FCMInitializer.initialize();

    // 메시지 핸들러 설정
    MessageHandler.setupMessageHandlers();

    // 토큰 확인 및 갱신
    await TokenManager.checkExistingToken();

    _isInitialized = true;
    print('✅ FCM 서비스 초기화 완료');
  }

  // FCM 토큰 발급 및 가져오기
  static Future<String?> getFCMToken() async {
    return await TokenManager.getToken();
  }

  // 토큰 갱신 시 콜백 설정
  static void setupTokenRefresh(Function(String) onTokenRefresh) {
    TokenManager.setupTokenRefresh(onTokenRefresh);
  }

  // 특정 토픽 구독
  static Future<void> subscribeToTopic(String topic) async {
    await app_notification.FCMNotificationSettings.subscribeToTopic(topic);
  }

  // 토픽 구독 해제
  static Future<void> unsubscribeFromTopic(String topic) async {
    await app_notification.FCMNotificationSettings.unsubscribeFromTopic(topic);
  }

  // 알림 설정 관리
  static Future<void> updateNotificationSettings({
    bool enableReservations = true,
    bool enableMessages = true,
  }) async {
    await app_notification.FCMNotificationSettings.updateSettings(
      enableReservations: enableReservations,
      enableMessages: enableMessages,
    );
  }

  // 모든 알림 비활성화
  static Future<void> disableAllNotifications() async {
    await app_notification.FCMNotificationSettings.disableAllNotifications();
  }

  // 로그인 시 토큰 업데이트
  static Future<void> onUserLogin(String uid) async {
    await TokenManager.onUserLogin(uid);
  }

  // 로그아웃 시 토큰 삭제
  static Future<void> onUserLogout(String uid) async {
    await TokenManager.onUserLogout(uid);
  }
}