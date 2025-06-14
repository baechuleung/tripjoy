import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FriendsResponseRate extends StatefulWidget {
  final String tripfriendsId;

  const FriendsResponseRate({
    Key? key,
    required this.tripfriendsId,
  }) : super(key: key);

  @override
  State<FriendsResponseRate> createState() => _FriendsResponseRateState();
}

class _FriendsResponseRateState extends State<FriendsResponseRate> {
  late DatabaseReference _database;
  double _responseRate = 0.0;
  bool _isLoading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    print('FriendsResponseRate initState 호출됨');
    _initializeDatabase();
  }

  void _initializeDatabase() {
    // 명시적으로 데이터베이스 URL 설정
    final database = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://tripjoy-d309f-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );
    _database = database.ref();

    // 비동기로 계산 수행 (UI 블로킹 없이)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateResponseRate();
    });
  }

  Future<void> _calculateResponseRate() async {
    try {
      // 데이터베이스에서 빠르게 가져오기
      final snapshot = await _database
          .child('chat')
          .orderByKey()
          .endAt('${widget.tripfriendsId}\uf8ff')
          .once();

      if (snapshot.snapshot.value == null) {
        return;
      }

      final Map<dynamic, dynamic> chats = snapshot.snapshot.value as Map<dynamic, dynamic>;

      int totalConversations = 0;
      int responsesWithin5Minutes = 0;

      // 각 채팅방 검사
      chats.forEach((chatId, chatData) {
        // chatId가 tripfriendsId를 포함하는지 확인
        if (chatId.toString().contains('_${widget.tripfriendsId}') ||
            chatId.toString().endsWith(widget.tripfriendsId)) {

          if (chatData['messages'] != null) {
            final Map<dynamic, dynamic> messages = chatData['messages'] as Map<dynamic, dynamic>;

            // 메시지를 시간순으로 정렬
            List<MapEntry<dynamic, dynamic>> sortedMessages = messages.entries.toList()
              ..sort((a, b) {
                int timestampA = a.value['timestamp'] ?? 0;
                int timestampB = b.value['timestamp'] ?? 0;
                return timestampA.compareTo(timestampB);
              });

            // 연속된 메시지 쌍 확인
            for (int i = 0; i < sortedMessages.length - 1; i++) {
              final currentMessage = sortedMessages[i].value;
              final nextMessage = sortedMessages[i + 1].value;

              // 서로 다른 발신자인지 확인
              if (currentMessage['senderId'] != nextMessage['senderId']) {
                // 첫 번째 메시지가 user이고 두 번째가 tripfriends인 경우
                if (!currentMessage['senderId'].toString().contains(widget.tripfriendsId) &&
                    nextMessage['senderId'].toString().contains(widget.tripfriendsId)) {

                  totalConversations++;

                  // 시간 차이 계산 (밀리초 단위)
                  int timeDiff = (nextMessage['timestamp'] ?? 0) - (currentMessage['timestamp'] ?? 0);

                  // 5분(300,000밀리초) 이내 응답인지 확인
                  if (timeDiff <= 300000 && timeDiff >= 0) {
                    responsesWithin5Minutes++;
                  }
                }
              }
            }
          }
        }
      });

      // 응답률 계산
      double rate = 0.0;
      if (totalConversations > 0) {
        rate = (responsesWithin5Minutes / totalConversations) * 100;
      }

      if (mounted) {
        setState(() {
          _responseRate = rate;
          _isLoading = false;
          _hasData = totalConversations > 0;
        });
      }

    } catch (e) {
      print('응답률 계산 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이어도 기본 UI 표시
    return Row(
      children: [
        const Icon(
          Icons.notifications,
          size: 18,
          color: Color(0xFFFFAF5E),
        ),
        const SizedBox(width: 4),
        Text(
          '5분 이내 응답률 ${_responseRate.toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}