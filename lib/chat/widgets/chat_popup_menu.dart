// lib/chat/widgets/chat_popup_menu.dart
import 'package:flutter/material.dart';
import '../widgets/report_block_dialog.dart';
import '../services/user_management_service.dart';

class ChatPopupMenu extends StatelessWidget {
  final String userId;
  final String friendsId;
  final String chatId;

  // 신고/차단 관련 텍스트 변수들
  final String _reportSuccessText = '신고가 접수되었습니다';
  final String _blockSuccessText = '프렌즈가 차단되었습니다';
  final String _reportMenuText = '신고하기';
  final String _blockMenuText = '차단하기';
  final String _errorStateText = '에러가 발생했습니다';

  // final을 제거하고 lazy 초기화를 사용
  late final UserManagementService _userManagementService;

  ChatPopupMenu({
    Key? key,
    required this.userId,
    required this.friendsId,
    required this.chatId,
  }) : super(key: key) {
    // 생성자에서 초기화
    _userManagementService = UserManagementService();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      color: Colors.white,
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: 'report',
            child: Center(
              child: Text(_reportMenuText),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'block',
            child: Center(
              child: Text(_blockMenuText),
            ),
          ),
        ];
      },
      onSelected: (String value) {
        if (value == 'report') {
          _showReportDialog(context);
        } else if (value == 'block') {
          _showBlockDialog(context);
        }
      },
    );
  }

  // 신고하기 다이얼로그 표시
  void _showReportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ReportDialog(
          onReport: (String reason, String? customReason) async {
            Navigator.of(dialogContext).pop();

            try {
              // 사용자 관리 서비스의 reportUser 메서드 호출
              await _userManagementService.reportUser(
                reporterId: userId,
                reportedUserId: friendsId,
                reason: reason,
                customReason: customReason,
              );

              // 스낵바 대신 디버그 프린트 사용
              debugPrint('🚨 [신고] $_reportSuccessText');
            } catch (e) {
              // 스낵바 대신 디버그 프린트 사용
              debugPrint('⚠️ [신고] $_errorStateText: $e');
            }
          },
          onCancel: () {
            // 디버그 프린트 추가
            debugPrint('💬 [신고] 신고 다이얼로그 취소됨');
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  // 차단하기 다이얼로그 표시
  void _showBlockDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlockDialog(
          onBlock: () async {
            Navigator.of(dialogContext).pop();

            try {
              // 사용자 관리 서비스의 blockUser 메서드 호출
              await _userManagementService.blockUser(
                blockerId: userId,
                blockedUserId: friendsId,
                chatId: chatId,
              );

              // 스낵바 대신 디버그 프린트 사용
              debugPrint('🚫 [차단] $_blockSuccessText');

              // 차단 후 이전 화면으로 이동
              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) {
                  debugPrint('👋 [차단] 채팅방 나가기');
                  Navigator.of(context).pop();
                }
              });
            } catch (e) {
              // 스낵바 대신 디버그 프린트 사용
              debugPrint('⚠️ [차단] $_errorStateText: $e');
            }
          },
          onCancel: () {
            // 디버그 프린트 추가
            debugPrint('💬 [차단] 차단 다이얼로그 취소됨');
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
}