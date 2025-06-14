import 'package:flutter/material.dart';

class CustomPurposeSelector extends StatefulWidget {
  final List<String>? selectedPurposes;
  final Function(List<String>) onPurposeSelected;

  const CustomPurposeSelector({
    Key? key,
    this.selectedPurposes,
    required this.onPurposeSelected,
  }) : super(key: key);

  @override
  State<CustomPurposeSelector> createState() => _CustomPurposeSelectorState();
}

class _CustomPurposeSelectorState extends State<CustomPurposeSelector> {
  // 현재 선택된 이용목적들
  late List<String> _selectedPurposes;

  @override
  void initState() {
    super.initState();
    // 초기 선택된 이용목적 설정
    _selectedPurposes = widget.selectedPurposes != null
        ? List<String>.from(widget.selectedPurposes!)
        : [];
  }

  // 이용목적 리스트
  final List<String> purposes = [
    '맛집/카페 탐방',
    '전통시장/쇼핑탐방',
    '자유일정/통역'
  ];

  // 이용목적 선택/취소 처리
  void _togglePurpose(String purpose) {
    setState(() {
      if (_selectedPurposes.contains(purpose)) {
        // 이미 선택되어 있으면 제거
        _selectedPurposes.remove(purpose);
      } else {
        // 선택되어 있지 않으면 추가
        _selectedPurposes.add(purpose);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 너비 계산
    final screenWidth = MediaQuery.of(context).size.width;
    // 아이템 너비 계산 (패딩 고려)
    final itemWidth = (screenWidth - 40) / 2; // (화면 너비 - (좌우 패딩 + 중간 간격)) / 2

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
            '이용목적 선택',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 16),

          // 목적 옵션 그리드 레이아웃 (한 줄에 2개씩)
          Column(
            children: [
              // 첫 번째 행 (0, 1번 항목)
              Row(
                children: [
                  _buildPurposeOption(
                    purposes[0],
                    _selectedPurposes.contains(purposes[0]),
                    itemWidth,
                  ),
                  const SizedBox(width: 8),
                  _buildPurposeOption(
                    purposes[1],
                    _selectedPurposes.contains(purposes[1]),
                    itemWidth,
                  ),
                ],
              ),

              const SizedBox(height: 8), // 행 사이 간격

              // 두 번째 행 (2번 항목)
              Row(
                children: [
                  _buildPurposeOption(
                    purposes[2],
                    _selectedPurposes.contains(purposes[2]),
                    itemWidth,
                  ),
                  const SizedBox(width: 8),
                  // 두 번째 항목은 투명 상자로 대체
                  SizedBox(width: itemWidth),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 확인 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedPurposes.isNotEmpty
                  ? () => widget.onPurposeSelected(_selectedPurposes)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF237AFF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 이용목적 옵션 위젯 - 고정 너비 사용
  Widget _buildPurposeOption(String purpose, bool isSelected, double width) {
    return GestureDetector(
      onTap: () => _togglePurpose(purpose),
      child: Container(
        width: width,
        height: 44, // 높이 고정
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE6EFFF)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF237AFF)
                : const Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
        child: Row(
          // 중앙 정렬로 변경
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.check,
                  color: Color(0xFF237AFF),
                  size: 16,
                ),
              ),
            Flexible(
              child: Text(
                purpose,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF237AFF)
                      : const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center, // 텍스트 중앙 정렬
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}