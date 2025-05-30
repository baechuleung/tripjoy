// lib/chat/controllers/chat_controller.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../../tripfriends/reservation/reservation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/plan_show_dialog.dart';

class ChatController {
  final String userId;
  final String friendsId;
  final String friendsName;
  final BuildContext context;
  final ChatService chatService;
  final Function updateState;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  DateTime lastRefreshTime = DateTime.now();
  List<ChatMessage> messages = [];
  bool initialLoadComplete = false;
  bool isReservationCompleted = false;
  bool isCheckingReservation = true;
  bool isPlanRequestFilled = false; // 예약 정보가 모두 입력되었는지 여부
  late String chatId;
  Map<String, dynamic>? reservationData; // 예약 데이터 저장

  ChatController({
    required this.userId,
    required this.friendsId,
    required this.friendsName,
    required this.context,
    required this.updateState,
    ChatService? service,
  }) : chatService = service ?? ChatService() {
    chatId = chatService.getChatId(userId, friendsId);

    // 현재 활성화된 채팅방 설정 (푸시 알림 제어용)
    ChatService.setActiveChatId(chatId);
    print('채팅 화면 진입: 활성 채팅방 ID $chatId 설정됨');

    // 채팅방 입장 시 메시지를 읽음 상태로 표시
    chatService.markMessagesAsRead(userId, friendsId);

    // 디버깅용 로그 - 사용자앱의 사용자 ID 확인
    print('사용자앱 - 사용자ID: $userId, 프렌즈ID: $friendsId');
  }

  // 초기화 및 리소스 해제
  void dispose() {
    // 화면이 종료될 때 활성 채팅방 ID 초기화
    ChatService.setActiveChatId(null);
    print('채팅 화면 종료: 활성 채팅방 ID 초기화됨');

    messageController.dispose();
    scrollController.dispose();
  }

  // 예약 상태 로드 함수
  Future<void> loadReservationStatus() async {
    updateState(() {
      isCheckingReservation = true;
    });

    try {
      // 1. 예약 진행 상태 확인 (in_progress 상태인지)
      final hasInProgressReservation = await chatService.checkReservationStatus(friendsId);

      // 2. 예약 정보 입력 상태 확인
      await _checkPlanRequestStatus();

      updateState(() {
        isReservationCompleted = hasInProgressReservation;
        isCheckingReservation = false;
      });
    } catch (error) {
      print('예약 상태 로드 오류: $error');
      updateState(() {
        isCheckingReservation = false;
      });
    }
  }

  // 예약 정보 입력 상태 확인 (추가된 함수)
  Future<void> _checkPlanRequestStatus() async {
    try {
      // ChatService를 통해 예약 데이터 로드
      final result = await chatService.loadReservationData(userId, friendsId);

      // 오류가 있는 경우
      if (result.containsKey('error')) {
        updateState(() {
          isPlanRequestFilled = false;
        });
        return;
      }

      // 예약 데이터 저장
      reservationData = result['reservationData'];

      // 필수 필드들이 모두 입력되었는지 확인
      bool isComplete = _isPlanRequestComplete(reservationData);

      updateState(() {
        isPlanRequestFilled = isComplete;
      });

      print('예약 정보 입력 상태: $isPlanRequestFilled');
    } catch (e) {
      print('예약 정보 확인 오류: $e');
      updateState(() {
        isPlanRequestFilled = false;
      });
    }
  }

