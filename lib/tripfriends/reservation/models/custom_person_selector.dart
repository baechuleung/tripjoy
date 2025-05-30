import 'package:flutter/material.dart';

class CustomPersonSelector extends StatelessWidget {
  final int? selectedPerson;
  final Function(int) onPersonSelected;

  const CustomPersonSelector({
    Key? key,
    this.selectedPerson,
    required this.onPersonSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들 추가
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text(
            '인원 선택',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),

          // 인원 옵션 그리드 - 1-4명만 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [1, 2, 3, 4].map((count) =>
                _buildPersonButton(count, context)
            ).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 인원 버튼 위젯
  Widget _buildPersonButton(int count, BuildContext context) {
    final isSelected = selectedPerson == count;
    final buttonWidth = (MediaQuery.of(context).size.width - 52) / 4;

    return GestureDetector(
      onTap: () {
        onPersonSelected(count);
        // Navigator.pop은 onPersonSelected 콜백에서 처리하도록 제거
      },
      child: Container(
        width: buttonWidth,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF237AFF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF237AFF) : const Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '$count명',
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
    );
  }
}