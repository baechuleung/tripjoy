// custom_city_selector.dart
import 'package:flutter/material.dart';

class CustomCitySelector extends StatelessWidget {
  final String? selectedCityId;
  final List<Map<String, dynamic>> cities;
  final Function(Map<String, dynamic>) onCitySelected;
  final String countryFlag;

  const CustomCitySelector({
    Key? key,
    this.selectedCityId,
    required this.cities,
    required this.onCitySelected,
    required this.countryFlag,
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
                Text(
                  '${countryFlag} 도시 선택',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 도시 목록 (스크롤 가능)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cities.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildCityItem(cities[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 도시 선택 아이템 위젯
  Widget _buildCityItem(Map<String, dynamic> city) {
    final isSelected = selectedCityId == city['code'];

    return GestureDetector(
      onTap: () {
        onCitySelected(city);
        // 선택 후 모달 닫기
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6EFFF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF237AFF) : const Color(0xFFE4E4E4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 도시명
            Expanded(
              child: Text(
                city['name'],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF237AFF) : Colors.black,
                ),
              ),
            ),

            // 체크 아이콘 (선택된 경우만)
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFF237AFF),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}