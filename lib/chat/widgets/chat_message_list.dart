// lib/chat/widgets/chat_message_list.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/message_formatter.dart';
import 'chat_date_header.dart';
import 'message_bubble.dart';

class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool initialLoadComplete;
  final String userId;
  final String? friendsImage;
  final ScrollController scrollController;

  const ChatMessageList({
    Key? key,
    required this.messages,
    required this.initialLoadComplete,
    required this.userId,
    required this.friendsImage,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // 메시지가 없는 경우 - 빈 상태 표시 (초기 로딩 이후)
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.maps_ugc, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '프렌즈와의 대화가 여기에 표시됩니다.\n메시지를 보내 대화를 시작해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFC2C2C2),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // 역순 리스트뷰를 위해 메시지 배열 복사 및 역순 정렬
    final reversedMessages = List<ChatMessage>.from(messages);
    reversedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 26, // 상단 여유 공간 (역순이므로 하단 여유 공간이 됨)
        bottom: 16,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      // 역순 리스트뷰 설정 - 최신 메시지가 맨 아래(화면 처음)에 표시됨
      reverse: true,
      itemCount: reversedMessages.length,
      itemBuilder: (context, index) {
        // 역순이므로 인덱스는 뒤에서부터 계산
        final message = reversedMessages[index];

        // 현재 메시지가 내가 보낸 것인지 확인
        final isMe = message.senderId == userId;

        // 날짜 헤더 표시 로직 (역순 리스트뷰이므로 날짜 비교도 반대로)
        final showDateHeader = index == reversedMessages.length - 1 || // 첫 메시지(시간상 가장 오래된 메시지)
            !MessageFormatter.isSameDay(
                reversedMessages[index].timestamp,
                reversedMessages[index + 1].timestamp);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateHeader) ChatDateHeader(timestamp: message.timestamp),
            MessageBubble(
              message: message,
              isMe: isMe,
              friendsImage: friendsImage,
            ),
          ],
        );
      },
    );
  }
}