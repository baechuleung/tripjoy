// lib/auth/widgets/birth_date_selector.dart
import 'package:flutter/material.dart';

class BirthDateSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateChanged;
  final bool showError;

  const BirthDateSelector({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.showError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '생년월일',
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
              child: _buildDropdown(
                value: selectedDate?.year,
                hint: 'YYYY',
                items: List.generate(100, (index) => DateTime.now().year - index),
                onChanged: (value) {
                  if (value != null) {
                    onDateChanged(DateTime(
                      value,
                      selectedDate?.month ?? 1,
                      selectedDate?.day ?? 1,
                    ));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdown(
                value: selectedDate?.month,
                hint: 'MM',
                items: List.generate(12, (index) => index + 1),
                onChanged: (value) {
                  if (value != null) {
                    onDateChanged(DateTime(
                      selectedDate?.year ?? DateTime.now().year,
                      value,
                      selectedDate?.day ?? 1,
                    ));
                  }
                },
                formatValue: (value) => value.toString().padLeft(2, '0'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdown(
                value: selectedDate?.day,
                hint: 'DD',
                items: List.generate(31, (index) => index + 1),
                onChanged: (value) {
                  if (value != null) {
                    onDateChanged(DateTime(
                      selectedDate?.year ?? DateTime.now().year,
                      selectedDate?.month ?? 1,
                      value,
                    ));
                  }
                },
                formatValue: (value) => value.toString().padLeft(2, '0'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '연령 제한 콘텐츠 필터링 및 법적 요구사항 준수를 위해 필요합니다',
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
            '생년월일을 입력해주세요',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required int? value,
    required String hint,
    required List<int> items,
    required Function(int?) onChanged,
    String Function(int)? formatValue,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          hint: Text(hint, style: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          )),
          style: const TextStyle(
            color: Color(0xFF353535), // 입력된 텍스트 색상 변경
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(formatValue != null ? formatValue(item) : item.toString()),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}