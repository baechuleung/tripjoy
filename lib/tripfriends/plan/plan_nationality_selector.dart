// plan_nationality_selector.dart
import 'package:flutter/material.dart';
import 'modal/custom_nationality_selector.dart';

class PlanNationalitySelector extends StatelessWidget {
  final String? selectedNationality;
  final List<Map<String, String>> nationalities;
  final Function(String?) onChanged;
  final Function(String?) validateNationality;

  const PlanNationalitySelector({
    Key? key,
    required this.selectedNationality,
    required this.nationalities,
    required this.onChanged,
    required this.validateNationality,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: Color(0xFFE4E4E4)),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            children: [
              // 왼쪽에 아이콘 배치
              Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Icon(Icons.airplane_ticket_outlined, color: Color(0xFF4E5968), size: 22),
              ),
              // 오른쪽에 텍스트 필드 배치 (오른쪽 정렬)
              Expanded(
                child: Center( // 전체 영역을 중앙 정렬하는 Center 위젯 추가
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '여행할 국가 선택',
                      hintStyle: TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: EdgeInsets.only(right: 16),
                      isDense: true, // 컴팩트한 레이아웃을 위해 추가
                    ),
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right, // 텍스트 오른쪽 정렬
                    textAlignVertical: TextAlignVertical.center, // 텍스트 수직 중앙 정렬
                    readOnly: true,
                    onTap: () => _showNationalitySelector(context),
                    controller: TextEditingController(
                      text: _getSelectedNationalityText(),
                    ),
                    validator: (value) => validateNationality(selectedNationality),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 선택된 국가의 표시 텍스트 (국기 + 이름)
  String _getSelectedNationalityText() {
    if (selectedNationality == null || selectedNationality!.isEmpty) {
      return '';
    }

    final nationality = nationalities.firstWhere(
          (c) => c['code'] == selectedNationality,
      orElse: () => {'name': '', 'flag': ''},
    );

    return '${nationality['flag'] ?? ''} ${nationality['name'] ?? ''}';
  }

  // 국가 선택기 표시
  void _showNationalitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomNationalitySelector(
        selectedNationality: selectedNationality,
        nationalities: nationalities,
        onNationalitySelected: onChanged,
      ),
    );
  }
}