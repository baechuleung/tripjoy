import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../handlers/message_handler.dart';

class AndroidConfig {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static AndroidNotificationChannel? channel;

  static Future<void> initialize() async {
    print('🔔 Android FCM 설정 초기화 시작');

    // 알림 채널 설정
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      '중요 알림',
      description: '중요도가 높은 알림을 위한 채널입니다.',
      importance: Importance.high,
    );

    // 채널 생성
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);

    // 초기화
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: MessageHandler.onNotificationResponse,
    );

    print('✅ Android FCM 설정 초기화 완료');
  }
}