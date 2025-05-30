import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tripjoy/components/side_drawer/mypage/reservation/reservation_page.dart';

class ReservationNotificationHandler {
  // 싱글톤 패턴 구현
  static final ReservationNotificationHandler _instance = ReservationNotificationHandler._internal();

  factory ReservationNotificationHandler() => _instance;

  ReservationNotificationHandler._internal();

  // 앱 내 경로 이동을 위한 네비게이터 키
  GlobalKey<NavigatorState>? navigatorKey;

  // 로컬 알림을 위한 플러그인
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  // Android용 알림 채널 ID
  static const String channelId = 'reservation_channel';
  static const String channelName = '예약 알림';
  static const String channelDescription = '예약 관련 알림을 위한 채널입니다.';

  // 초기화 여부
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // 초기화 메소드
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    if (_isInitialized) {
      debugPrint('🔔 ReservationNotificationHandler가 이미 초기화되어 있습니다.');
      return;
    }

    debugPrint('🔔 ReservationNotificationHandler 초기화 중...');

    // navigatorKey 설정
    navigatorKey = navKey;

    // FCM 권한 요청
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 FCM 권한 상태: ${settings.authorizationStatus}');

    // 로컬 알림 초기화
    await _initLocalNotifications();

    _isInitialized = true;
    debugPrint('✅ ReservationNotificationHandler 초기화 완료');
  }

  // 로컬 알림 초기화
  Future<void> _initLocalNotifications() async {
    try {
      debugPrint('🔔 로컬 알림 초기화 시작 (예약)');

      // Android 설정
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 설정 (onDidReceiveLocalNotification 파라미터는 이제 사용되지 않음)
      final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      // 초기화 설정
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // 플러그인 초기화
      await localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          // 알림 클릭 처리
          debugPrint('🔔 [예약] 로컬 알림 클릭됨: ${notificationResponse.payload}');

          if (notificationResponse.payload != null) {
            // 페이로드 형식: "type:값,key:값,key:값"
            final payloadMap = _parsePayload(notificationResponse.payload!);
            await _handleLocalNotificationClick(payloadMap);
          }
        },
      );

      // Android 채널 생성
      if (await _isAndroid()) {
        await localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
        ));
      }

      debugPrint('✅ 로컬 알림 초기화 완료 (예약)');
    } catch (e, stackTrace) {
      debugPrint('⚠️ 로컬 알림 초기화 실패 (예약): $e');
      debugPrint('⚠️ 스택 트레이스: $stackTrace');
    }
  }

  // Android 기기인지 확인
  Future<bool> _isAndroid() async {
    return Theme.of(navigatorKey!.currentContext!).platform == TargetPlatform.android;
  }

  // 페이로드 문자열을 Map으로 변환
  Map<String, String> _parsePayload(String payload) {
    Map<String, String> result = {};
    final parts = payload.split(',');

    for (var part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        result[keyValue[0]] = keyValue[1];
      }
    }

    return result;
  }

  // 로컬 알림 클릭 처리
  Future<void> _handleLocalNotificationClick(Map<String, String> payloadMap) async {
    debugPrint('🔔 [예약] 로컬 알림 페이로드: $payloadMap');

    // 예약 알림 처리 - 바로 예약 화면으로 이동
    _navigateToReservationPage();
  }

  // 예약 관련 알림인지 확인
  bool isReservationNotification(RemoteMessage message) {
    final type = message.data['type'];
    debugPrint('📩 알림 타입 확인: $type');
    return type == 'reservation_in_progress';
  }

  // FCM 토큰 업데이트 (사용자가 로그인할 때 호출)
  Future<void> updateFcmToken(String userId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        debugPrint('✅ FCM 토큰 업데이트됨: $token');
      } else {
        debugPrint('❌ FCM 토큰을 가져올 수 없음');
      }
    } catch (e) {
      debugPrint('❌ FCM 토큰 업데이트 오류: $e');
    }
  }

  // FCM 메시지를 로컬 알림으로 표시 (앱이 실행 중일 때)
  Future<void> showLocalNotification(RemoteMessage message) async {
    try {
      // 알림 ID 생성 (현재 시간 기반)
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 알림 제목과 내용 설정
      String title = message.notification?.title ?? '예약 알림';
      String body = message.notification?.body ?? '예약이 시작되었습니다. 확인해주세요.';

      debugPrint('🔔 [예약] 로컬 알림 표시: $title, $body');

      // 페이로드 생성
      String payload = 'type:reservation_in_progress';

      // 예약 ID가 있으면 추가
      if (message.data['reservation_id'] != null) {
        payload += ',reservation_id:${message.data['reservation_id']}';
      }

      // Android 알림 상세 설정
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      // iOS 알림 상세 설정
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // 플랫폼별 설정 통합
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 알림 표시
      await localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );

      debugPrint('✅ [예약] 로컬 알림 표시 완료: ID=$id, 페이로드=$payload');
    } catch (e, stackTrace) {
      debugPrint('❌ [예약] 로컬 알림 표시 오류: $e');
      debugPrint('❌ 스택 트레이스: $stackTrace');
    }
  }

  // 메시지 핸들링 - 예약 알림 처리 (알림 클릭시에만 실행됨)
  void handleMessage(RemoteMessage message) {
    try {
      final Map<String, dynamic> data = message.data;
      final String? type = data['type'];
      final String? reservationId = data['reservation_id'];

      debugPrint('📱 [Reservation] 알림 클릭 처리: 타입=$type, 예약 ID=$reservationId');

      if (navigatorKey?.currentState == null) {
        debugPrint('⚠️ 네비게이터 키가 없어 경로 이동 불가');
        return;
      }

      // 현재 스택 상태 로깅
      final context = navigatorKey!.currentContext;
      if (context != null) {
        final route = ModalRoute.of(context);
        debugPrint('현재 경로 이름: ${route?.settings.name}');
      } else {
        debugPrint('⚠️ context가 null입니다');
        return; // 컨텍스트가 없으면 이동 불가
      }

      // 예약 시작 알림인 경우 예약 내역 화면으로 이동
      if (type == 'reservation_in_progress' || type == null) {
        _navigateToReservationPage();
        debugPrint('✅ 예약 내역 화면으로 이동 시도');
      } else {
        debugPrint('ℹ️ 처리되지 않은 예약 알림 타입: $type');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 예약 알림 처리 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  // 예약 내역 화면으로 이동
  void _navigateToReservationPage() {
    if (navigatorKey?.currentState == null) {
      debugPrint('⚠️ navigatorKey.currentState가 null입니다');
      return;
    }

    try {
      final context = navigatorKey!.currentContext!;

      // 현재 경로 출력
      final currentRoute = ModalRoute.of(context)?.settings.name;
      debugPrint('현재 경로(이동 전): $currentRoute');

      // 이미 예약 내역 화면이 아닌지 확인
      if (!(currentRoute == '/reservation')) {
        debugPrint('🔔 예약 내역 화면으로 이동 시도...');

        // 화면 이동 시 기존 스택 정리 (메인 화면까지)
        navigatorKey!.currentState!.popUntil((route) => route.isFirst);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReservationPage(),
            settings: RouteSettings(name: '/reservation'),
          ),
        );

        debugPrint('✅ 예약 내역 화면으로 이동 완료');
      } else {
        debugPrint('ℹ️ 이미 예약 내역 화면에 있습니다');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 화면 이동 중 오류 발생: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
}