import 'package:flutter/material.dart';

class CancelPopup extends StatelessWidget {
  final bool isPaymentCancellation;

  const CancelPopup({
    Key? key,
    this.isPaymentCancellation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 취소 유형에 따라 타이틀 및 내용 설정
    final title = isPaymentCancellation ? '결제취소 안내' : '예약취소 안내';
    final cancelButtonText = isPaymentCancellation ? '돌아가기' : '취소';
    final confirmButtonText = isPaymentCancellation ? '결제 취소하기' : '확인';
    final confirmButtonColor = isPaymentCancellation ? Color(0xFFE8505B) : Color(0xFF3182F6);
    final confirmButtonBgColor = isPaymentCancellation ? Color(0xFFFFE8E8) : Color(0xFFE8F1FF);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF353535),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPaymentCancellation) ...[
            // 결제 취소 안내
            Text(
              '결제 취소 시 예약이 즉시 취소되며\n복구가 불가능합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF353535),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '환불은 결제 수단에 따라\n1-3일 내에 처리됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '취소 후 예약 내역 확인 불가\n\n장소 변경 · 일정 조정은 프렌즈\n에게 직접 문의하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF353535),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            // 기존 예약 취소 안내
            Text(
              '예약 30분 전 취소 시 전액 환불',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF353535),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '(영업일 3일 이내 처리)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '취소 후 예약 내역 확인 불가\n\n장소 변경 · 일정 조정은 프렌즈\n에게 직접 문의',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF353535),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => Navigator.of(context).pop(false),
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  margin: EdgeInsets.only(left: 16, right: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE8E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cancelButtonText,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  margin: EdgeInsets.only(left: 8, right: 16, bottom: 16),
                  decoration: BoxDecoration(
                    color: confirmButtonBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    confirmButtonText,
                    style: TextStyle(
                      color: confirmButtonColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}