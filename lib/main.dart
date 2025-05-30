import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide User;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // 추가
import 'routes.dart';
import 'theme.dart';
import 'firebase_service.dart';
import 'services/fcm_service/fcm_service.dart';
import 'services/fcm_service/handlers/message_handler.dart';

// 전역 내비게이터 키는 message_handler.dart에서 가져옴
final GlobalKey<NavigatorState> navigatorKey = messageHandlerNavigatorKey;

// 비동기 초기화 함수들을 한 번에 실행하기 위한 클래스
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  bool _isInitialized = false;
  bool _secondaryInitComplete = false;

  // 필수 초기화 (Firebase 먼저)
  Future<void> initializeEssentials() async {
    if (_isInitialized) return;

    try {
      print('🔥 필수 서비스 초기화 시작');

      // .env 파일 먼저 로드 (API 키 사용 전에)
      await _initDotenv();

      // Firebase 먼저 초기화 (핵심 서비스로 가정)
      await _initFirebase();

      _isInitialized = true;
      print('✅ 필수 초기화 완료 - UI 렌더링 준비됨');
    } catch (e, stackTrace) {
      print('⚠️ 필수 초기화 중 오류 발생: $e');
      print('스택 트레이스: $stackTrace');
    }
  }

  // .env 파일 초기화 추가
  Future<void> _initDotenv() async {
    try {
      await dotenv.load(fileName: ".env");
      print('✅ .env 파일 로드 완료');

      // 환경 변수 확인 (디버깅용)
      final openaiKey = dotenv.env['OPENAI_API_KEY'];
      final googleKey = dotenv.env['GOOGLE_CLOUD_API_KEY'];

      print('🔑 OPENAI_API_KEY 존재: ${openaiKey != null && openaiKey.isNotEmpty}');
      print('🔑 GOOGLE_CLOUD_API_KEY 존재: ${googleKey != null && googleKey.isNotEmpty}');
    } catch (e) {
      print('⚠️ .env 파일 로드 실패: $e');
      print('⚠️ .env 파일이 프로젝트 루트에 있고 pubspec.yaml의 assets에 등록되어 있는지 확인하세요.');
    }
  }

  // 2차 초기화 (UI 렌더링 후)
  Future<void> initializeSecondary() async {
    if (_secondaryInitComplete) return;

    try {
      print('🔄 2차 초기화 시작 (백그라운드)');

      // FCM 서비스 초기화
      await FCMService.initialize();

      // 병렬로 실행 가능한 나머지 초기화 작업들
      await Future.wait([
        _initGoogleMaps(),
        _initKakaoSDK(),
        initializeDateFormatting('ko_KR', null),
      ]);

      // 인증 상태 리스너 설정 (가장 마지막에)
      _setupAuthStateListener();

      _secondaryInitComplete = true;
      print('✅ 2차 초기화 완료');
    } catch (e) {
      print('⚠️ 2차 초기화 중 오류 발생: $e');
    }
  }

  // Firebase 초기화 - 핵심 서비스
  Future<void> _initFirebase() async {
    try {
      final app = await FirebaseService.app;
      print('✅ Firebase 초기화 완료: ${app.name}');
    } catch (e) {
      print('⚠️ Firebase 초기화 실패: $e');
      rethrow;
    }
  }

  // Google Maps 초기화 - 2차 초기화에서 수행
  Future<void> _initGoogleMaps() async {
    try {
      final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
      if (mapsImplementation is GoogleMapsFlutterAndroid) {
        mapsImplementation.useAndroidViewSurface = true;
      }
      print('✅ Google Maps 초기화 완료');
    } catch (e) {
      print('⚠️ Google Maps 초기화 실패: $e');
    }
  }

  // 카카오 SDK 초기화 - 2차 초기화에서 수행
  Future<void> _initKakaoSDK() async {
    try {
      KakaoSdk.init(
        nativeAppKey: '5bdab3ee8da6a2c0ff7ef73ce749c5c8',
        javaScriptAppKey: '5bdab3ee8da6a2c0ff7ef73ce749c5c8',
      );
      print('✅ 카카오 SDK 초기화 완료');
    } catch (e) {
      print('⚠️ 카카오 SDK 초기화 실패: $e');
    }
  }

  // 인증 상태 리스너 설정
  void _setupAuthStateListener() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          print('👤 인증된 사용자 감지: ${user.uid}');
          Future.microtask(() {
            FCMService.onUserLogin(user.uid);
            print('✅ 사용자 FCM 토큰 업데이트 요청 완료');
          });
        } else {
          print('⚠️ 인증된 사용자 없음 - 알림 서비스 초기화 건너뜀');
        }
      });
      print('✅ 인증 상태 리스너 설정 완료');
    } catch (e, stackTrace) {
      print('⚠️ 인증 상태 리스너 설정 실패: $e');
      print('⚠️ 스택 트레이스: $stackTrace');
    }
  }

  // 앱이 포그라운드로 돌아올 때 사용
  Future<void> onAppResumed() async {
    print('🔄 앱이 포그라운드로 돌아옴');

    if (navigatorKey.currentContext != null) {
      final route = ModalRoute.of(navigatorKey.currentContext!);
      print('🔄 현재 라우트: ${route?.settings.name ?? "알 수 없음"}');
    }

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('🔄 현재 FCM 토큰 (앱 재개 시): $fcmToken');
    } catch (e) {
      print('⚠️ FCM 토큰 확인 오류: $e');
    }
  }

  // 알림 권한 요청 (UI 렌더링 후 호출)
  Future<void> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        if (status.isDenied) {
          print('📱 Android 알림 권한 요청');
          await Permission.notification.request();
        }

        final newStatus = await Permission.notification.status;
        print('📱 알림 권한 상태: $newStatus');
      } catch (e) {
        print('⚠️ 알림 권한 요청 중 오류: $e');
      }
    }
  }
}

