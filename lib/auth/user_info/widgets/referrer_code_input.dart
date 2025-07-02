// lib/auth/widgets/referrer_code_input.dart
import 'package:flutter/material.dart';
import '../validators/referrer_code_validator.dart';

class ReferrerCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final bool showError;
  final Function(bool) onErrorChanged;

  const ReferrerCodeInput({
    Key? key,
    required this.controller,
    required this.showError,
    required this.onErrorChanged,
  }) : super(key: key);

  @override
  _ReferrerCodeInputState createState() => _ReferrerCodeInputState();
}

class _ReferrerCodeInputState extends State<ReferrerCodeInput> {
  bool? _isValidCode;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_isValidCode != null) {
      setState(() {
        _isValidCode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '추천인 코드',
              style: TextStyle(
                color: Color(0xFF4E5968),
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '선택사항',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(
                    color: Color(0xFF353535), // 입력된 텍스트 색상 변경
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: '코드를 입력해주세요',
                    hintStyle: const TextStyle(
                      color: Color(0xFF999999), // 힌트 텍스트 색상
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 48,
              child: ElevatedButton(
                onPressed: hasText && !_isChecking ? () async {
                  setState(() {
                    _isChecking = true;
                  });

                  widget.onErrorChanged(false);

                  final isValid = await ReferrerCodeValidator.validateReferrerCode(
                      widget.controller.text.trim()
                  );

                  setState(() {
                    _isValidCode = isValid;
                    _isChecking = false;
                  });

                  if (!isValid) {
                    widget.onErrorChanged(true);
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasText ? const Color(0xFF4050FF) : const Color(0xFFF5F5F5),
                  foregroundColor: hasText ? Colors.white : const Color(0xFF757575),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isChecking
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isValidCode == true) ...[
          const SizedBox(height: 8),
          const Text(
            '유효한 추천인 코드입니다.',
            style: TextStyle(
              color: Color(0xFF2196F3),
              fontSize: 10,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (widget.showError || _isValidCode == false) ...[
          const SizedBox(height: 8),
          const Text(
            '추천인 코드가 올바르지 않습니다. 다시 입력해주세요.',
            style: TextStyle(
              color: Color(0xFFFF5050),
              fontSize: 10,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}