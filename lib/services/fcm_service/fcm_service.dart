import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/fcm_initializer.dart';
import 'token/token_manager.dart';
import 'token/notification_settings.dart' as app_notification;
import 'handlers/message_handler.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isInitialized = false;

  // 로컬 알림 플러그인
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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
    // iOS 배지 초기화
    await clearBadge();
  }

  // 현재 배지 수 가져오기 (로컬 저장소에서)
  static Future<int> getBadgeCount() async {
    if (!Platform.isIOS) return 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('badge_count') ?? 0;
    } catch (e) {
      print('⚠️ 배지 수 가져오기 실패: $e');
      return 0;
    }
  }

  // 배지 수 설정 (로컬 저장소에 저장)
  static Future<void> setBadgeCount(int count) async {
    if (!Platform.isIOS) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('badge_count', count);

      // iOS 플러그인을 통해 실제 배지 설정
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        // 배지 권한 요청
        await iosPlugin.requestPermissions(badge: true);

        // 더미 알림을 생성하여 배지 업데이트
        if (count > 0) {
          await _localNotifications.show(
            0,
            null,
            null,
            NotificationDetails(
              iOS: DarwinNotificationDetails(
                presentAlert: false,
                presentBadge: true,
                presentSound: false,
                badgeNumber: count,
              ),
            ),
          );
          // 즉시 알림 제거 (배지만 남김)
          await _localNotifications.cancel(0);
        }
      }

      print('✅ 배지 수 설정: $count');
    } catch (e) {
      print('⚠️ 배지 수 설정 실패: $e');
    }
  }

  // 배지 수 증가
  static Future<void> incrementBadgeCount() async {
    if (!Platform.isIOS) return;

    final currentCount = await getBadgeCount();
    await setBadgeCount(currentCount + 1);
  }

  // 배지 카운트 초기화
  static Future<void> clearBadge() async {
    if (!Platform.isIOS) return;

    try {
      // 로컬 저장소 초기화
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('badge_count', 0);

      // iOS 플러그인을 통해 배지 제거
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(badge: true);

        // 배지를 0으로 설정하는 더미 알림
        await _localNotifications.show(
          0,
          null,
          null,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: false,
              presentBadge: true,
              presentSound: false,
              badgeNumber: 0,
            ),
          ),
        );
        // 즉시 알림 제거
        await _localNotifications.cancel(0);
      }

      // Firebase Messaging을 통해서도 배지 클리어 시도
      await _messaging.setForegroundNotificationPresentationOptions(
        badge: false,
      );
      await Future.delayed(const Duration(milliseconds: 100));
      await _messaging.setForegroundNotificationPresentationOptions(
        badge: true,
      );

      print('✅ 배지 클리어 완료');
    } catch (e) {
      print('⚠️ 배지 클리어 실패: $e');
    }
  }

  // 로그아웃 시 토큰 삭제
  static Future<void> onUserLogout(String uid) async {
    await TokenManager.onUserLogout(uid);
    // 배지도 초기화
    await clearBadge();
  }
}