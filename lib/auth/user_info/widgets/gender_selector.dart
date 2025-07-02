// lib/auth/widgets/gender_selector.dart
import 'package:flutter/material.dart';

class GenderSelector extends StatelessWidget {
  final String? selectedGender;
  final Function(String) onGenderChanged;
  final bool showError;

  const GenderSelector({
    Key? key,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.showError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성별',
          style: TextStyle(
            color: Color(0xFF4E5968),
            fontSize: 14,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderButton('여성'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildGenderButton('남성'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '맞춤형 여행 상품 추천을 위해 필요합니다',
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
            '성별을 선택해주세요',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderButton(String gender) {
    final isSelected = selectedGender == gender;

    return GestureDetector(
      onTap: () => onGenderChanged(gender),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFE0E0E0),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            gender,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}