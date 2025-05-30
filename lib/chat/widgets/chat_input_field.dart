// lib/chat/widgets/chat_input_field.dart - 트립조이 앱(고객용)
import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onTap;

  const ChatInputField({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  // 내부적으로 FocusNode 관리
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 포커스 리스너 추가
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // 포커스 상태가 변경될 때 호출되는 함수
    if (_focusNode.hasFocus) {
      // 포커스를 얻었을 때 onTap 호출
      widget.onTap();
    }
  }

  void _handleSend() {
    // 전송 처리
    if (widget.controller.text.trim().isNotEmpty) {
      // 전송 콜백 실행
      widget.onSend();

      // 약간의 지연 후 포커스 설정 - 키보드가 내려가지 않도록
      Future.microtask(() {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 메시지 입력 필드
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: '프렌즈에게 메시지를 입력하세요...',
                    hintStyle: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    _handleSend();
                    // 키보드 내려가는 것 방지 - 명시적으로 포커스 다시 요청
                    Future.delayed(const Duration(milliseconds: 50), () {
                      _focusNode.requestFocus();
                    });
                  },
                  onTap: widget.onTap,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 전송 버튼
            GestureDetector(
              onTap: _handleSend, // 내부 함수 사용
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF237AFF), // 일반 사용자 앱 색상 (파란색)
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _handleSend, // 내부 함수 사용
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
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
}