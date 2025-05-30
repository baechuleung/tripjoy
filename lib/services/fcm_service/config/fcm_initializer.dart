import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../handlers/message_handler.dart';
import 'android_config.dart';
import 'ios_config.dart';

class FCMInitializer {
  static Future<void> initialize() async {
    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    // 플랫폼별 로컬 알림 초기화
    if (Platform.isAndroid) {
      await AndroidConfig.initialize();
    } else if (Platform.isIOS) {
      await IOSConfig.initialize();
    }

    // iOS 포그라운드 알림 설정
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}