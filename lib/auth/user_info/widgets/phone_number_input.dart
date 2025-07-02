// lib/auth/widgets/phone_number_input.dart
import 'package:flutter/material.dart';

class PhoneNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final bool showError;

  const PhoneNumberInput({
    Key? key,
    required this.controller,
    required this.showError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '휴대폰번호',
          style: TextStyle(
            color: Color(0xFF4E5968),
            fontSize: 14,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Color(0xFF353535), // 입력된 텍스트 색상
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '- 없이 입력',
              hintStyle: const TextStyle(
                color: Color(0xFF999999), // 힌트 텍스트 색상
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '여행 중 긴급상황 발생 시 안전을 위한 연락처로 사용됩니다',
          style: TextStyle(
            color: Color(0xFF999999),
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
          ),
        ),
        if (showError) ...[
          const SizedBox(height: 8),
          const Text(
            '휴대폰 번호를 입력해주세요',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}