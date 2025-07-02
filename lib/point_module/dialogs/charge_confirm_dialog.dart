// lib/point_module/dialogs/charge_confirm_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/point_package.dart';

class ChargeConfirmDialog extends StatelessWidget {
  final PointPackage package;
  final VoidCallback onConfirm;
  final int points; // DB의 현재 포인트

  const ChargeConfirmDialog({
    super.key,
    required this.package,
    required this.onConfirm,
    this.points = 0,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final totalPoints = points + package.points;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 제목
            const Text(
              '포인트를 충전하시겠습니까?',
              style: TextStyle(
                color: Color(0xFF353535),
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                height: 1.20,
              ),
            ),
            const SizedBox(height: 16),

            // 충전 정보
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '충전 포인트',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '+ ${numberFormat.format(package.points)}P',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '합계 포인트',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF353535),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${numberFormat.format(totalPoints)}P',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF353535),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CustomPaint(
                    size: Size(double.infinity, 1),
                    painter: DottedLinePainter(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '현재 결제금액',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF353535),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '₩${numberFormat.format(package.price)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF3182F6),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 안내 문구
            const Text(
              '※ 충전된 포인트를 사용할 경우 환불되지 않습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // 버튼 영역
            Row(
              children: <Widget>[
                // 취소 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF6F6F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Center(
                        child: Text(
                          '취소',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4E5968),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 충전하기 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE8F2FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Center(
                        child: Text(
                          '충전하기',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF3182F6),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required PointPackage package,
    required VoidCallback onConfirm,
    int points = 0, // DB의 현재 포인트
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ChargeConfirmDialog(
          package: package,
          onConfirm: onConfirm,
          points: points,
        );
      },
    );
  }
}

// 점선 그리기를 위한 CustomPainter
class DottedLinePainter extends CustomPainter {
  const DottedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}