  // 예약 정보가 모두 입력되었는지 확인하는 함수 (타입 체크 로직 수정)
  bool _isPlanRequestComplete(Map<String, dynamic>? data) {
    if (data == null) return false;

    print('meetingPlace 필드 확인: ${data['meetingPlace']}');

    // 각 필수 필드 확인 (타입 체크 수정)

    // 1. meetingPlace 확인 (Map/Object 타입)
    bool hasMeetingPlace = data.containsKey('meetingPlace') &&
        data['meetingPlace'] != null &&
        data['meetingPlace'] is Map &&
        (data['meetingPlace'] as Map).isNotEmpty;

    // 2. personCount 확인 (숫자 또는 문자열 형태의 숫자)
    bool hasPersonCount = data.containsKey('personCount') &&
        data['personCount'] != null;

    // 3. purpose 확인 (List/Array 타입)
    bool hasPurpose = data.containsKey('purpose') &&
        data['purpose'] != null &&
        data['purpose'] is List &&
        (data['purpose'] as List).isNotEmpty;

    // 4. startTime 확인 (문자열)
    bool hasStartTime = data.containsKey('startTime') &&
        data['startTime'] != null &&
        data['startTime'].toString().isNotEmpty;

    // 5. useDate 확인 (문자열)
    bool hasUseDate = data.containsKey('useDate') &&
        data['useDate'] != null &&
        data['useDate'].toString().isNotEmpty;

    print('필드 상태 체크:');
    print('meetingPlace=$hasMeetingPlace');
    print('personCount=$hasPersonCount');
    print('purpose=$hasPurpose');
    print('startTime=$hasStartTime');
    print('useDate=$hasUseDate');

    // 모든 필드가 입력되었는지 여부 반환
    return hasMeetingPlace && hasPersonCount && hasPurpose && hasStartTime && hasUseDate;
  }

// 메시지 목록 로드 - 수정된 버전
  void loadMessages() {
    chatService.getMessages(userId, friendsId)
        .listen((newMessages) {
      updateState(() {
        messages = newMessages;
        initialLoadComplete = true;

        // 읽지 않은 메시지 자동 읽음 표시
        final unreadMessages = newMessages.where((msg) =>
        msg.senderId == friendsId &&
            msg.receiverId == userId &&  // receiverId도 확인
            !msg.isRead).toList();

        if (unreadMessages.isNotEmpty) {
          print('읽지 않은 메시지 ${unreadMessages.length}개 발견, 읽음 표시 처리');
          // markMessagesAsRead 호출하여 실제로 DB 업데이트
          chatService.markMessagesAsRead(userId, friendsId);
        }
      });
    });
  }

  // 메시지 읽음 상태 갱신 함수 - 디바운싱 적용
  void refreshReadStatus() {
    final now = DateTime.now();
    // 마지막 새로고침 이후 1초 이상 지났을 때만 실행 (과도한 호출 방지)
    if (now.difference(lastRefreshTime).inMilliseconds > 1000) {
      lastRefreshTime = now;
      chatService.quickMarkAsRead(userId, friendsId);
      print('읽음 상태 업데이트: ${DateTime.now()}');
    }
  }

  // 메시지 전송 함수
  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    // 디버깅 로그 추가 - ID값 확인
    print('메시지 전송 - 사용자ID: $userId, 프렌즈ID: $friendsId');

