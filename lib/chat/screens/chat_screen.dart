// lib/chat/screens/chat_screen.dart - 리팩토링된 고객용 채팅 화면
import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_navigation_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_warning_notice.dart';
import '../../services/fcm_service/handlers/chat_handler.dart'; // 수정된 경로

class ChatScreen extends StatefulWidget {
  final String userId;
  final String friendsId;
  final String friendsName;
  final String? friendsImage;

  const ChatScreen({
    Key? key,
    required this.userId,
    required this.friendsId,
    required this.friendsName,
    this.friendsImage,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late ChatController _controller;

  @override
  void initState() {
    super.initState();

    // 위젯 바인딩 옵저버 등록
    WidgetsBinding.instance.addObserver(this);

    // 상태 업데이트 콜백 생성
    void updateState(VoidCallback fn) {
      if (mounted) setState(fn);
    }

    // 채팅 컨트롤러 초기화
    _controller = ChatController(
      userId: widget.userId,
      friendsId: widget.friendsId,
      friendsName: widget.friendsName,
      context: context,
      updateState: updateState,
    );

    // 메시지 및 상태 로드
    _controller.loadMessages();
    _controller.loadReservationStatus();

    // 채팅방 진입 시 현재 채팅방 정보 설정
    // _controller 초기화 후에 호출합니다
    ChatHandler.setCurrentChatRoom(
        widget.userId,
        widget.friendsId,
        chatId: _controller.chatId
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _controller.handleAppLifecycleStateChange(state);

    // 앱이 포그라운드로 돌아올 때 채팅방 상태 업데이트
    if (state == AppLifecycleState.resumed) {
      ChatHandler.setCurrentChatRoom(
          widget.userId,
          widget.friendsId,
          chatId: _controller.chatId
      );
    } else if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드로 갈 때 상태 초기화
      ChatHandler.clearCurrentChatRoom();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 화면 크기나 키보드 상태가 변경될 때의 작업
  }

  // 키보드 내리기 및 포커스 해제 함수
  void _dismissKeyboard() {
    // 현재 포커스 노드에서 포커스 해제하여 키보드 닫기
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 키보드가 올라와도 화면 크기가 조정되도록 설정
      resizeToAvoidBottomInset: true,

      // 헤더(앱바) 위젯
      appBar: ChatHeader(
        userId: widget.userId,
        friendsId: widget.friendsId,
        chatId: _controller.chatId,
        friendsName: widget.friendsName,
        friendsImage: widget.friendsImage,
      ),

      body: SafeArea(
        bottom: false, // 하단 안전 영역 비활성화 (입력 필드가 키보드 위에 완전히 보이도록)
        child: Column(
          children: [
            // 유의사항 위젯 (예약하기 버튼보다 위에 위치)
            const ChatWarningNotice(),

            // 네비게이션 바 - 예약하기 버튼
            ChatNavigationBar(
              isCheckingReservation: _controller.isCheckingReservation,
              isReservationCompleted: _controller.isReservationCompleted,
              onReservationPressed: _controller.navigateToReservationPage,
            ),

            // 구분선과 그림자를 포함한 컨테이너
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 2), // 아래쪽으로 그림자
                  ),
                ],
              ),
              child: const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFEEEEEE),
              ),
            ),

            // 채팅 영역
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissKeyboard, // 화면 탭할 때만 키보드 내림
                onPanDown: (_) => _controller.refreshReadStatus(),
                child: Column(
                  children: [
                    // 메시지 목록 - Expanded로 감싸서 남은 공간을 모두 차지하도록 함
                    Expanded(
                      child: ChatMessageList(
                        messages: _controller.messages,
                        initialLoadComplete: _controller.initialLoadComplete,
                        userId: widget.userId,
                        friendsImage: widget.friendsImage,
                        scrollController: _controller.scrollController,
                      ),
                    ),

                    // 메시지 입력 필드
                    ChatInputField(
                      controller: _controller.messageController,
                      onSend: _controller.sendMessage,
                      onTap: _controller.refreshReadStatus,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 채팅방 나갈 때 상태 초기화
    ChatHandler.clearCurrentChatRoom();

    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}