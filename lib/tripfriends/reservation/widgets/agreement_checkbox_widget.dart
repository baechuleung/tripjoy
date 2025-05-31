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

  // 커스텀 체크박스 위젯 생성
  Widget _buildCustomCheckbox(bool isChecked, Function(bool?) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFF237AFF) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isChecked ? const Color(0xFF237AFF) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.check,
          size: 14,
          color: isChecked ? Colors.white : const Color(0xFFE4E4E4),
        ),
      ),
    );
  }

  // 하위 체크박스용 심플한 체크 아이콘
  Widget _buildSimpleCheck(bool isChecked) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: Icon(
        Icons.check,
        size: 20,
        color: isChecked ? const Color(0xFF237AFF) : const Color(0xFFE4E4E4),
      ),
    );
  }

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
          const SizedBox(height: 12),

          // 전체 동의 항목
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: _buildCustomCheckbox(_isAllChecked, _handleAllChecked),
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
          const SizedBox(height: 12), // 여백

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
                  width: 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPaymentAgreed = !_isPaymentAgreed;
                        _updateAllChecked();
                      });
                    },
                    child: _buildSimpleCheck(_isPaymentAgreed),
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
          const SizedBox(height: 8),

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
                  width: 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isProhibitionAgreed = !_isProhibitionAgreed;
                        _updateAllChecked();
                      });
                    },
                    child: _buildSimpleCheck(_isProhibitionAgreed),
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
          const SizedBox(height: 8),

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
                  width: 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isReviewAgreed = !_isReviewAgreed;
                      });
                    },
                    child: _buildSimpleCheck(_isReviewAgreed),
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