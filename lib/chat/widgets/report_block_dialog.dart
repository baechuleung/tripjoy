// lib/chat/widgets/report_block_dialog.dart
import 'package:flutter/material.dart';

// 신고하기 다이얼로그
class ReportDialog extends StatefulWidget {
  final Function(String, String?) onReport;
  final VoidCallback onCancel;

  const ReportDialog({
    Key? key,
    required this.onReport,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  // 신고 타입 옵션들 - 요청에 따라 일부 항목 제거
  final List<String> _reportTypes = [
    '욕설/비방',
    '무례한 태도/부적절한 제한',
    '상품/서비스 판매 권유',
    '개인 정보 요구',
    '기타(직접입력)'
  ];

  // 선택된 신고 타입
  String? _selectedType;

  // 기타 이유 텍스트 컨트롤러
  final TextEditingController _customReasonController = TextEditingController();

  // 커스텀 라디오 버튼 위젯
  Widget _buildCustomRadioButton(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 3,
                    color: isSelected ? const Color(0xFF3182F6) : const Color(0x42556789),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: ShapeDecoration(
                  color: const Color(0xFF3182F6),
                  shape: OvalBorder(
                    side: BorderSide(
                      width: 1,
                      color: const Color(0xFF3182F6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9, // 화면 너비의 90%
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '⚠️ 해당 프렌즈를 신고하시겠어요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 라디오 버튼 목록
                    for (String type in _reportTypes)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              _buildCustomRadioButton(_selectedType == type),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  type,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // '기타' 선택 시 표시할 텍스트 필드
                    if (_selectedType == '기타(직접입력)')
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextField(
                          controller: _customReasonController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '신고 이유를 입력하세요',
                            hintStyle: TextStyle(fontSize: 13),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: const Color(0xFFE4E4E4)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: const Color(0xFFE4E4E4)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: const Color(0xFFE4E4E4)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          maxLines: 3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      child: TextButton(
                        onPressed: widget.onCancel,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFFE4E4E4),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '취소',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _selectedType == null
                            ? null
                            : () {
                          final customReason = _selectedType == '기타(직접입력)' ? _customReasonController.text : null;
                          widget.onReport(_selectedType!, customReason);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFFFFE8E8),
                          foregroundColor: const Color(0xFFFF5050),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFFF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '신고하기',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedType == null ? const Color(0xFFCCCCCC) : const Color(0xFFFF5050),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }
}

// 차단하기 다이얼로그
class BlockDialog extends StatelessWidget {
  final Function() onBlock;
  final VoidCallback onCancel;

  const BlockDialog({
    Key? key,
    required this.onBlock,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9, // 화면 너비의 90%
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '이 프렌즈를 차단하시겠어요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: const Text(
                '차단 시 대화를 더 이상 주고 받을 수 없으며, 추후 동일 프렌즈와의 매칭되지 않습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0x7F14181F),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      child: TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFFE4E4E4),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '취소',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: onBlock,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFFFFE8E8),
                          foregroundColor: const Color(0xFFFF5050),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '차단하기',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFFF5050),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}