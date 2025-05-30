// lib/chat/models/chat_list_item.dart - 트립프렌즈 앱(고객용)
class ChatListItem {
  final String chatId;           // 채팅방 ID
  final String friendsId;       // 프렌즈 ID
  final String friendsName;     // 프렌즈 이름
  final String? friendsImage;   // 프렌즈 프로필 이미지 URL
  final String lastMessage;      // 마지막 메시지 내용
  final String formattedTime;    // 포맷팅된 시간 문자열
  final int timestamp;           // 원본 타임스탬프 (밀리초)
  final int unreadCount;         // 읽지 않은 메시지 수
  final bool isBlocked;          // 차단 여부

  ChatListItem({
    required this.chatId,
    required this.friendsId,
    required this.friendsName,
    this.friendsImage,
    required this.lastMessage,
    required this.formattedTime,
    required this.timestamp,
    required this.unreadCount,
    required this.isBlocked,
  });

  // 프로필 이미지가 있는지 확인
  bool get hasProfileImage => friendsImage != null && friendsImage!.isNotEmpty;

  // 읽지 않은 메시지가 있는지 확인
  bool get hasUnreadMessages => unreadCount > 0;
}