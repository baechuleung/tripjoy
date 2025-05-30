import 'package:flutter/material.dart';
import 'showdialog/agreement_dialog.dart';

class AgreementCheckboxWidget extends StatefulWidget {
  final bool isChecked;
  final Function(bool) onChanged;

  const AgreementCheckboxWidget({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  State<AgreementCheckboxWidget> createState() => AgreementCheckboxWidgetState();
}

class AgreementCheckboxWidgetState extends State<AgreementCheckboxWidget> {
  bool _isAllChecked = false;
  bool _isPaymentAgreed = false;
  bool _isProhibitionAgreed = false;
  bool _isReviewAgreed = false;

  @override
  void initState() {
    super.initState();
    _isAllChecked = widget.isChecked;
  }

  void _updateAllChecked() {
    setState(() {
      _isAllChecked = _isPaymentAgreed && _isProhibitionAgreed;
      // 전체 동의 상태를 상위 위젯에 알림
      widget.onChanged(_isAllChecked);
    });
  }

  void _handleAllChecked(bool? value) {
    setState(() {
      _isAllChecked = value ?? false;
      _isPaymentAgreed = _isAllChecked;
      _isProhibitionAgreed = _isAllChecked;
      _isReviewAgreed = _isAllChecked;
      // 전체 동의 상태를 상위 위젯에 알림
      widget.onChanged(_isAllChecked);
    });
  }

  // 상태 확인용 getter 메서드들
  bool get isPaymentAgreed => _isPaymentAgreed;
  bool get isProhibitionAgreed => _isProhibitionAgreed;
  bool get isReviewAgreed => _isReviewAgreed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 필수 동의 항목 텍스트 추가
          const Text(
            '필수 동의 항목',
            style: TextStyle(
              color: Color(0xFF353535),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4), // 텍스트와 구분선 사이 여백 추가
          // 텍스트 아래 구분선 추가
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEEEEEE),
          ),
          const SizedBox(height: 4),

          // 전체 동의 항목
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                child: Checkbox(
                  value: _isAllChecked,
                  onChanged: _handleAllChecked,
                  activeColor: const Color(0xFFFF5252),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Text(
                '전체 동의합니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // 전체 동의 아래 구분선 삭제됨
          const SizedBox(height: 4), // 여백 줄임

          // 필수 항목 1: 현장결제 안내 동의
          GestureDetector(
            onTap: () {
              showPaymentAgreementDialog(context, (value) {
                setState(() {
                  _isPaymentAgreed = value;
                  _updateAllChecked();
                });
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  child: Checkbox(
                    value: _isPaymentAgreed,
                    onChanged: (value) {
                      setState(() {
                        _isPaymentAgreed = value ?? false;
                        _updateAllChecked();
                      });
                    },
                    activeColor: const Color(0xFFFF5252),
                    visualDensity: VisualDensity.compact, // 체크박스 크기 줄임
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Text(
                  '[필수] 현장결제 안내 동의',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          // 필수 항목 2: 금지 행위 안내 동의
          GestureDetector(
            onTap: () {
              showProhibitionAgreementDialog(context, (value) {
                setState(() {
                  _isProhibitionAgreed = value;
                  _updateAllChecked();
                });
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  child: Checkbox(
                    value: _isProhibitionAgreed,
                    onChanged: (value) {
                      setState(() {
                        _isProhibitionAgreed = value ?? false;
                        _updateAllChecked();
                      });
                    },
                    activeColor: const Color(0xFFFF5252),
                    visualDensity: VisualDensity.compact, // 체크박스 크기 줄임
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Text(
                  '[필수] 금지 행위 안내 동의',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          // 선택 항목: 프렌즈 이용 후 리뷰약속 동의
          GestureDetector(
            onTap: () {
              showReviewAgreementDialog(context, (value) {
                setState(() {
                  _isReviewAgreed = value;
                });
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  child: Checkbox(
                    value: _isReviewAgreed,
                    onChanged: (value) {
                      setState(() {
                        _isReviewAgreed = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFFFF5252),
                    visualDensity: VisualDensity.compact, // 체크박스 크기 줄임
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Text(
                  '[선택] 프렌즈 이용 후 리뷰약속 동의',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
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