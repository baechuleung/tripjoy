// lib/chat/controllers/chat_list_controller.dart - 트립프렌즈 앱(고객용)
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_list_item.dart';
import '../services/chat_list_service.dart';
import '../services/user_management_service.dart';

class ChatListController extends ChangeNotifier {
  final String customerId;
  late final ChatListService _chatListService;
  late final UserManagementService _userManagementService;

  bool _isLoading = true;
  List<ChatListItem> _chatItems = [];

  // 편집 모드 관련 변수
  bool _isEditMode = false;
  Set<String> _selectedChatIds = {};

  // 텍스트 변수들
  String _unblockSuccessText = '차단이 해제되었습니다';
  String _errorStateText = '오류가 발생했습니다';
  String _confirmUnblockTitle = '차단 해제 확인';
  String _confirmUnblockMessage = '선택한 프렌즈의 차단을 해제하시겠습니까?';
  String _confirmButtonText = '확인';
  String _cancelButtonText = '취소';

  // 채팅 목록 실시간 스트림 컨트롤러 추가
  final _chatListStreamController = StreamController<List<ChatListItem>>.broadcast();
  Stream<List<ChatListItem>> get chatListStream => _chatListStreamController.stream;
  StreamSubscription? _chatSubscription;

  ChatListController({required this.customerId}) {
    _chatListService = ChatListService(customerId: customerId);
    _userManagementService = UserManagementService();
  }

  // Getters
  bool get isLoading => _isLoading;
  List<ChatListItem> get chatItems => _chatItems;
  bool get isEditMode => _isEditMode;
  Set<String> get selectedChatIds => _selectedChatIds;

  // UserManagementService 가져오기
  UserManagementService getService() {
    return _userManagementService;
  }

  // 채팅 목록 로드
  Future<void> loadChatList() async {
    try {
      _isLoading = true;
      notifyListeners();

      final chatItems = await _chatListService.getChatList();

      // 차단된 채팅을 맨 아래로 정렬
      chatItems.sort((a, b) {
        if (a.isBlocked && !b.isBlocked) return 1;
        if (!a.isBlocked && b.isBlocked) return -1;
        return 0;
      });

      _chatItems = chatItems;

      // 스트림에 데이터 추가
      _chatListStreamController.add(_chatItems);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('채팅 목록 로드 오류: $e');
    }
  }

  // 실시간 업데이트 시작 메서드 추가
  void startRealTimeUpdates() {
    // 기존 구독이 있으면 취소
    _chatSubscription?.cancel();

    // 서비스에서 채팅 업데이트 스트림 구독
    // Firebase Realtime Database의 실시간 업데이트를 위해 getChatListStream 사용
    _chatSubscription = _chatListService.getChatListStream().listen((updatedChatItems) {
      // 차단된 채팅을 맨 아래로 정렬
      updatedChatItems.sort((a, b) {
        if (a.isBlocked && !b.isBlocked) return 1;
        if (!a.isBlocked && b.isBlocked) return -1;
        return 0;
      });

      _chatItems = updatedChatItems;
      _chatListStreamController.add(_chatItems);
      notifyListeners();
    });
  }