    try {
      // 현재 컨트롤러에서 텍스트 가져오기 (클리어 전에)
      final messageText = messageController.text.trim();

      // 텍스트 필드 즉시 초기화 (포커스는 유지)
      messageController.clear();

      // 메시지 전송 - 포커스 손실 방지를 위해 Future로 처리
      Future(() {
        return chatService.sendMessage(
          userId,
          friendsId,
          messageText,
        );
      }).then((_) {
        // 메시지 전송 성공 후 읽음 상태 갱신
        refreshReadStatus();
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 전송 실패: $e')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 전송 처리 오류: $e')),
      );
    }
  }

  // 프렌즈 정보로 plan_request 생성하기
  // _createPlanRequestFromFriendsInfo 메서드 수정
  Future<String?> _createPlanRequestFromFriendsInfo() async {
    try {
      print("========== plan_request 자동 생성 시작 ==========");
      print("사용자ID: $userId, 프렌즈ID: $friendsId");

      // 파이어스토어 인스턴스
      final firestore = FirebaseFirestore.instance;

      // 1. 프렌즈의 location 정보 가져오기
      final friendsDoc = await firestore
          .collection('tripfriends_users')
          .doc(friendsId)
          .get();

      if (!friendsDoc.exists || friendsDoc.data() == null) {
        print("프렌즈 정보를 찾을 수 없습니다");
        return null;
      }

      final friendsData = friendsDoc.data()!;
      if (!friendsData.containsKey('location')) {
        print("프렌즈의 location 정보가 없습니다");
        return null;
      }

      // 프렌즈의 location 정보 추출
      final location = friendsData['location'];
      final nationality = location['nationality'];
      final city = location['city'];

      print("프렌즈 location 정보: nationality=$nationality, city=$city");

      // 2. 유저 정보 가져오기
      final userDoc = await firestore.collection('users').doc(userId).get();
      String userName = '사용자';
      String userEmail = '';  // 이메일 변수 추가
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        if (userData.containsKey('name')) {
          userName = userData['name'];
        }
        if (userData.containsKey('email')) {  // 이메일 정보 가져오기
          userEmail = userData['email'];
        }
      }

      // 3. plan_request 데이터 구성
      final timestamp = FieldValue.serverTimestamp();
      final planRequestData = {
        'userId': userId,
        'userEmail': userEmail,  // 이메일 정보 추가
        'userName': userName,
        'location': {
          'nationality': nationality,
          'city': city
        },
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      print("생성할 plan_request 데이터: $planRequestData");

      // 4. plan_request 문서 생성
      final docRef = await firestore
          .collection('users')
          .doc(userId)
          .collection('plan_requests')
          .add(planRequestData);

      print("plan_request 생성 성공 - ID: ${docRef.id}");
      print("========== plan_request 자동 생성 완료 ==========");

      return docRef.id;
    } catch (e) {
      print("========== plan_request 자동 생성 오류 ==========");
      print("오류 내용: $e");
      return null;
    }
  }

  // 프렌즈 location 정보 가져오기
  Future<Map<String, dynamic>?> _getFriendsLocationInfo() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final friendsDoc = await firestore
          .collection('tripfriends_users')
          .doc(friendsId)
          .get();

      if (!friendsDoc.exists || friendsDoc.data() == null) {
        return null;
      }

      final friendsData = friendsDoc.data()!;
      if (!friendsData.containsKey('location')) {
        return null;
      }

      final location = friendsData['location'];
      return {
        'nationality': location['nationality'],
        'city': location['city'],
      };
    } catch (e) {
      print("프렌즈 location 정보 조회 오류: $e");
      return null;
    }
  }