void main() async {
  // 위젯 바인딩 및 스플래시 유지
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Firebase 등 필수 서비스만 먼저 초기화
    await AppInitializer().initializeEssentials();

    // 앱 실행
    runApp(const MyApp(initialRoute: '/'));

    // 스플래시 제거
    FlutterNativeSplash.remove();

    // UI 렌더링 후 나머지 초기화 작업 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 2차 초기화 작업 실행 (지연시켜서)
      Future.delayed(const Duration(milliseconds: 500), () {
        AppInitializer().initializeSecondary();
      });

      // 알림 권한 요청 (더 지연)
      Future.delayed(const Duration(seconds: 3), () {
        AppInitializer().requestNotificationPermission();
      });
    });
  } catch (e, stackTrace) {
    print('🚨 앱 초기화 치명적 오류: $e');
    print('🚨 스택 트레이스: $stackTrace');
    // 앱 실행 (최소 기능으로)
    runApp(const MyApp(initialRoute: '/'));
    FlutterNativeSplash.remove();
  }
}

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    print('📱 MyApp.initState 호출됨');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('📱 앱 생명주기 상태 변경: $state');
    if (state == AppLifecycleState.resumed) {
      AppInitializer().onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    print('📱 MyApp.dispose 호출됨');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('📱 MyApp.build 호출됨');
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: widget.initialRoute,
      onGenerateRoute: (settings) {
        print('📱 라우트 생성: ${settings.name}');
        if (appRoutes.containsKey(settings.name)) {
          return MaterialPageRoute(
            builder: (context) => appRoutes[settings.name]!(context),
            settings: settings,
          );
        }

        print('⚠️ 알 수 없는 라우트: ${settings.name}, 기본 라우트(/)로 이동');
        return MaterialPageRoute(
          builder: (context) => appRoutes['/']!(context),
          settings: const RouteSettings(name: '/'),
        );
      },
      theme: appTheme,
    );
  }
}