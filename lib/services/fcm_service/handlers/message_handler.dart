import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/android_config.dart';
import '../config/ios_config.dart';
import 'reservation_handler.dart';
import 'chat_handler.dart';
import '../fcm_service.dart';

// 전역 내비게이터 키 (앱 어디서나 내비게이션 접근 가능)
final GlobalKey<NavigatorState> messageHandlerNavigatorKey = GlobalKey<NavigatorState>();

// 전역 백그라운드 핸들러
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  print('🔔 백그라운드 메시지 수신: ${message.notification?.title}');

  // 백그라운드에서 메시지를 받으면 배지 수 증가
  if (Platform.isIOS) {
    // 백그라운드에서는 FCMService를 직접 사용할 수 없으므로
    // 다음에 앱이 열릴 때 처리하도록 함
    print('🔔 백그라운드 메시지 - 배지 업데이트는 앱 시작 시 처리');
  }
}

class MessageHandler {
  // 외부에서 접근 가능한 백그라운드 핸들러
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    await firebaseBackgroundMessageHandler(message);
  }

  // 알림 설정
  static Future<void> setupMessageHandlers() async {
    print('🔔 메시지 핸들러 설정 시작');

    // FCM 권한 요청 (iOS에서 필요)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('🔔 FCM 알림 권한 상태: ${settings.authorizationStatus}');

    // 앱이 포그라운드 상태일 때 알림 표시 설정 (iOS)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 포그라운드 알림 핸들러 등록
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 [onMessage] 포그라운드 메시지 수신: ${message.notification?.title}');
      print('🔍 [onMessage] 메시지 데이터: ${message.data}');
      handleForegroundMessage(message);
    });

    // 앱이 백그라운드에서 열릴 때 핸들러 등록
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 [onMessageOpenedApp] 알림을 통해 앱 열림: ${message.notification?.title}');
      print('🔍 [onMessageOpenedApp] 메시지 데이터: ${message.data}');

      // 알림을 클릭하여 앱을 열었으므로 배지 클리어
      FCMService.clearBadge();

      if (message.data.isNotEmpty) {
        print('👆 알림 클릭 처리 시작 (onMessageOpenedApp)');
        handleNotificationClick(message.data);
      }
    });

    // 앱이 종료된 상태에서 알림으로 열린 경우 처리
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🔔 [initialMessage] 종료 상태에서 알림으로 앱 실행됨: ${initialMessage.notification?.title}');
      print('🔍 [initialMessage] 초기 메시지 데이터: ${initialMessage.data}');

      // 알림을 클릭하여 앱을 열었으므로 배지 클리어
      await FCMService.clearBadge();

      if (initialMessage.data.isNotEmpty) {
        Future.delayed(const Duration(seconds: 2), () {
          print('👆 알림 클릭 처리 시작 (initialMessage)');
          handleNotificationClick(initialMessage.data);
        });
      }
    } else {
      print('⚠️ 초기 메시지 없음');
    }

    print('✅ 메시지 핸들러 설정 완료');
  }

  // 알림 탭 핸들러
  static void onNotificationResponse(NotificationResponse response) {
    print('👆 [onNotificationResponse] 알림 클릭됨: ${response.payload}');

    // 알림 클릭 시 배지 클리어
    FCMService.clearBadge();

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        Map<String, dynamic> data = json.decode(response.payload!);
        print('👆 파싱된 알림 데이터: $data');
        handleNotificationClick(data);
      } catch (e) {
        print('⚠️ 알림 페이로드 파싱 실패: $e');
      }
    }
  }

  // 알림 클릭 처리
  static void handleNotificationClick(Map<String, dynamic> data) {
    String? type = data['type'];
    print('👆 알림 클릭 처리: 타입=$type, 데이터=$data');

    print('🔍 NavigatorKey 상태: ${messageHandlerNavigatorKey.currentState != null ? "사용 가능" : "사용 불가"}');

    if (messageHandlerNavigatorKey.currentState == null) {
      print('⚠️ 내비게이터 상태가 없습니다. 1초 후 재시도합니다.');
      Future.delayed(const Duration(seconds: 1), () {
        if (messageHandlerNavigatorKey.currentState != null) {
          _processNotificationClick(type, data);
        } else {
          print('⚠️ 내비게이터 상태가 여전히 없습니다. 3초 후 마지막으로 재시도합니다.');
          Future.delayed(const Duration(seconds: 3), () {
            _processNotificationClick(type, data);
          });
        }
      });
    } else {
      _processNotificationClick(type, data);
    }
  }

  // 실제 알림 클릭 처리 로직
  static void _processNotificationClick(String? type, Map<String, dynamic> data) {
    print('🔍 알림 처리 시작: type=$type');

    switch(type) {
      case 'reservation_in_progress':
        print('🔍 예약 알림 처리 시작');
        ReservationHandler.handleReservationRequest(data);
        break;

      case 'message':
        print('🔍 채팅 메시지 알림 처리 시작');
        ChatHandler.handleChatMessage(data);
        break;

      default:
        print('📋 기본 화면으로 이동 - 타입: $type');
    }
  }

  // 포그라운드 메시지 처리
  static void handleForegroundMessage(RemoteMessage message) {
    print('🔔 [handleForegroundMessage] 포그라운드 메시지 수신: ${message.notification?.title}');
    print('🔍 [handleForegroundMessage] 메시지 데이터: ${message.data}');

    // 메시지 타입 확인
    String? type = message.data['type'];

    // 채팅 메시지인 경우 현재 채팅방과 비교
    if (type == 'message') {
      String? chatId = message.data['chat_id'];
      String? senderId = message.data['sender_id'];
      String? receiverId = message.data['receiver_id'];

      // 현재 채팅방 상태 확인 - getter 메서드 사용
      if (ChatHandler.isInChatScreen && ChatHandler.currentChatId != null) {
        // chatId로 비교
        bool isSameChatRoom = (ChatHandler.currentChatId == chatId);

        // chatId가 다른 형식일 수 있으므로 추가 검증
        if (!isSameChatRoom && senderId != null && receiverId != null) {
          List<String> ids = [senderId, receiverId];
          ids.sort();
          String generatedChatId = '${ids[0]}_${ids[1]}';
          isSameChatRoom = (ChatHandler.currentChatId == generatedChatId);
        }

        if (isSameChatRoom) {
          print('💬 [채팅] 현재 같은 채팅방에 있어 포그라운드 알림 표시하지 않음');
          // 메시지 처리는 하되 알림은 표시하지 않음
          ChatHandler.processChatMessage(message.data);
          return;
        }
      }

      // 다른 채팅방의 메시지이거나 채팅방에 없는 경우 처리
      ChatHandler.processChatMessage(message.data);

      // iOS에서 배지 수 증가
      if (Platform.isIOS) {
        FCMService.incrementBadgeCount();
      }
    } else if (type == 'reservation_in_progress') {
      ReservationHandler.processReservationRequest(message.data);

      // iOS에서 배지 수 증가
      if (Platform.isIOS) {
        FCMService.incrementBadgeCount();
      }
    } else {
      // 기타 알림 타입도 배지 증가
      if (Platform.isIOS) {
        FCMService.incrementBadgeCount();
      }
    }
  }

  // iOS 배지 클리어 (더 이상 직접 사용하지 않음, FCMService 사용)
  static void _clearIOSBadge() {
    FCMService.clearBadge();
  }
}