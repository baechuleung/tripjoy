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
    '욕설 / 비방',
    '무례한 태도 / 반복된 불쾌한 요구',
    '부적절한 여행 안내',
    '금전 요구 또는 불법행위 비용요청',
    '기타'
  ];

  // 선택된 신고 타입
  String? _selectedType;

  // 기타 이유 텍스트 컨트롤러
  final TextEditingController _customReasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // 명시적으로 배경색을 흰색으로 설정
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // 모서리를 더 둥글게
      ),
      title: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 20), // 아이콘 크기 줄임
          const SizedBox(width: 8),
          Text(
            '해당 프렌즈를 신고하시겠어요?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), // 타이틀 글자 크기 줄임
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16), // 컨텐츠 패딩 조정
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 라디오 버튼 목록
            for (String type in _reportTypes)
              RadioListTile<String>(
                title: Text(
                  type,
                  style: const TextStyle(fontSize: 14), // 목록 항목 글자 크기 줄임
                ),
                value: type,
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                activeColor: Colors.blue,
                contentPadding: EdgeInsets.zero,
                dense: true, // 목록 항목 간격 더 조밀하게
              ),

            // '기타' 선택 시 표시할 텍스트 필드
            if (_selectedType == '기타')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  controller: _customReasonController,
                  style: const TextStyle(fontSize: 14), // 입력 필드 글자 크기 줄임
                  decoration: const InputDecoration(
                    hintText: '신고 이유를 입력하세요',
                    hintStyle: TextStyle(fontSize: 13), // 힌트 텍스트 크기 줄임
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 3,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            '취소',
            style: TextStyle(fontSize: 14), // 버튼 글자 크기 줄임
          ),
        ),
        ElevatedButton(
          onPressed: _selectedType == null
              ? null  // 선택이 없으면 비활성화
              : () {
            final customReason = _selectedType == '기타' ? _customReasonController.text : null;
            widget.onReport(_selectedType!, customReason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[100],
            foregroundColor: Colors.red[900],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 버튼 패딩 조정
          ),
          child: const Text(
            '신고하기',
            style: TextStyle(fontSize: 14), // 버튼 글자 크기 줄임
          ),
        ),
      ],
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
    return AlertDialog(
      backgroundColor: Colors.white, // 명시적으로 배경색을 흰색으로 설정
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // 모서리를 더 둥글게
      ),
      title: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 20), // 아이콘 크기 줄임
          const SizedBox(width: 8),
          Text(
            '이 프렌즈를 차단하시겠어요?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), // 타이틀 글자 크기 줄임
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16), // 컨텐츠 패딩 조정
      content: const Text(
        '차단 시 대화를 더 이상 주고 받을 수 없으며, 추후 동일 프렌즈와의 매칭되지 않습니다.',
        style: TextStyle(fontSize: 14), // 내용 글자 크기 줄임
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            '취소',
            style: TextStyle(fontSize: 14), // 버튼 글자 크기 줄임
          ),
        ),
        ElevatedButton(
          onPressed: onBlock,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[100],
            foregroundColor: Colors.red[900],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 버튼 패딩 조정
          ),
          child: const Text(
            '차단하기',
            style: TextStyle(fontSize: 14), // 버튼 글자 크기 줄임
          ),
        ),
      ],
    );
  }
}