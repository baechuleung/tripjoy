// custom_nationality_selector.dart
import 'package:flutter/material.dart';

class CustomNationalitySelector extends StatelessWidget {
  final String? selectedNationality;
  final List<Map<String, String>> nationalities;
  final Function(String?) onNationalitySelected;

  const CustomNationalitySelector({
    Key? key,
    required this.selectedNationality,
    required this.nationalities,
    required this.onNationalitySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
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

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '여행할 국가 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 국가 목록
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: nationalities.length,
              itemBuilder: (context, index) {
                final nationality = nationalities[index];
                final isSelected = selectedNationality == nationality['code'];
                // 베트남만 선택 가능
                final bool isAvailable = nationality['code'] == 'VN';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: isAvailable
                        ? () {
                      onNationalitySelected(nationality['code']);
                      Navigator.pop(context);
                    }
                        : null, // 선택 불가능
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: isSelected
                          ? const Color(0xFFE6EFFF)
                          : (isAvailable ? Colors.white : const Color(0xFFF5F5F5)), // 선택 불가능한 경우 흐린 배경
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF237AFF)
                              : (isAvailable ? const Color(0xFFE4E4E4) : const Color(0xFFEEEEEE)),
                          width: 1,
                        ),
                      ),
                      disabledBackgroundColor: const Color(0xFFF5F5F5), // 비활성화 시 배경색
                      disabledForegroundColor: Colors.black54, // 비활성화 시 텍스트 색상
                    ),
                    child: Row(
                      children: [
                        // 국기 이모지
                        Text(
                          nationality['flag'] ?? '',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        // 국가명
                        Expanded(
                          child: Text(
                            nationality['name'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF237AFF)
                                  : (isAvailable ? Colors.black : Colors.black54),
                            ),
                          ),
                        ),

                        // 선택 불가능한 국가에는 서비스 준비중 메시지 표시
                        if (!isAvailable)
                          Text(
                            '서비스 준비중입니다',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                        // 체크 아이콘 (선택된 경우만)
                        if (isSelected)
                          const Icon(Icons.check, color: Color(0xFF237AFF)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}