// chat_controller.dart 파일의 navigateToReservationPage 메서드를 수정합니다.
  Future<void> navigateToReservationPage() async {
    try {
      print("========== 예약정보 입력 과정 시작 ==========");
      print("userId: $userId, friendsId: $friendsId, friendsName: $friendsName");

      // 예약 데이터가 없는 경우에만 로딩
      if (reservationData == null) {
        // 로딩 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // ChatService를 통해 예약 데이터 로드
        final result = await chatService.loadReservationData(userId, friendsId);

        // 로딩 다이얼로그 닫기
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // 오류 처리 - plan_requests가 없는 경우 사용자 확인 후 자동 생성
        if (result.containsKey('error') && result['error'] == 'no_plan_requests') {
          print("plan_requests 문서가 없음. 프렌즈 정보로 자동 생성 확인 요청");

          // 프렌즈 location 정보 가져오기
          final locationInfo = await _getFriendsLocationInfo();

          if (locationInfo == null) {
            // 프렌즈 정보 없음
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('프렌즈 정보를 불러올 수 없습니다.')),
            );
            print("========== 예약정보 입력 과정 중단 ==========");
            return;
          }

          // 확인 다이얼로그 표시 - plan_show_dialog.dart의 함수 사용
          final confirmed = await showPlanConfirmDialog(
            context: context,
            countryCode: locationInfo['nationality'],
            cityData: locationInfo['city'],
          );

          if (!confirmed) {
            // 사용자가 취소함
            print("사용자가 여행 지역 확인을 취소했습니다.");
            print("========== 예약정보 입력 과정 중단 ==========");
            return;
          }

          // 사용자 확인 후 plan_request 생성
          print("사용자가 여행 지역 확인을 승인했습니다. plan_request 생성 진행");

          // 로딩 표시
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          // 자동으로 plan_request 생성
          final requestId = await _createPlanRequestFromFriendsInfo();

          // 로딩 다이얼로그 닫기
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          if (requestId == null) {
            // 생성 실패
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('예약 정보를 생성하는 중 오류가 발생했습니다.')),
            );
            print("========== 예약정보 입력 과정 중단 ==========");
            return;
          }

          // 생성 성공 - 데이터 다시 로드
          final newResult = await chatService.loadReservationData(userId, friendsId);

          if (newResult.containsKey('error')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('예약 정보를 불러오는 중 오류가 발생했습니다.')),
            );
            print("========== 예약정보 입력 과정 중단 ==========");
            return;
          }

          // 예약 데이터 저장
          reservationData = newResult['reservationData'];
        } else if (result.containsKey('error')) {
          // 기타 오류
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('예약 정보를 불러오는 중 오류가 발생했습니다.')),
          );
          print("========== 예약정보 입력 과정 중단 ==========");
          return;
        } else {
          // 정상적으로 데이터 로드
          reservationData = result['reservationData'];
        }
      }

      // 중요: 필요한 필드들 추가 (friendUserId, friends_uid)
      if (reservationData != null) {
        // 예약번호 생성
        if (!reservationData!.containsKey('reservationNumber')) {
          String reservationNumber = _generateReservationNumber();
          reservationData!['reservationNumber'] = reservationNumber;
        }

        // 필수 필드 추가
        reservationData!['friendUserId'] = friendsId;
        reservationData!['friends_uid'] = friendsId;

        print("필수 필드 추가됨: friendUserId, friends_uid");
        print("reservationData 키들: ${reservationData!.keys.toList()}");
      }

      // 예약 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReservationPage(
            reservationId: '',
            friendsId: friendsId,
            reservationData: reservationData!,
            userId: userId,
            requestId: reservationData!.containsKey('requestId')
                ? reservationData!['requestId']
                : '',
          ),
        ),
      ).then((_) {
        // 예약 페이지에서 돌아왔을 때 상태 다시 확인
        _checkPlanRequestStatus();
      });

      print("========== 예약정보 입력 과정 완료 ==========");
    } catch (e) {
      // 로딩 다이얼로그가 표시된 경우 닫기
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // 오류 메시지 표시
      print('========== 데이터 조회 중 오류 발생 ==========');
      print('오류 내용: $e');
      print('오류 스택: ${StackTrace.current}');

      // 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약 정보를 불러오는 중 오류가 발생했습니다.')),
      );
    }
  }

// 예약 번호 생성 함수 추가
  String _generateReservationNumber() {
    // 현재 시간을 가져옴
    final now = DateTime.now();

    // 날짜 부분 (YYYYMMDD 형식)
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // 영어 + 숫자 조합의 4자리 난수 생성
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomPart = '';

    // 4자리 영문+숫자 조합 생성
    for (int i = 0; i < 4; i++) {
      final randomIndex = now.millisecondsSinceEpoch % chars.length + i;
      randomPart += chars[randomIndex % chars.length];
    }

    // 최종 예약번호: 날짜 + 난수 (하이픈 없음)
    return '$dateStr$randomPart';
  }

  // 앱 상태 변경 감지
  void handleAppLifecycleStateChange(AppLifecycleState state) {
    // 앱이 백그라운드로 갈 때 활성 채팅방 ID 초기화
    if (state == AppLifecycleState.paused) {
      ChatService.setActiveChatId(null);
      print('앱 백그라운드: 활성 채팅방 ID 초기화됨');
    }

    // 앱이 포그라운드로 돌아왔을 때 다시 활성 채팅방 ID 설정
    if (state == AppLifecycleState.resumed) {
      ChatService.setActiveChatId(chatId);
      print('앱 포그라운드: 활성 채팅방 ID $chatId 재설정됨');

      // 읽음 상태 갱신
      refreshReadStatus();
    }
  }
}