  // 편집 모드 토글
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    _selectedChatIds.clear();
    notifyListeners();
  }

  // 채팅 선택/해제
  void toggleChatSelection(String chatId) {
    if (_selectedChatIds.contains(chatId)) {
      _selectedChatIds.remove(chatId);
    } else {
      _selectedChatIds.add(chatId);
    }
    notifyListeners();
  }

  // 채팅 체크박스 변경
  void setChatSelection(String chatId, bool isSelected) {
    if (isSelected) {
      _selectedChatIds.add(chatId);
    } else {
      _selectedChatIds.remove(chatId);
    }
    notifyListeners();
  }

  // 선택된 채팅 삭제
  Future<void> deleteSelectedChats() async {
    if (_selectedChatIds.isEmpty) return;

    try {
      // 삭제 시작 시 로딩 상태로 변경
      _isLoading = true;
      notifyListeners();

      // 삭제할 채팅 ID 목록 복사
      final chatsToDelete = Set<String>.from(_selectedChatIds);

      // 각 선택된 채팅에 대해 삭제 작업 수행
      for (final chatId in chatsToDelete) {
        await _chatListService.deleteChat(chatId);
      }

      // 선택 목록 초기화
      _selectedChatIds.clear();

      // 편집 모드 종료
      _isEditMode = false;

      // 스트림에 빈 데이터 추가 (로딩 표시를 위해)
      _chatItems = [];
      _chatListStreamController.add(_chatItems);

      // 약간의 지연 후 목록 새로고침 시작
      await Future.delayed(Duration(milliseconds: 500));
      await loadChatList();

      // 이미 loadChatList에서 _isLoading = false로 설정됨
    } catch (e) {
      // 오류 발생 시 로딩 상태 해제
      _isLoading = false;
      notifyListeners();
      print('채팅 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 선택된 차단된 채팅 차단 해제
  Future<void> unblockSelectedChats(BuildContext context) async {
    if (_selectedChatIds.isEmpty) return;

    try {
      // 차단 해제 확인 대화상자 표시
      final bool confirm = await _showUnblockConfirmDialog(context);
      if (!confirm) return;

      // 차단 해제 시작 시 로딩 상태로 변경
      _isLoading = true;
      notifyListeners();

      // 차단 해제할 ID 목록 복사
      final chatsToUnblock = Set<String>.from(_selectedChatIds);

      // 각 선택된 채팅에 대해 차단 해제 작업 수행
      for (final chatId in chatsToUnblock) {
        try {
          // chatId에서 해당 프렌즈 ID 찾기
          final selectedChat = _chatItems.firstWhere(
                (item) => item.chatId == chatId,
            orElse: () => throw Exception('채팅을 찾을 수 없습니다'),
          );

          if (selectedChat.isBlocked) {
            await _userManagementService.unblockUser(
                customerId,
                selectedChat.friendsId
            );
          }
        } catch (e) {
          print('채팅 $chatId 차단 해제 중 오류 발생 (건너뜀): $e');
          continue; // 오류가 발생해도 계속 진행
        }
      }

      // 성공 메시지
      print(_unblockSuccessText);

      // 선택 목록 초기화
      _selectedChatIds.clear();

      // 편집 모드 종료
      _isEditMode = false;

      // 스트림에 빈 데이터 추가 (로딩 표시를 위해)
      _chatItems = [];
      _chatListStreamController.add(_chatItems);

      // 약간의 지연 후 목록 새로고침 시작
      await Future.delayed(Duration(milliseconds: 500));
      await loadChatList();

      // 이미 loadChatList에서 _isLoading = false로 설정됨
    } catch (e) {
      // 오류 발생 시 로딩 상태 해제
      _isLoading = false;
      notifyListeners();
      print('$_errorStateText: $e');
    }
  }

  // 차단 해제 확인 대화상자
  Future<bool> _showUnblockConfirmDialog(BuildContext context) async {
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
                  _confirmUnblockTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          content: Text(
            _confirmUnblockMessage,
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
                _cancelButtonText,
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
                _confirmButtonText,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );

    return result;
  }

  // 차단된 채팅 있는지 확인
  bool hasBlockedChats() {
    try {
      final blockedChats = _selectedChatIds
          .map((id) => _chatItems.firstWhere(
            (item) => item.chatId == id,
        orElse: () => ChatListItem(
          chatId: id,
          friendsId: '',
          friendsName: '',
          lastMessage: '',
          formattedTime: '',
          timestamp: 0,
          unreadCount: 0,
          isBlocked: false,
        ),
      ))
          .where((item) => item.isBlocked)
          .toList();

      return blockedChats.isNotEmpty;
    } catch (e) {
      print('hasBlockedChats 오류: $e');
      return false;
    }
  }

  @override
  void dispose() {
    // 리소스 해제
    _chatSubscription?.cancel();
    _chatListStreamController.close();
    super.dispose();
  }
}