// lib/chat/widgets/chat_date_header.dart - 트립조이 앱(고객용)
import 'package:flutter/material.dart';
import '../services/message_formatter.dart';

class ChatDateHeader extends StatelessWidget {
  final DateTime timestamp;

  const ChatDateHeader({
    Key? key,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateText = MessageFormatter.formatDateHeader(timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }
}