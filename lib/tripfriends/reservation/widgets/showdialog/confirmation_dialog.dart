import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText = '취소',
    this.confirmText = '확인',
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 타이틀 섹션
          Container(
            padding: const EdgeInsets.only(top: 32, bottom: 8),
            width: double.infinity,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 노쇼 안내 컨테이너
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: const Color(0xFFE8F2FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Color(0xFFFF3E3E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '프렌즈 예약 노쇼관련 안내',
                      style: TextStyle(
                        color: Color(0xFF353535),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '프렌즈 예약 후 무단 불참(노쇼)은 단순한 약속 위반을 넘어, 다른 사용자에게 심각한 피해를 주는 ',
                        style: TextStyle(
                          color: Color(0xFF4E5968),
                          fontSize: 13,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.30,
                          letterSpacing: -0.39,
                        ),
                      ),
                      TextSpan(
                        text: '위법 행위입니다.',
                        style: TextStyle(
                          color: Color(0xFF0059B7),
                          fontSize: 13,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          height: 1.30,
                          letterSpacing: -0.39,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '해당 행위가 확인될 경우, 사전 경고 없이 계정이 즉시 정지되며, 필요 시 ',
                        style: TextStyle(
                          color: Color(0xFF4E5968),
                          fontSize: 13,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.30,
                          letterSpacing: -0.39,
                        ),
                      ),
                      TextSpan(
                        text: '법적 조치 및 손해배상 청구',
                        style: TextStyle(
                          color: Color(0xFF0059B7),
                          fontSize: 13,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          height: 1.30,
                          letterSpacing: -0.39,
                        ),
                      ),
                      TextSpan(
                        text: '가 이루어질 수 있습니다.',
                        style: TextStyle(
                          color: Color(0xFF4E5968),
                          fontSize: 13,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.30,
                          letterSpacing: -0.39,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 내용 섹션
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            width: double.infinity,
            child: Center(
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 버튼 섹션
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // 취소 버튼
                if (cancelText.isNotEmpty)
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F5F5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 확인 버튼
                Expanded(
                  child: Container(
                    height: 48,
                    margin: cancelText.isNotEmpty
                        ? const EdgeInsets.only(left: 8)
                        : EdgeInsets.zero,
                    child: TextButton(
                      onPressed: onConfirm,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F0FF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF237AFF),
                          fontWeight: FontWeight.w700,
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
    );
  }
}