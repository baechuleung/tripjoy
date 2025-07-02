// lib/chat/screens/chat_list_screen.dart - 트립프렌즈 앱(고객용)
import 'package:flutter/material.dart';
import '../models/chat_list_item.dart';
import '../controllers/chat_list_controller.dart';
import 'chat_screen.dart';
import 'package:tripjoy/components/tripfriends_bottom_navigator.dart';
import '../widgets/loading_spinner.dart'; // 로딩 스피너 import 추가

class ChatListScreen extends StatefulWidget {
  final String customerId;

  const ChatListScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late ChatListController _controller;
  bool _isLoading = true;
  List<ChatListItem> _chatItems = [];
  bool _isEditMode = false;
  Set<String> _selectedChatIds = {};

  // 텍스트 변수들
  String _chatListTitle = '채팅 리스트';
  String _emptyChatListText = '아직 채팅이 없습니다';
  String _deleteButtonText = '삭제하기';
  String _unblockButtonText = '차단 해제하기';
  String _loadingText = '채팅 목록을 불러오는 중...'; // 로딩 메시지 추가

  // 바텀 네비게이션 인덱스
  final int _currentIndex = 3; // 채팅은 인덱스 3
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = ChatListController(customerId: widget.customerId);
    _controller.addListener(_updateState);
    _loadChatList();
    _controller.startRealTimeUpdates(); // 실시간 업데이트 시작
  }

  void _loadChatList() async {
    await _controller.loadChatList();
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        _isLoading = _controller.isLoading;
        _chatItems = _controller.chatItems;
        _isEditMode = _controller.isEditMode;
        _selectedChatIds = _controller.selectedChatIds;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      // 앱바 추가
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF353535),
        surfaceTintColor: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.3),
        elevation: 0.5,
        centerTitle: true, // 타이틀 중앙 정렬
        title: Text(
          _chatListTitle,
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        // 뒤로가기 버튼 제거
        automaticallyImplyLeading: false, // 자동으로 추가되는 뒤로가기 버튼 비활성화
        actions: [
          // 편집 아이콘을 앱바에 배치 (오른쪽 여백 추가)
          if (_chatItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(
                  _isEditMode ? Icons.close : Icons.more_vert,
                  color: Color(0xFF353535),
                ),
                onPressed: () {
                  _controller.toggleEditMode();
                },
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 부분
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),

            // 채팅 목록
            Expanded(
              child: _buildChatList(),
            ),

            // 삭제 및 차단 해제 버튼 (편집 모드일 때만 표시)
            if (_isEditMode && _selectedChatIds.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // 차단 해제 버튼 - 선택한 채팅 중 차단된 것이 있을 때만 표시
                    if (_controller.hasBlockedChats())
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _controller.unblockSelectedChats(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            foregroundColor: Colors.blue[800],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _unblockButtonText,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),

                    // 삭제 버튼
                    Expanded(
                      child: Padding(
                        padding: _controller.hasBlockedChats()
                            ? const EdgeInsets.only(left: 8.0)
                            : EdgeInsets.zero,
                        child: GestureDetector(
                          onTap: () => _controller.deleteSelectedChats(),
                          child: Container(
                            height: 45,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF3182F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${_selectedChatIds.length}개 채팅방 나가기',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: TripfriendsBottomNavigator(
        currentIndex: _currentIndex,
        onTap: (index) {},
        scaffoldKey: _scaffoldKey,
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<List<ChatListItem>>(
      stream: _controller.chatListStream,
      builder: (context, snapshot) {
        // 로딩 중이거나 아직 스냅샷이 없을 때 로딩 스피너 표시
        if (_isLoading || !snapshot.hasData) {
          return LoadingSpinner(
            message: _loadingText,
          );
        }

        // 데이터가 없으면 안내 메시지
        if (snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              _emptyChatListText,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        // 데이터가 있으면 목록 표시
        _chatItems = snapshot.data!; // 로컬 변수 업데이트

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: _chatItems.length,
          itemBuilder: (context, index) {
            final item = _chatItems[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0), // 아이템 사이 간격 추가
              child: _buildChatListItem(item),
            );
          },
        );
      },
    );
  }

  Widget _buildChatListItem(ChatListItem item) {
    final bool isSelected = _selectedChatIds.contains(item.chatId);

    return InkWell(
      onTap: () {
        if (_isEditMode) {
          // 편집 모드에서는 선택/해제
          _controller.toggleChatSelection(item.chatId);
        } else {
          // 차단된 채팅은 열지 않음
          if (item.isBlocked) return;

          // 채팅 화면으로 이동
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return ChatScreen(
                  userId: widget.customerId,
                  friendsId: item.friendsId,
                  friendsName: item.friendsName,
                  friendsImage: item.friendsImage,
                );
              },
              transitionDuration: Duration.zero, // 애니메이션 제거
              settings: RouteSettings(name: '/chat_screen'),
            ),
          ).then((_) {
            // 채팅 화면에서 돌아왔을 때 목록 갱신
            _controller.loadChatList();
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 체크박스 (편집 모드일 때만)
            if (_isEditMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    _controller.toggleChatSelection(item.chatId);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF237AFF) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF237AFF) : const Color(0xFFD9D9D9),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                        : null,
                  ),
                ),
              ),

            // 프로필 이미지
            CircleAvatar(
              radius: 24,
              backgroundImage: item.friendsImage != null
                  ? NetworkImage(item.friendsImage!)
                  : null,
              child: item.friendsImage == null
                  ? const Icon(Icons.person)
                  : null,
              backgroundColor: Colors.blue.shade100,
            ),
            const SizedBox(width: 14),

            // 채팅 정보 (이름, 메시지, 타임스탬프)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 이름과 메시지 영역
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 타입과 프렌즈 이름
                            Row(
                              children: [
                                // 채팅 타입 배지
                                if (item.type != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: _buildChatTypeBadge(item.type!),
                                  ),
                                // 프렌즈 이름
                                Expanded(
                                  child: Text(
                                    item.friendsName,
                                    style: TextStyle(
                                      fontWeight: item.unreadCount > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 15,
                                      color: item.isBlocked ? Colors.grey : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // 마지막 메시지
                            Text(
                              item.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: item.isBlocked
                                    ? Colors.grey
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 시간/읽지 않은 메시지 또는 차단 해제 버튼
                      if (item.isBlocked && !_isEditMode)
                      // 차단 해제 버튼 (차단된 채팅만)
                        Container(
                          width: 75, // 버튼 너비 증가
                          height: 50, // 두 줄 높이에 맞춤
                          margin: const EdgeInsets.only(left: 8),
                          child: Material(
                            color: const Color(0xFFE4E4E4), // 회색 배경
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                _handleUnblockChat(item.friendsId);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: Text(
                                  '차단해제',
                                  style: TextStyle(
                                    color: const Color(0xFF4E5968), // 회색 배경
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                      // 시간과 읽지 않은 메시지 수
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 시간
                            Text(
                              item.formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // 읽지 않은 메시지 수 또는 빈 공간
                            item.unreadCount > 0 && !_isEditMode
                                ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3E6C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                                : SizedBox(height: 20), // 빈 공간 유지
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 단일 채팅 차단 해제 처리
  Future<void> _handleUnblockChat(String friendsId) async {
    try {
      // 차단 해제 확인 다이얼로그 표시
      final bool confirm = await _showSingleUnblockConfirmDialog(friendsId);
      if (!confirm) return;

      // 차단 해제 처리
      await _controller.getService().unblockUser(widget.customerId, friendsId);

      // 목록 새로고침
      await _controller.loadChatList();
    } catch (e) {
      print('채팅 차단 해제 중 오류 발생: $e');
    }
  }

  // 단일 차단 해제 확인 대화상자
  Future<bool> _showSingleUnblockConfirmDialog(String friendsId) async {
    // 해당 프렌즈 정보 찾기
    final friendChat = _chatItems.firstWhere(
          (item) => item.friendsId == friendsId,
      orElse: () => throw Exception('채팅을 찾을 수 없습니다'),
    );

    bool result = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: Row(
            children: [
              const Icon(Icons.block, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '차단 해제 확인',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          content: Text(
            '${friendChat.friendsName}님의 차단을 해제하시겠습니까?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                result = false;
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                '취소',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                result = true;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[900],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                '확인',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );

    return result;
  }

  // 채팅 타입 배지 위젯
  Widget _buildChatTypeBadge(String chatType) {
    if (chatType == 'friends') {
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: ShapeDecoration(
          color: const Color(0xFFE8F2FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Center(
          child: Text(
            '트립프렌즈',
            style: TextStyle(
              color: const Color(0xFF3182F6),
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else if (chatType == 'workmate') {
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFF2EA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Center(
          child: Text(
            '워크메이트',
            style: TextStyle(
              color: const Color(0xFFF67531),
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}