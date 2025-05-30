import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripjoy/chat/screens/chat_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatNotificationHandler {
  // 싱글톤 패턴 구현
  static final ChatNotificationHandler _instance = ChatNotificationHandler._internal();

  factory ChatNotificationHandler() => _instance;

  ChatNotificationHandler._internal();

  // 현재 활성화된 채팅방 정보를 저장할 정적 변수들
  static String? _currentUserId;
  static String? _currentFriendId;
  static String? _currentChatId;
  static bool _isInChatScreen = false;

  // 현재 채팅방 상태 업데이트 (ChatScreen에서 호출하도록 함)
  static void setCurrentChatRoom(String userId, String friendId, {String? chatId}) {
    _currentUserId = userId;
    _currentFriendId = friendId;

    // chatId가 제공되면 사용, 아니면 userId와 friendId를 조합하여 생성
    // 일관성을 위해 둘 중 작은 값을 앞에 두고 생성
    if (chatId != null) {
      _currentChatId = chatId;
    } else {
      // userId와 friendId를 정렬하여 일관된 chatId 형태를 생성
      List<String> ids = [userId, friendId];
      ids.sort(); // 오름차순 정렬
      _currentChatId = '${ids[0]}_${ids[1]}';
    }

    _isInChatScreen = true;
    debugPrint('💬 [채팅] 현재 채팅방 설정: userId=$userId, friendId=$friendId, chatId=$_currentChatId');
  }

  // 채팅방에서 나갈 때 호출
  static void clearCurrentChatRoom() {
    _isInChatScreen = false;
    debugPrint('💬 [채팅] 채팅방 나감: 상태 초기화');
  }

  // 앱 내 경로 이동을 위한 네비게이터 키
  GlobalKey<NavigatorState>? navigatorKey;

  // 로컬 알림을 위한 플러그인
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  // Android용 알림 채널 ID
  static const String channelId = 'chat_channel';
  static const String channelName = '채팅 알림';
  static const String channelDescription = '채팅 관련 알림을 위한 채널입니다.';

  // 초기화 여부
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // 초기화 메소드
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    if (_isInitialized) {
      debugPrint('🔔 ChatNotificationHandler가 이미 초기화되어 있습니다.');
      return;
    }

    debugPrint('🔔 ChatNotificationHandler 초기화 중...');

    // navigatorKey 설정
    navigatorKey = navKey;

    // 로컬 알림 초기화
    await _initLocalNotifications();

    _isInitialized = true;
    debugPrint('✅ ChatNotificationHandler 초기화 완료');
  }

  // 로컬 알림 초기화
  Future<void> _initLocalNotifications() async {
    try {
      debugPrint('🔔 로컬 알림 초기화 시작 (채팅)');

      // Android 설정
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 설정 (onDidReceiveLocalNotification 파라미터 제거)
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
          debugPrint('🔔 [채팅] 로컬 알림 클릭됨: ${notificationResponse.payload}');

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

      debugPrint('✅ 로컬 알림 초기화 완료 (채팅)');
    } catch (e, stackTrace) {
      debugPrint('⚠️ 로컬 알림 초기화 실패 (채팅): $e');
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
    debugPrint('🔔 [채팅] 로컬 알림 페이로드: $payloadMap');

    final userId = payloadMap['receiver_id'];
    final friendsId = payloadMap['sender_id'];
    final chatId = payloadMap['chat_id'];

    if (userId != null && friendsId != null && chatId != null) {
      await _loadFriendsInfoAndNavigate(userId, friendsId, chatId);
    } else {
      debugPrint('⚠️ [채팅] 로컬 알림에 필요한 정보가 없습니다');
    }
  }

  // 채팅 관련 알림인지 확인
  bool isChatNotification(RemoteMessage message) {
    final type = message.data['type'];
    debugPrint('📩 알림 타입 확인: $type');
    return type == 'message';
  }

  // FCM 메시지를 로컬 알림으로 표시 (앱이 실행 중일 때) - 로컬 알림 생성 비활성화
  Future<void> showLocalNotification(RemoteMessage message) async {
    try {
      // 메시지 데이터 가져오기
      final Map<String, dynamic> data = message.data;
      final String? senderId = data['sender_id'];
      final String? receiverId = data['receiver_id'];
      final String? chatId = data['chat_id'];

      // 발신자 이름 (있으면 사용, 없으면 기본값)
      final String senderName = data['sender_name'] ?? '프렌즈';

      debugPrint('💬 [채팅] 현재 채팅방 상태: 활성=$_isInChatScreen, userId=$_currentUserId, friendId=$_currentFriendId');
      debugPrint('💬 [채팅] 수신 메시지: senderId=$senderId, receiverId=$receiverId, chatId=$chatId');

      // 채팅방에 있고, 현재 채팅방이 메시지를 보낸 채팅방과 같은지 확인
      if (_isInChatScreen) {
        bool isSameChatRoom = false;
        debugPrint('💬 [채팅] 채팅방 ID 비교: 현재=$_currentChatId, 수신=$chatId');

        // 채팅방 ID로 비교
        if (_currentChatId != null && chatId != null) {
          isSameChatRoom = (_currentChatId == chatId);

          // chatId 포맷이 다를 수 있으므로 두 가지 경우도 확인
          if (!isSameChatRoom && _currentUserId != null && _currentFriendId != null) {
            isSameChatRoom =
                (chatId == '${_currentUserId}_${_currentFriendId}') ||
                    (chatId == '${_currentFriendId}_${_currentUserId}');
          }
        }

        // 사용자-친구 조합으로 비교
        if (!isSameChatRoom && _currentFriendId != null && _currentUserId != null) {
          isSameChatRoom = (_currentFriendId == senderId && _currentUserId == receiverId) ||
              (_currentFriendId == receiverId && _currentUserId == senderId);
          debugPrint('💬 [채팅] 사용자-친구 조합 비교: $isSameChatRoom');
          debugPrint('💬 [채팅] 비교 데이터: currentFriendId=$_currentFriendId, senderId=$senderId, currentUserId=$_currentUserId, receiverId=$receiverId');
        }

        if (isSameChatRoom) {
          debugPrint('💬 [채팅] 현재 같은 채팅방에 있어 알림 표시하지 않음');
          return;
        }
      }

      // 로컬 알림 생성 코드 제거
      debugPrint('✅ [채팅] 서버 알림만 사용, 로컬 알림 생성 안함');
    } catch (e, stackTrace) {
      debugPrint('❌ [채팅] 알림 처리 오류: $e');
      debugPrint('❌ 스택 트레이스: $stackTrace');
    }
  }

  // 메시지 핸들링 - 채팅 알림 처리 (알림 클릭시에만 실행됨)
  void handleMessage(RemoteMessage message) {
    try {
      final Map<String, dynamic> data = message.data;
      final String? type = data['type'];

      debugPrint('📱 [Chat] 알림 클릭 처리 시작: 타입=$type');

      // 채팅 알림이 아니면 무시 (하지만 데이터가 없는 경우는 진행)
      if (type != null && type != 'message') {
        debugPrint('ℹ️ 채팅 알림이 아닌 메시지: $type');
        return;
      }

      final String? chatId = data['chat_id'];
      final String? senderId = data['sender_id'];
      final String? receiverId = data['receiver_id'];

      debugPrint('💬 채팅 알림 클릭 처리: chatId=$chatId, senderId=$senderId, receiverId=$receiverId');

      if (navigatorKey?.currentState == null) {
        debugPrint('⚠️ 네비게이터 키가 없어 경로 이동 불가');
        return;
      }

      // chatId, senderId, receiverId가 모두 있는지 확인
      if (chatId != null && senderId != null && receiverId != null) {
        // 현재 스택 상태 로깅
        final context = navigatorKey!.currentContext;
        if (context != null) {
          final route = ModalRoute.of(context);
          debugPrint('현재 경로 이름: ${route?.settings.name}');
        } else {
          debugPrint('⚠️ context가 null입니다');
          return; // 컨텍스트가 없으면 이동 불가
        }

        _loadFriendsInfoAndNavigate(receiverId, senderId, chatId);
      } else {
        debugPrint('⚠️ 채팅 알림에 필요한 정보가 없습니다');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 채팅 알림 처리 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  // 친구 정보를 로드하고 채팅 화면으로 이동
  Future<void> _loadFriendsInfoAndNavigate(String userId, String friendsId, String chatId) async {
    try {
      debugPrint('🔍 친구 정보 조회 중: userId=$userId, friendsId=$friendsId, chatId=$chatId');

      // 친구 정보 조회 - 먼저 tripfriends_users 컬렉션에서 시도
      DocumentSnapshot friendDoc = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(friendsId)
          .get();

      debugPrint('tripfriends_users에서 친구 정보 조회 결과: ${friendDoc.exists ? "존재함" : "없음"}');

      // tripfriends_users에 없으면 users 컬렉션에서 조회
      if (!friendDoc.exists) {
        friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendsId)
            .get();
        debugPrint('users에서 친구 정보 조회 결과: ${friendDoc.exists ? "존재함" : "없음"}');
      }

      String friendsName = "프렌즈";
      String? friendsImage;

      // 친구 정보가 있으면 이름과 이미지 가져오기
      if (friendDoc.exists) {
        final data = friendDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          friendsName = data['name'] ?? "프렌즈";

          // profileImageUrl이 기본 필드명
          friendsImage = data['profileImageUrl'] ??
              data['profileUrl'] ??
              data['profileImage'] ??
              data['profile_image'];

          debugPrint('👤 친구 정보 로드 성공: 이름=$friendsName, 이미지=$friendsImage');
        }
      }

      // 채팅 화면으로 이동
      _navigateToChatScreen(userId, friendsId, friendsName, friendsImage);

    } catch (e, stackTrace) {
      debugPrint('❌ 친구 정보 로드 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');

      // 오류가 발생해도 최소한의 정보로 채팅 화면 이동 시도
      _navigateToChatScreen(userId, friendsId, "프렌즈", null);
    }
  }

  // 채팅 화면으로 이동
  void _navigateToChatScreen(String userId, String friendsId, String friendsName, String? friendsImage) {
    if (navigatorKey?.currentState == null) {
      debugPrint('⚠️ navigatorKey.currentState가 null입니다');
      return;
    }

    debugPrint('🔔 채팅 화면으로 이동 시도: 사용자=$userId, 친구=$friendsId, 이름=$friendsName');

    try {
      final context = navigatorKey!.currentContext!;

      // 현재 경로 출력
      final currentRoute = ModalRoute.of(context)?.settings.name;
      debugPrint('현재 경로(이동 전): $currentRoute');

      // 이미 같은 채팅방에 있는지 확인
      bool isAlreadyInChatRoom = false;
      navigatorKey!.currentState!.popUntil((route) {
        if (route.settings.name == '/chat_screen') {
          // 경로의 arguments를 확인하여 같은 채팅방인지 확인
          final args = route.settings.arguments;
          if (args is Map<String, dynamic> &&
              args['friendsId'] == friendsId &&
              args['userId'] == userId) {
            isAlreadyInChatRoom = true;
            return true;
          }
        }
        return route.isFirst;
      });

      // 이미 같은 채팅방에 있으면 이동하지 않음
      if (isAlreadyInChatRoom) {
        debugPrint('ℹ️ 이미 같은 채팅방에 있습니다');
        return;
      }

      // 채팅 화면으로 이동
      navigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: userId,
            friendsId: friendsId,
            friendsName: friendsName,
            friendsImage: friendsImage,
          ),
          settings: RouteSettings(
            name: '/chat_screen',
            arguments: {
              'userId': userId,
              'friendsId': friendsId,
            },
          ),
        ),
      );

      debugPrint('✅ 채팅 화면으로 이동 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ 화면 이동 중 오류 발생: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
}