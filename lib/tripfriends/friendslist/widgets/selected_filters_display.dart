// lib/tripfriends/friendslist/widgets/selected_filters_display.dart
import 'package:flutter/material.dart';
import '../filter/filter_constants.dart';

/// 선택된 필터 표시 위젯
class SelectedFiltersDisplay extends StatelessWidget {
  final Map<String, Set<String>> selectedFilters;
  final Function(String, String) onRemoveFilter;

  const SelectedFiltersDisplay({
    Key? key,
    required this.selectedFilters,
    required this.onRemoveFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 선택된 필터가 없으면 빈 SizedBox 반환 (공간 차지 안함)
    if (selectedFilters.isEmpty ||
        selectedFilters.values.every((options) => options.isEmpty)) {
      return const SizedBox.shrink();
    }

    // 선택된 필터 태그 준비
    List<Widget> selectedFilterChips = [];

    selectedFilters.forEach((category, options) {
      for (var option in options) {
        // '상관없음'이나 '전체'는 표시하지 않음
        if (option != '상관없음' && option != '전체') {
          // 필터 표시 데이터 가져오기
          final displayData = FilterConstants.getFilterDisplayData(category, option);

          selectedFilterChips.add(
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: ShapeDecoration(
                  color: Color(0xFFF4F3FF),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Color(0xFF887FFF)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(displayData['iconData'] as IconData, size: 20, color: displayData['iconColor'] as Color),
                    const SizedBox(width: 4),
                    Text(
                      displayData['displayText'] as String,
                      style: TextStyle(
                        color: Color(0xFF887FFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (displayData['secondIconData'] != null)
                      Icon(displayData['secondIconData'] as IconData, size: 20,
                          color: const Color(0xFF8E8E8E)),
                    const SizedBox(width: 4),
                    // 삭제 버튼 추가
                    InkWell(
                      onTap: () => onRemoveFilter(category, option),
                      child: Icon(Icons.close, size: 16, color: Color(0xFF887FFF)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    });

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: selectedFilterChips,
        ),
      ),
    );
  }
}